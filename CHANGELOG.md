# Changelog

All notable changes to Wyvern will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [1.0.0] - 2026-05-30

### Added

- `wyvern.agent.create` — create stateful LangGraph agents from MATLAB with named-argument syntax
- `wyvern.agent.run` — invoke agents and receive responses as MATLAB strings or verbose structs
- `wyvern.agent.stream` — stream agent token output live to the MATLAB command window
- `wyvern.agent.reset` — clear agent memory and conversation state
- `wyvern.rag.loadDocs` — index PDF, TXT, and Markdown documents into a FAISS vector store
- `wyvern.rag.search` — semantic search returning top-k chunks as a MATLAB struct array
- `wyvern.rag.ask` — RAG question answering with source attribution
- `wyvern.hf.load` — load any HuggingFace model by `model_id` string
- `wyvern.hf.embed` — generate N×D embedding matrices from text inputs (double precision)
- `wyvern.hf.generate` — text generation from HuggingFace text-generation pipelines
- `wyvern.hf.classify` — standard and zero-shot classification; returns labels + scores struct
- `wyvern.setup` — one-command setup: checks Python ≥ 3.10, installs dependencies, starts server, verifies health
- `wyvern.start` / `wyvern.stop` / `wyvern.status` — server lifecycle management with cross-platform support
- `wyvern.version` — returns the current toolbox version string
- Built-in agent tools: `web_search` (DuckDuckGo) and `calculator`
- Persistent conversation memory via LangGraph `MemorySaver`
- Support for OpenAI (GPT-4o, GPT-4o-mini) and Anthropic (Claude Sonnet, Claude Haiku) cloud models
- FastAPI backend server with async LangGraph, RAG, and HuggingFace routers on `localhost:5173`
- Server-side error messages translated to human-readable MATLAB `error('Wyvern:...')` calls
- Cross-platform server launch: Windows (`start /B`), macOS and Linux (background `&`)
- Python test suite (pytest + httpx) covering all three routers with monkeypatched managers
- MATLAB test suite (`matlab.unittest.TestCase`) for agent, RAG, and HF subsystems
- `tests/run_all_tests.m` — single-command full test runner with pass/fail summary
- `GettingStarted.m` live script walkthrough with five sections
- Four example scripts: `example_basic_agent`, `example_rag_pipeline`, `example_huggingface`, `example_multiagent`
- Sample document `signal_processing_overview.txt` for RAG examples
- `packageWyvern.m` — builds `Wyvern.mltbx` for MATLAB File Exchange distribution
- GitHub Actions CI workflow (Python tests + ruff lint on Ubuntu, Windows, macOS)
- `CONTRIBUTING.md`, `.gitignore`, issue templates, and PR template
