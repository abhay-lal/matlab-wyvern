"""RAG API router."""

from __future__ import annotations

import logging

from fastapi import APIRouter, HTTPException, Request

from server.models.rag_models import (
    RagAskRequest,
    RagAskResponse,
    RagLoadRequest,
    RagLoadResponse,
    RagSearchRequest,
    RagSearchResponse,
    RagChunk,
)

logger = logging.getLogger(__name__)
router = APIRouter()


def _rag(request: Request):
    return request.app.state.rag_manager


@router.post("/load", response_model=RagLoadResponse)
async def load_docs(body: RagLoadRequest, request: Request) -> RagLoadResponse:
    """Index documents into a named FAISS vector store collection."""
    try:
        chunks_indexed = _rag(request).load(
            body.collection_id,
            body.path,
            body.file_types,
            body.chunk_size,
            body.chunk_overlap,
            body.embedding_model,
        )
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception(
            "Failed to load documents for collection '%s'", body.collection_id
        )
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    return RagLoadResponse(
        collection_id=body.collection_id,
        chunks_indexed=chunks_indexed,
        status="ready",
    )


@router.post("/search", response_model=RagSearchResponse)
async def search(body: RagSearchRequest, request: Request) -> RagSearchResponse:
    """Semantic search over an indexed document collection."""
    try:
        results = _rag(request).search(body.collection_id, body.query, body.top_k)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Search failed for collection '%s'", body.collection_id)
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    chunks = [RagChunk(**r) for r in results]
    return RagSearchResponse(chunks=chunks)


@router.post("/ask", response_model=RagAskResponse)
async def ask(body: RagAskRequest, request: Request) -> RagAskResponse:
    """Answer a question using RAG over an indexed collection."""
    try:
        result = _rag(request).ask(
            body.collection_id,
            body.question,
            body.model,
            body.api_key,
            body.top_k,
        )
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("RAG ask failed for collection '%s'", body.collection_id)
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    return RagAskResponse(**result)
