"""Pydantic v2 schemas for HuggingFace routes."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class HFLoadRequest(BaseModel):
    model_id: str = Field(..., description="HuggingFace model identifier, e.g. 'all-MiniLM-L6-v2'")
    task: str = Field(..., description="Pipeline task, e.g. 'feature-extraction', 'text-generation', 'zero-shot-classification'")
    device: Literal["cpu", "cuda", "auto"] = Field(default="cpu", description="Device to load the model on")


class HFLoadResponse(BaseModel):
    model_id: str
    task: str
    status: Literal["loaded"]


class HFEmbedRequest(BaseModel):
    model_id: str
    texts: list[str] = Field(..., min_length=1, description="List of texts to embed")


class HFEmbedResponse(BaseModel):
    embeddings: list[list[float]]
    shape: list[int]


class HFGenerateRequest(BaseModel):
    model_id: str
    prompt: str
    max_new_tokens: int = Field(default=256, ge=1, le=4096)
    temperature: float = Field(default=1.0, ge=0.0, le=2.0)
    do_sample: bool = False


class HFGenerateResponse(BaseModel):
    generated_text: str


class HFClassifyRequest(BaseModel):
    model_id: str
    texts: list[str] = Field(..., min_length=1)
    labels: list[str] | None = Field(
        default=None,
        description="Label list for zero-shot classification. None for standard classification.",
    )


class HFClassifyResponse(BaseModel):
    labels: list[str]
    scores: list[list[float]]
