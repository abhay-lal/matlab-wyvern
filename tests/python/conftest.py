"""Shared pytest fixtures for Wyvern server tests.

Two fixture modes are provided:

1. ``client`` (default, used by all router unit tests) — an in-process
   HTTPX ASGI client that talks directly to the FastAPI app without binding
   a real port.  Fast, no teardown issues, works in CI without free ports.

2. ``live_server`` / ``live_client`` (integration, opt-in) — starts the
   real FastAPI server as a subprocess, polls /health, and tears it down
   after the session.  Enable with:  ``pytest -m integration``
"""

from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

import httpx
import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from server.main import app
from server.core.agent_manager import AgentManager
from server.core.rag_manager import RagManager
from server.core.hf_manager import HFManager

SERVER_URL = "http://localhost:5173"
SERVER_MAIN = Path(__file__).parent.parent.parent / "server" / "main.py"


# ─── In-process ASGI client (used by all unit tests) ─────────────────────────

@pytest_asyncio.fixture
async def client():
    """Async HTTPX client wired directly to the FastAPI app (no real port).

    The ASGI transport bypasses the lifespan context manager, so we
    manually attach the singleton managers to ``app.state`` here so that
    routers can access them during tests.
    """
    app.state.agent_manager = AgentManager()
    app.state.rag_manager = RagManager()
    app.state.hf_manager = HFManager()

    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac

    # Cleanup
    app.state.hf_manager.cleanup()
    app.state.rag_manager.cleanup()


# ─── Live subprocess server (integration tests only) ─────────────────────────

@pytest.fixture(scope="session")
def live_server():
    """Start the real FastAPI server once for the entire integration test session."""
    process = subprocess.Popen(
        [sys.executable, str(SERVER_MAIN)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    # Poll /health until the server is ready (max 30 s)
    for _ in range(30):
        try:
            r = httpx.get(f"{SERVER_URL}/health", timeout=2)
            if r.status_code == 200:
                break
        except Exception:
            pass
        time.sleep(1)
    else:
        process.kill()
        pytest.fail("Wyvern server did not start within 30 seconds")

    yield process

    process.terminate()
    process.wait()


@pytest.fixture
def live_client(live_server):
    """Synchronous HTTPX client pointing at the live server."""
    return httpx.Client(base_url=SERVER_URL, timeout=30)
