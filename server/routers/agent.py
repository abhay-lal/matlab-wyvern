"""Agent API router."""

from __future__ import annotations

import asyncio
import logging

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse

from server.models.agent_models import (
    AgentCreateRequest,
    AgentCreateResponse,
    AgentResetRequest,
    AgentResetResponse,
    AgentRunRequest,
    AgentRunResponse,
    AgentStreamRequest,
)

logger = logging.getLogger(__name__)
router = APIRouter()


def _agents(request: Request):
    return request.app.state.agent_manager


@router.post("/create", response_model=AgentCreateResponse)
async def create_agent(body: AgentCreateRequest, request: Request) -> AgentCreateResponse:
    """Define a new LangGraph agent with tools and optional memory."""
    try:
        _agents(request).create(
            agent_id=body.agent_id,
            model=body.model,
            api_key=body.api_key,
            system_prompt=body.system_prompt,
            tools=body.tools,
            memory=body.memory,
        )
    except Exception as exc:
        logger.exception("Failed to create agent '%s'", body.agent_id)
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    return AgentCreateResponse(agent_id=body.agent_id, status="created")


@router.post("/run", response_model=AgentRunResponse)
async def run_agent(body: AgentRunRequest, request: Request) -> AgentRunResponse:
    """Invoke an agent and return the final response."""
    try:
        result = await asyncio.get_event_loop().run_in_executor(
            None,
            lambda: _agents(request).run(body.agent_id, body.message, body.context),
        )
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Agent run failed for '%s'", body.agent_id)
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    return AgentRunResponse(**result)


@router.post("/stream")
async def stream_agent(body: AgentStreamRequest, request: Request) -> StreamingResponse:
    """Invoke an agent and stream token chunks as Server-Sent Events."""

    async def event_generator():
        try:
            gen = _agents(request).stream(body.agent_id, body.message)
            for chunk in gen:
                if await request.is_disconnected():
                    break
                yield f"data: {chunk}\n\n"
        except KeyError as exc:
            yield f"data: [ERROR] {exc}\n\n"
        except Exception as exc:
            logger.exception("Stream failed for agent '%s'", body.agent_id)
            yield f"data: [ERROR] {exc}\n\n"
        finally:
            yield "data: [DONE]\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")


@router.post("/reset", response_model=AgentResetResponse)
async def reset_agent(body: AgentResetRequest, request: Request) -> AgentResetResponse:
    """Clear an agent's memory and conversation history."""
    try:
        _agents(request).reset(body.agent_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Reset failed for agent '%s'", body.agent_id)
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    return AgentResetResponse(status="reset")
