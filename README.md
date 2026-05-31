# Wyvern

> LangGraph agents, HuggingFace models, and RAG pipelines — from inside MATLAB.

[![View on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/)
[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Tests](https://github.com/abhay-lal/matpy-wyvern/actions/workflows/test.yml/badge.svg)](https://github.com/abhay-lal/matpy-wyvern/actions/workflows/test.yml)

---

## What is Wyvern?

MathWorks' official [`llms-with-matlab`](https://github.com/matlab-deep-learning/llms-with-matlab) add-on
covers the basics: sending chat messages, simple tool calling, and RAG with the Text Analytics Toolbox.
Wyvern covers what it doesn't. If you need **stateful multi-step LangGraph agents**, direct access to
**HuggingFace Transformers** (embeddings, generation, classification), **multi-agent orchestration**,
or **persistent conversation memory** — Wyvern adds all of that as a clean MATLAB toolbox. You stay
entirely in MATLAB, call functions the same way you would any MathWorks toolbox, and get native MATLAB
types back. No Python code, no configuration files, no event loop headaches.

---

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| MATLAB | R2024a or later | Required |
| Python | 3.10 or later | Must be on system PATH (`python3 --version`) |
| API key | Anthropic or OpenAI | For cloud models; not needed for local HuggingFace inference |

---

## Installation

**Step 1** — Install from MATLAB Add-On Explorer

Search for **Wyvern** in the Add-On Explorer, or double-click `Wyvern.mltbx` from a downloaded release.

Alternatively, clone and add to path manually:

```bash
git clone https://github.com/abhay-lal/matpy-wyvern.git
```

```matlab
addpath(genpath('matpy-wyvern/toolbox'))
```

**Step 2** — Run one-time setup

```matlab
wyvern.setup()
% Optionally pass your API key:
% wyvern.setup(apiKey="sk-ant-your-key")
```

This checks your Python installation, installs all Python dependencies, writes your API key to
`server/.env`, starts the FastAPI server in the background, and polls until it's healthy.

**Step 3** — You're done. Start using it.

---

## Quick Start

```matlab
% ── Agents ───────────────────────────────────────────────────────────────────
wyvern.agent.create("analyst", ...
    model       = "claude-sonnet-4-6", ...
    systemPrompt= "You are a signal processing expert with MATLAB knowledge.")

response = wyvern.agent.run("analyst", ...
    "Explain what a Butterworth filter does and when to use it.")
disp(response)

% ── RAG ──────────────────────────────────────────────────────────────────────
wyvern.rag.loadDocs("papers", "/path/to/your/papers/")
answer = wyvern.rag.ask("papers", "What preprocessing steps were used?")
disp(answer)

% ── HuggingFace Embeddings ────────────────────────────────────────────────────
sentences = {"signal processing", "deep learning", "control systems"};
E = wyvern.hf.embed("all-MiniLM-L6-v2", sentences);
% E is a 3×384 double matrix — use it like any MATLAB matrix
```

---

## API Reference

### Server Lifecycle

| Function | Description | Returns |
|---|---|---|
| `wyvern.setup()` | One-time install and server start | — |
| `wyvern.start()` | Start the FastAPI server | — |
| `wyvern.stop()` | Gracefully stop the server | — |
| `wyvern.status()` | Show server health, version, and recent logs | struct |
| `wyvern.version()` | Return current toolbox version string | string |

### Agents (`wyvern.agent.*`)

| Function | Description | Returns |
|---|---|---|
| `wyvern.agent.create(id, ...)` | Create a LangGraph agent | string (agentId) |
| `wyvern.agent.run(id, msg, ...)` | Run agent, get response | string or struct |
| `wyvern.agent.stream(id, msg)` | Stream agent token output live | — (prints to console) |
| `wyvern.agent.reset(id)` | Clear agent memory | — |

**Options for `create`:**

| Name | Type | Default | Description |
|---|---|---|---|
| `model` | string | `"gpt-4o"` | LLM model name |
| `apiKey` | string | `""` | API key (else reads from `.env`) |
| `systemPrompt` | string | `"You are a helpful assistant."` | Agent persona |
| `tools` | string array | `[]` | `"web_search"`, `"calculator"` |
| `memory` | logical | `true` | Persist conversation history |

### RAG (`wyvern.rag.*`)

| Function | Description | Returns |
|---|---|---|
| `wyvern.rag.loadDocs(id, path, ...)` | Index documents into a vector store | struct |
| `wyvern.rag.search(id, query, ...)` | Semantic search, return top-k chunks | struct array |
| `wyvern.rag.ask(id, question, ...)` | RAG question answering | string or struct |

**Options for `loadDocs`:**

| Name | Type | Default |
|---|---|---|
| `fileTypes` | string array | `["pdf","txt","md"]` |
| `chunkSize` | integer | `500` |
| `chunkOverlap` | integer | `50` |
| `embeddingModel` | string | `"all-MiniLM-L6-v2"` |

### HuggingFace (`wyvern.hf.*`)

| Function | Description | Returns |
|---|---|---|
| `wyvern.hf.load(modelId, task)` | Load a HuggingFace model | — |
| `wyvern.hf.embed(modelId, texts)` | Get N×D embedding matrix | double matrix |
| `wyvern.hf.generate(modelId, prompt, ...)` | Text generation | string |
| `wyvern.hf.classify(modelId, texts, ...)` | Standard or zero-shot classification | struct |

---

## Supported Models

**Cloud LLMs (via API key)**

| Provider | Models |
|---|---|
| OpenAI | `gpt-4o`, `gpt-4o-mini`, `gpt-4-turbo` |
| Anthropic | `claude-sonnet-4-6`, `claude-haiku-4-5`, `claude-opus-4-5` |

**HuggingFace (local, no API key)**

Any model on the [HuggingFace Hub](https://huggingface.co/models) compatible with the `transformers`
pipeline interface. Tested models include:

- Embeddings: `all-MiniLM-L6-v2`, `all-mpnet-base-v2`, `BAAI/bge-small-en-v1.5`
- Zero-shot classification: `facebook/bart-large-mnli`
- Text generation: `gpt2`, `microsoft/phi-2`

**Local (no API key, no internet)**

Point to any Ollama-served model by setting `model="ollama/llama3"` — support is enabled via
LangChain's Ollama integration.

---

## How It Works

Wyvern runs a lightweight FastAPI server on `localhost:5173` that MATLAB communicates with over HTTP
using `webwrite` and `webread`. The server owns Python's `asyncio` event loop, which is what enables
stateful LangGraph agents and streaming without MATLAB deadlocks — a fundamental limitation of calling
LangGraph via `pyrun` directly. All complexity is hidden behind the server boundary: users call clean
MATLAB functions with named arguments and receive native MATLAB types (strings, structs, double
matrices) in return.

```
MATLAB (webwrite/webread)  ──HTTP──►  FastAPI server (localhost:5173)
                                           ├── /agent/*  →  LangGraph + LangChain
                                           ├── /rag/*    →  FAISS + LangChain
                                           └── /hf/*     →  HuggingFace Transformers
```

---

## Relationship to `llms-with-matlab`

Wyvern is a **complement** to, not a replacement for, MathWorks' official
[`llms-with-matlab`](https://github.com/matlab-deep-learning/llms-with-matlab) add-on. If you need
basic chat completion, simple one-shot tool calling, or RAG powered by the Text Analytics Toolbox,
use that — it's the officially supported path. Wyvern fills the gap: if you need stateful multi-step
LangGraph agents, HuggingFace model access, multi-agent orchestration, or persistent memory across
sessions, that's what Wyvern adds. The two are fully compatible; you can use both in the same MATLAB
project.

---

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, code style
guidelines, branch naming, and the pull request process. Browse
[open issues](https://github.com/abhay-lal/matpy-wyvern/issues) for ideas — especially those tagged
`good first issue`.

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

## Built on

| Library | Role |
|---|---|
| [LangChain](https://github.com/langchain-ai/langchain) | LLM orchestration and retrieval chains |
| [LangGraph](https://github.com/langchain-ai/langgraph) | Stateful agent graph execution |
| [HuggingFace Transformers](https://github.com/huggingface/transformers) | Local model inference |
| [sentence-transformers](https://github.com/UKPLab/sentence-transformers) | Dense text embeddings |
| [FastAPI](https://fastapi.tiangolo.com) | Python bridge server |
| [FAISS](https://github.com/facebookresearch/faiss) | Vector similarity search |
