"""HuggingFace API router."""

from __future__ import annotations

import logging

from fastapi import APIRouter, HTTPException, Request

from server.models.hf_models import (
    HFClassifyRequest,
    HFClassifyResponse,
    HFEmbedRequest,
    HFEmbedResponse,
    HFGenerateRequest,
    HFGenerateResponse,
    HFLoadRequest,
    HFLoadResponse,
)

logger = logging.getLogger(__name__)
router = APIRouter()


def _hf(request: Request):
    return request.app.state.hf_manager


@router.post("/load", response_model=HFLoadResponse)
async def load_model(body: HFLoadRequest, request: Request) -> HFLoadResponse:
    """Load a HuggingFace model into memory."""
    try:
        _hf(request).load(body.model_id, body.task, body.device)
    except Exception as exc:
        logger.exception("Failed to load model '%s'", body.model_id)
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    return HFLoadResponse(model_id=body.model_id, task=body.task, status="loaded")


@router.post("/embed", response_model=HFEmbedResponse)
async def embed(body: HFEmbedRequest, request: Request) -> HFEmbedResponse:
    """Return embedding vectors for the provided texts."""
    try:
        vectors = _hf(request).embed(body.model_id, body.texts)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Embedding failed for model '%s'", body.model_id)
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    shape = [len(vectors), len(vectors[0]) if vectors else 0]
    return HFEmbedResponse(embeddings=vectors, shape=shape)


@router.post("/generate", response_model=HFGenerateResponse)
async def generate(body: HFGenerateRequest, request: Request) -> HFGenerateResponse:
    """Run text generation and return the result."""
    try:
        text = _hf(request).generate(
            body.model_id,
            body.prompt,
            body.max_new_tokens,
            body.temperature,
            body.do_sample,
        )
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Generation failed for model '%s'", body.model_id)
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    return HFGenerateResponse(generated_text=text)


@router.post("/classify", response_model=HFClassifyResponse)
async def classify(body: HFClassifyRequest, request: Request) -> HFClassifyResponse:
    """Run classification (standard or zero-shot) and return labels + scores."""
    try:
        labels, scores = _hf(request).classify(body.model_id, body.texts, body.labels)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("Classification failed for model '%s'", body.model_id)
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    return HFClassifyResponse(labels=labels, scores=scores)
