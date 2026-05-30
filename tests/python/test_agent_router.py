"""Tests for /agent router."""

from __future__ import annotations

import pytest


@pytest.mark.asyncio
async def test_create_agent_happy_path(client, monkeypatch):
    """Creating an agent with valid parameters returns agent_id and 'created'."""
    from server.core import agent_manager as am

    # Stub out the heavy LangGraph build to avoid needing API keys in tests
    def fake_create(self, agent_id, model, api_key, system_prompt, tools, memory):
        self._agents[agent_id] = object()  # placeholder

    monkeypatch.setattr(am.AgentManager, "create", fake_create)

    resp = await client.post(
        "/agent/create",
        json={
            "agent_id": "test_agent",
            "model": "gpt-4o",
            "system_prompt": "You are a test assistant.",
            "tools": [],
            "memory": False,
        },
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["agent_id"] == "test_agent"
    assert data["status"] == "created"


@pytest.mark.asyncio
async def test_run_agent_not_found(client):
    """Running an unknown agent returns 404."""
    resp = await client.post(
        "/agent/run",
        json={"agent_id": "nonexistent", "message": "hello"},
    )
    assert resp.status_code == 404
    assert "nonexistent" in resp.json()["detail"]


@pytest.mark.asyncio
async def test_reset_agent_not_found(client):
    """Resetting an unknown agent returns 404."""
    resp = await client.post("/agent/reset", json={"agent_id": "ghost"})
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_create_agent_missing_field(client):
    """Missing required agent_id field returns 422."""
    resp = await client.post(
        "/agent/create",
        json={"model": "gpt-4o"},
    )
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_run_agent_happy_path(client, monkeypatch):
    """Running a stubbed agent returns response struct."""
    from server.core import agent_manager as am

    def fake_create(self, agent_id, **_):
        from unittest.mock import MagicMock
        entry = MagicMock()
        entry.run.return_value = {
            "response": "test answer",
            "steps": [],
            "tokens_used": 42,
        }
        self._agents[agent_id] = entry

    monkeypatch.setattr(am.AgentManager, "create", fake_create)

    await client.post(
        "/agent/create",
        json={
            "agent_id": "stubbed",
            "model": "gpt-4o",
            "system_prompt": "stub",
            "tools": [],
            "memory": False,
        },
    )
    resp = await client.post(
        "/agent/run",
        json={"agent_id": "stubbed", "message": "hi"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["response"] == "test answer"
    assert data["tokens_used"] == 42
