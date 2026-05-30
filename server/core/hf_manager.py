"""HuggingFace pipeline manager — loads and caches HF models."""

from __future__ import annotations

import logging
from typing import Any

logger = logging.getLogger(__name__)


class HFManager:
    """Manages HuggingFace pipeline instances, keyed by model_id."""

    def __init__(self) -> None:
        self._pipelines: dict[str, Any] = {}
        self._sentence_transformers: dict[str, Any] = {}

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def load(self, model_id: str, task: str, device: str = "cpu") -> None:
        """Load a HuggingFace model/pipeline into memory."""
        if model_id in self._pipelines or model_id in self._sentence_transformers:
            logger.info("Model '%s' already loaded — skipping.", model_id)
            return

        logger.info("Loading HF model '%s' for task '%s' on %s...", model_id, task, device)

        if task == "feature-extraction":
            self._load_sentence_transformer(model_id, device)
        else:
            self._load_pipeline(model_id, task, device)

        logger.info("Model '%s' loaded successfully.", model_id)

    def embed(self, model_id: str, texts: list[str]) -> list[list[float]]:
        """Return embeddings for *texts* as a list-of-lists of floats."""
        if model_id not in self._sentence_transformers:
            raise KeyError(f"Model '{model_id}' is not loaded. Call /hf/load first.")

        model = self._sentence_transformers[model_id]
        vectors = model.encode(texts, convert_to_numpy=True)
        return vectors.tolist()

    def generate(
        self,
        model_id: str,
        prompt: str,
        max_new_tokens: int = 256,
        temperature: float = 1.0,
        do_sample: bool = False,
    ) -> str:
        """Run text generation and return the generated string."""
        if model_id not in self._pipelines:
            raise KeyError(f"Model '{model_id}' is not loaded. Call /hf/load first.")

        pipe = self._pipelines[model_id]
        kwargs: dict[str, Any] = {
            "max_new_tokens": max_new_tokens,
            "do_sample": do_sample,
        }
        if do_sample:
            kwargs["temperature"] = temperature

        results = pipe(prompt, **kwargs)
        if isinstance(results, list) and results:
            first = results[0]
            return first.get("generated_text", str(first))
        return str(results)

    def classify(
        self,
        model_id: str,
        texts: list[str],
        labels: list[str] | None,
    ) -> tuple[list[str], list[list[float]]]:
        """
        Run classification.

        Returns (label_list, scores_matrix) where scores_matrix[i] are the
        scores for texts[i].
        """
        if model_id not in self._pipelines:
            raise KeyError(f"Model '{model_id}' is not loaded. Call /hf/load first.")

        pipe = self._pipelines[model_id]

        if labels is not None:
            # Zero-shot classification
            all_labels: list[str] = []
            all_scores: list[list[float]] = []
            for text in texts:
                result = pipe(text, candidate_labels=labels)
                if not all_labels:
                    all_labels = result["labels"]
                all_scores.append(result["scores"])
            return all_labels, all_scores
        else:
            # Standard sequence classification
            results = pipe(texts)
            if not isinstance(results, list):
                results = [results]
            unique_labels = [r["label"] for r in results]
            scores = [[r["score"]] for r in results]
            return unique_labels, scores

    def cleanup(self) -> None:
        """Release all loaded models."""
        logger.info("Releasing %d HF models.", len(self._pipelines) + len(self._sentence_transformers))
        self._pipelines.clear()
        self._sentence_transformers.clear()

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _load_pipeline(self, model_id: str, task: str, device: str) -> None:
        from transformers import pipeline

        device_arg: int | str
        if device == "cpu":
            device_arg = -1
        elif device == "cuda":
            device_arg = 0
        else:
            device_arg = "auto"

        self._pipelines[model_id] = pipeline(task, model=model_id, device=device_arg)

    def _load_sentence_transformer(self, model_id: str, device: str) -> None:
        from sentence_transformers import SentenceTransformer

        self._sentence_transformers[model_id] = SentenceTransformer(model_id, device=device)
