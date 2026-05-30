"""Tests for /rag router."""

from __future__ import annotations

import pytest


@pytest.mark.asyncio
async def test_load_missing_path(client):
    """Loading from a nonexistent path returns 404."""
    resp = await client.post(
        "/rag/load",
        json={
            "collection_id": "test",
            "path": "/nonexistent/path/xyz",
            "file_types": ["txt"],
        },
    )
    assert resp.status_code == 404
    assert "does not exist" in resp.json()["detail"]


@pytest.mark.asyncio
async def test_search_unknown_collection(client):
    """Searching an unknown collection returns 404."""
    resp = await client.post(
        "/rag/search",
        json={"collection_id": "missing_col", "query": "test", "top_k": 3},
    )
    assert resp.status_code == 404
    assert "missing_col" in resp.json()["detail"]


@pytest.mark.asyncio
async def test_ask_unknown_collection(client):
    """Asking against an unknown collection returns 404."""
    resp = await client.post(
        "/rag/ask",
        json={
            "collection_id": "missing_col",
            "question": "What is this?",
            "model": "gpt-4o",
        },
    )
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_load_missing_required_field(client):
    """Missing collection_id returns 422."""
    resp = await client.post(
        "/rag/load",
        json={"path": "/some/path"},
    )
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_load_happy_path(client, monkeypatch, tmp_path):
    """Loading a real temp directory with a .txt file succeeds."""
    from server.core import rag_manager as rm

    def fake_load(self, collection_id, path, file_types, chunk_size, chunk_overlap, embedding_model):
        self._collections[collection_id] = {"vectorstore": None, "embedding_model": embedding_model}
        return 7  # pretend 7 chunks

    monkeypatch.setattr(rm.RagManager, "load", fake_load)

    doc = tmp_path / "sample.txt"
    doc.write_text("Hello world")

    resp = await client.post(
        "/rag/load",
        json={
            "collection_id": "tmp_col",
            "path": str(tmp_path),
            "file_types": ["txt"],
        },
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["collection_id"] == "tmp_col"
    assert data["chunks_indexed"] == 7
    assert data["status"] == "ready"
