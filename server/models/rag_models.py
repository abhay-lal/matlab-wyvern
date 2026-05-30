"""Pydantic v2 schemas for RAG routes."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class RagLoadRequest(BaseModel):
    collection_id: str = Field(..., description="User-defined name for this document collection")
    path: str = Field(..., description="Absolute path to a folder or single file")
    file_types: list[str] = Field(default=["pdf", "txt", "md"], description="File extensions to index")
    chunk_size: int = Field(default=500, ge=50, le=8000)
    chunk_overlap: int = Field(default=50, ge=0, le=500)
    embedding_model: str = Field(default="all-MiniLM-L6-v2", description="Sentence-transformers model for embeddings")


class RagLoadResponse(BaseModel):
    collection_id: str
    chunks_indexed: int
    status: Literal["ready"]


class RagSearchRequest(BaseModel):
    collection_id: str
    query: str
    top_k: int = Field(default=5, ge=1, le=50)


class RagChunk(BaseModel):
    text: str
    source: str
    score: float


class RagSearchResponse(BaseModel):
    chunks: list[RagChunk]


class RagAskRequest(BaseModel):
    collection_id: str
    question: str
    model: str = Field(default="gpt-4o")
    api_key: str | None = None
    top_k: int = Field(default=5, ge=1, le=50)


class RagAskResponse(BaseModel):
    answer: str
    sources: list[str]
    chunks_used: int
