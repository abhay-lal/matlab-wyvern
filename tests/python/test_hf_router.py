"""Tests for /hf router."""

from __future__ import annotations

import pytest


@pytest.mark.asyncio
async def test_embed_model_not_loaded(client):
    """Embedding with an unloaded model returns 404."""
    resp = await client.post(
        "/hf/embed",
        json={"model_id": "not-loaded", "texts": ["hello"]},
    )
    assert resp.status_code == 404
    assert "not-loaded" in resp.json()["detail"]


@pytest.mark.asyncio
async def test_generate_model_not_loaded(client):
    """Generating with an unloaded model returns 404."""
    resp = await client.post(
        "/hf/generate",
        json={"model_id": "not-loaded", "prompt": "Hello"},
    )
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_classify_model_not_loaded(client):
    """Classification with an unloaded model returns 404."""
    resp = await client.post(
        "/hf/classify",
        json={"model_id": "not-loaded", "texts": ["test"]},
    )
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_load_missing_task(client):
    """Missing task field returns 422."""
    resp = await client.post(
        "/hf/load",
        json={"model_id": "all-MiniLM-L6-v2"},
    )
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_load_and_embed_happy_path(client, monkeypatch):
    """Loading and then embedding with a stubbed model returns correct shape."""
    from server.core import hf_manager as hfm
    import numpy as np

    def fake_load(self, model_id, task, device="cpu"):
        self._sentence_transformers[model_id] = None  # placeholder

    def fake_embed(self, model_id, texts):
        return [[0.1, 0.2, 0.3]] * len(texts)

    monkeypatch.setattr(hfm.HFManager, "load", fake_load)
    monkeypatch.setattr(hfm.HFManager, "embed", fake_embed)

    # Load
    load_resp = await client.post(
        "/hf/load",
        json={"model_id": "stub-model", "task": "feature-extraction", "device": "cpu"},
    )
    assert load_resp.status_code == 200
    assert load_resp.json()["status"] == "loaded"

    # Embed
    embed_resp = await client.post(
        "/hf/embed",
        json={"model_id": "stub-model", "texts": ["foo", "bar"]},
    )
    assert embed_resp.status_code == 200
    data = embed_resp.json()
    assert data["shape"] == [2, 3]
    assert len(data["embeddings"]) == 2
