"""Pydantic v2 schemas for agent routes."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


class AgentCreateRequest(BaseModel):
    agent_id: str = Field(
        ..., description="User-defined agent name, e.g. 'signal_analyst'"
    )
    model: str = Field(default="gpt-4o", description="LLM model name")
    api_key: str | None = Field(
        default=None, description="API key; if None reads from environment"
    )
    system_prompt: str = Field(
        default="You are a helpful assistant.", description="Agent persona/instructions"
    )
    tools: list[str] = Field(
        default_factory=list,
        description="Built-in tool names: 'web_search', 'calculator'",
    )
    memory: bool = Field(
        default=True, description="Persist conversation history across runs"
    )


class AgentCreateResponse(BaseModel):
    agent_id: str
    status: Literal["created"]


class AgentRunRequest(BaseModel):
    agent_id: str
    message: str
    context: dict[str, Any] | None = None


class AgentRunResponse(BaseModel):
    response: str
    steps: list[dict[str, Any]]
    tokens_used: int


class AgentResetRequest(BaseModel):
    agent_id: str


class AgentResetResponse(BaseModel):
    status: Literal["reset"]


class AgentStreamRequest(BaseModel):
    agent_id: str
    message: str
