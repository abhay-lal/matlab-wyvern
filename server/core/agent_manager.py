"""Agent manager — LangGraph agent lifecycle and state persistence."""

from __future__ import annotations

import logging
import os
from typing import Any

logger = logging.getLogger(__name__)

# Built-in tools available to agents
_BUILTIN_TOOLS: dict[str, Any] = {}


def _build_builtin_tools() -> dict[str, Any]:
    """Lazily build the registry of built-in LangChain tools."""
    from langchain_community.tools import DuckDuckGoSearchRun
    from langchain.tools import tool

    @tool
    def calculator(expression: str) -> str:
        """Evaluate a mathematical expression and return the result."""
        import math  # noqa: PLC0415
        try:
            safe_globals = {"__builtins__": {}, "math": math}
            result = eval(expression, safe_globals)  # noqa: S307
            return str(result)
        except Exception as exc:
            return f"Error: {exc}"

    return {
        "web_search": DuckDuckGoSearchRun(),
        "calculator": calculator,
    }


class _AgentEntry:
    """Holds an agent's graph, config, and conversation thread state."""

    def __init__(
        self,
        agent_id: str,
        model: str,
        api_key: str | None,
        system_prompt: str,
        tools: list[str],
        memory: bool,
    ) -> None:
        self.agent_id = agent_id
        self.model = model
        self.system_prompt = system_prompt
        self.memory = memory
        self._thread_id = agent_id  # one thread per agent for memory

        tool_objects = self._resolve_tools(tools)
        self._graph = self._build_graph(model, api_key, system_prompt, tool_objects)

    # ------------------------------------------------------------------
    # Public
    # ------------------------------------------------------------------

    def run(self, message: str, context: dict[str, Any] | None) -> dict[str, Any]:
        """Invoke the agent synchronously and return response + metadata."""
        from langchain_core.messages import HumanMessage, SystemMessage

        human_msg = HumanMessage(content=message)
        config = {"configurable": {"thread_id": self._thread_id}} if self.memory else {}

        steps: list[dict[str, Any]] = []
        final_response = ""
        tokens_used = 0

        result = self._graph.invoke({"messages": [human_msg]}, config=config)

        messages = result.get("messages", [])
        if messages:
            last = messages[-1]
            final_response = last.content if hasattr(last, "content") else str(last)

        # Collect intermediate tool steps
        for msg in messages:
            if hasattr(msg, "tool_calls") and msg.tool_calls:
                for tc in msg.tool_calls:
                    steps.append({"tool": tc.get("name", ""), "input": tc.get("args", {})})

        # Token usage from last AIMessage if available
        if messages:
            last_msg = messages[-1]
            usage = getattr(last_msg, "usage_metadata", None)
            if usage:
                tokens_used = usage.get("total_tokens", 0)

        return {
            "response": final_response,
            "steps": steps,
            "tokens_used": tokens_used,
        }

    def stream(self, message: str):
        """Yield token chunks from the agent as a generator."""
        from langchain_core.messages import HumanMessage

        human_msg = HumanMessage(content=message)
        config = {"configurable": {"thread_id": self._thread_id}} if self.memory else {}

        for chunk in self._graph.stream(
            {"messages": [human_msg]},
            config=config,
            stream_mode="messages",
        ):
            for msg_chunk in chunk:
                if hasattr(msg_chunk, "content") and msg_chunk.content:
                    yield msg_chunk.content

    def reset(self) -> None:
        """Clear the conversation memory by rotating the thread ID."""
        import uuid
        self._thread_id = f"{self.agent_id}_{uuid.uuid4().hex[:8]}"

    # ------------------------------------------------------------------
    # Private
    # ------------------------------------------------------------------

    @staticmethod
    def _resolve_tools(tool_names: list[str]) -> list[Any]:
        global _BUILTIN_TOOLS
        if not _BUILTIN_TOOLS:
            try:
                _BUILTIN_TOOLS = _build_builtin_tools()
            except Exception:
                logger.warning("Could not load all built-in tools.", exc_info=True)
                _BUILTIN_TOOLS = {}

        resolved = []
        for name in tool_names:
            if name in _BUILTIN_TOOLS:
                resolved.append(_BUILTIN_TOOLS[name])
            else:
                logger.warning("Unknown tool '%s' — skipping.", name)
        return resolved

    def _build_graph(
        self,
        model: str,
        api_key: str | None,
        system_prompt: str,
        tools: list[Any],
    ):
        from langchain_core.messages import SystemMessage
        from langgraph.graph import StateGraph, MessagesState, START, END
        from langgraph.prebuilt import ToolNode
        from langgraph.checkpoint.memory import MemorySaver

        llm = self._build_llm(model, api_key)
        if tools:
            llm = llm.bind_tools(tools)

        def call_model(state: MessagesState):
            messages = state["messages"]
            # Prepend system prompt if not already there
            if not any(getattr(m, "type", None) == "system" for m in messages):
                messages = [SystemMessage(content=system_prompt)] + messages
            response = llm.invoke(messages)
            return {"messages": [response]}

        def should_continue(state: MessagesState):
            last = state["messages"][-1]
            if hasattr(last, "tool_calls") and last.tool_calls:
                return "tools"
            return END

        builder = StateGraph(MessagesState)
        builder.add_node("agent", call_model)

        if tools:
            tool_node = ToolNode(tools)
            builder.add_node("tools", tool_node)
            builder.add_edge(START, "agent")
            builder.add_conditional_edges("agent", should_continue)
            builder.add_edge("tools", "agent")
        else:
            builder.add_edge(START, "agent")
            builder.add_edge("agent", END)

        checkpointer = MemorySaver() if self.memory else None
        return builder.compile(checkpointer=checkpointer)

    @staticmethod
    def _build_llm(model: str, api_key: str | None):
        model_lower = model.lower()

        if "claude" in model_lower or "anthropic" in model_lower:
            from langchain_anthropic import ChatAnthropic
            key = api_key or os.environ.get("ANTHROPIC_API_KEY")
            return ChatAnthropic(model=model, api_key=key)  # type: ignore[arg-type]

        # Default: OpenAI-compatible
        from langchain_openai import ChatOpenAI
        key = api_key or os.environ.get("OPENAI_API_KEY")
        return ChatOpenAI(model=model, api_key=key)  # type: ignore[arg-type]


class AgentManager:
    """Manages the lifecycle of named LangGraph agents."""

    def __init__(self) -> None:
        self._agents: dict[str, _AgentEntry] = {}

    def create(
        self,
        agent_id: str,
        model: str,
        api_key: str | None,
        system_prompt: str,
        tools: list[str],
        memory: bool,
    ) -> None:
        """Create (or replace) a named agent."""
        logger.info("Creating agent '%s' with model '%s'.", agent_id, model)
        self._agents[agent_id] = _AgentEntry(
            agent_id=agent_id,
            model=model,
            api_key=api_key,
            system_prompt=system_prompt,
            tools=tools,
            memory=memory,
        )

    def run(self, agent_id: str, message: str, context: dict[str, Any] | None) -> dict[str, Any]:
        return self._get(agent_id).run(message, context)

    def stream(self, agent_id: str, message: str):
        return self._get(agent_id).stream(message)

    def reset(self, agent_id: str) -> None:
        self._get(agent_id).reset()

    def _get(self, agent_id: str) -> _AgentEntry:
        if agent_id not in self._agents:
            raise KeyError(
                f"Agent '{agent_id}' does not exist. "
                f"Create it first with wyvern.agent.create('{agent_id}')."
            )
        return self._agents[agent_id]
