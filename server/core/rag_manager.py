"""RAG manager — document loading, FAISS vector store, retrieval, and QA."""

from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)


class RagManager:
    """Manages FAISS vector stores for named document collections."""

    def __init__(self) -> None:
        # collection_id -> {"vectorstore": FAISS, "embedding_model": str}
        self._collections: dict[str, dict[str, Any]] = {}

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def load(
        self,
        collection_id: str,
        path: str,
        file_types: list[str],
        chunk_size: int,
        chunk_overlap: int,
        embedding_model: str,
    ) -> int:
        """
        Load documents from *path*, chunk them, embed, and store in FAISS.

        Returns the number of chunks indexed.
        """
        resolved = Path(path)
        if not resolved.exists():
            raise FileNotFoundError(
                f"Path '{path}' does not exist or is not accessible."
            )

        from langchain_community.document_loaders import (
            DirectoryLoader,
            TextLoader,
            PyPDFLoader,
            UnstructuredMarkdownLoader,
        )
        from langchain.text_splitter import RecursiveCharacterTextSplitter
        from langchain_community.vectorstores import FAISS
        from langchain_community.embeddings import HuggingFaceEmbeddings

        documents = []
        loader_map = {
            "txt": (TextLoader, {}),
            "pdf": (PyPDFLoader, {}),
            "md": (UnstructuredMarkdownLoader, {}),
        }

        if resolved.is_file():
            ext = resolved.suffix.lstrip(".").lower()
            loader_cls, kwargs = loader_map.get(ext, (TextLoader, {}))
            loader = loader_cls(str(resolved), **kwargs)
            documents.extend(loader.load())
        else:
            for ext in file_types:
                loader_cls, kwargs = loader_map.get(ext, (TextLoader, {}))
                glob = f"**/*.{ext}"
                try:
                    dir_loader = DirectoryLoader(
                        str(resolved),
                        glob=glob,
                        loader_cls=loader_cls,
                        loader_kwargs=kwargs,
                        silent_errors=True,
                    )
                    documents.extend(dir_loader.load())
                except Exception:
                    logger.warning("Failed to load .%s files from %s", ext, path)

        if not documents:
            raise ValueError(
                f"No documents found at '{path}' with file types {file_types}."
            )

        splitter = RecursiveCharacterTextSplitter(
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap,
        )
        chunks = splitter.split_documents(documents)
        logger.info(
            "Indexed %d chunks from %d documents (collection='%s')",
            len(chunks),
            len(documents),
            collection_id,
        )

        embeddings = HuggingFaceEmbeddings(model_name=embedding_model)
        vectorstore = FAISS.from_documents(chunks, embeddings)

        self._collections[collection_id] = {
            "vectorstore": vectorstore,
            "embedding_model": embedding_model,
        }
        return len(chunks)

    def search(
        self,
        collection_id: str,
        query: str,
        top_k: int = 5,
    ) -> list[dict[str, Any]]:
        """
        Semantic search over a collection.

        Returns a list of dicts with keys: text, source, score.
        """
        vs = self._get_vectorstore(collection_id)
        results = vs.similarity_search_with_score(query, k=top_k)
        return [
            {
                "text": doc.page_content,
                "source": doc.metadata.get("source", ""),
                "score": float(score),
            }
            for doc, score in results
        ]

    def ask(
        self,
        collection_id: str,
        question: str,
        model: str,
        api_key: str | None,
        top_k: int = 5,
    ) -> dict[str, Any]:
        """
        RAG question-answering over a collection.

        Returns dict with keys: answer, sources, chunks_used.
        """
        vs = self._get_vectorstore(collection_id)

        from langchain.chains import RetrievalQA
        from langchain_openai import ChatOpenAI

        retriever = vs.as_retriever(search_kwargs={"k": top_k})

        effective_key = api_key or os.environ.get("OPENAI_API_KEY", "")
        llm = ChatOpenAI(model=model, api_key=effective_key or None)  # type: ignore[arg-type]

        qa_chain = RetrievalQA.from_chain_type(
            llm=llm,
            chain_type="stuff",
            retriever=retriever,
            return_source_documents=True,
        )
        result = qa_chain.invoke({"query": question})

        answer: str = result.get("result", "")
        source_docs = result.get("source_documents", [])
        sources = list({doc.metadata.get("source", "") for doc in source_docs})

        return {"answer": answer, "sources": sources, "chunks_used": len(source_docs)}

    def cleanup(self) -> None:
        """Release all vector stores."""
        logger.info("Releasing %d RAG collections.", len(self._collections))
        self._collections.clear()

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _get_vectorstore(self, collection_id: str):
        if collection_id not in self._collections:
            raise KeyError(
                f"Collection '{collection_id}' does not exist. "
                "Load documents first with /rag/load."
            )
        return self._collections[collection_id]["vectorstore"]
