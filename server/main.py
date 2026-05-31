"""Wyvern FastAPI server — main entry point."""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from server.core.agent_manager import AgentManager
from server.core.rag_manager import RagManager
from server.core.hf_manager import HFManager
from server.routers import agent, rag, hf

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)

WYVERN_VERSION = "0.1.0"


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialise and tear down singleton managers."""
    logger.info("Wyvern server starting (v%s)", WYVERN_VERSION)

    app.state.agent_manager = AgentManager()
    app.state.rag_manager = RagManager()
    app.state.hf_manager = HFManager()

    logger.info("All managers initialised — server ready.")
    yield

    logger.info("Wyvern server shutting down...")
    app.state.hf_manager.cleanup()
    app.state.rag_manager.cleanup()
    logger.info("Shutdown complete.")


app = FastAPI(
    title="Wyvern",
    description="MATLAB LLM Agent Toolbox — FastAPI bridge server",
    version=WYVERN_VERSION,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost", "http://127.0.0.1"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(agent.router, prefix="/agent", tags=["agent"])
app.include_router(rag.router, prefix="/rag", tags=["rag"])
app.include_router(hf.router, prefix="/hf", tags=["hf"])


@app.get("/health")
async def health() -> dict:
    """Return server health and version."""
    return {"status": "ok", "version": WYVERN_VERSION}


if __name__ == "__main__":
    import argparse
    import uvicorn

    parser = argparse.ArgumentParser(description="Start the Wyvern server")
    parser.add_argument("--port", type=int, default=5173, help="Port to listen on")
    parser.add_argument("--host", default="127.0.0.1", help="Host to bind to")
    args = parser.parse_args()

    uvicorn.run(
        "server.main:app",
        host=args.host,
        port=args.port,
        workers=1,
        log_level="info",
    )
