# Cursor Prompt — Wyvern: MATLAB LLM Agent Toolbox
## Model: Claude Sonnet 4.6

---

## ROLE & GOAL

You are an expert software engineer with deep knowledge of both MATLAB toolbox development and Python LLM/agent frameworks (LangChain, LangGraph, HuggingFace Transformers). Your goal is to build **Wyvern** (`matlab-wyvern`) — an open-source MATLAB toolbox that gives MATLAB users transparent access to Python's LLM ecosystem (LangChain, LangGraph, HuggingFace) without them ever needing to write Python or leave MATLAB.

The user stays entirely in MATLAB. All Python complexity is hidden behind clean, MATLAB-native function calls that feel like any other MathWorks toolbox.

---

## CONTEXT & DESIGN DECISIONS

Before writing any code, internalise these architectural decisions that have already been made:

### Why a local FastAPI server, not `pyrun` directly
MATLAB's `pyrun` is synchronous and single-threaded. LangGraph agents use Python's `asyncio` event loop internally. Calling LangGraph directly via `pyrun` risks deadlocks and broken streaming for any stateful multi-step agent. The solution is a **local FastAPI server** that MATLAB talks to over HTTP using `webwrite`/`webread`. The Python process owns its own event loop; MATLAB just makes HTTP calls. After a one-time setup, this is completely invisible to the user.

### What MathWorks already provides (do NOT duplicate)
The official `llms-with-matlab` add-on (GitHub: `matlab-deep-learning/llms-with-matlab`) already handles:
- Basic OpenAI / Azure / Ollama chat calls
- Simple tool calling via `openAIFunction`
- Basic RAG with MATLAB Text Analytics Toolbox

**Do not re-implement these.** Wyvern fills the gap — stateful LangGraph agents, HuggingFace model access, multi-agent orchestration, and persistent memory — things the official add-on does not cover.

### Distribution target
The toolbox will be open-sourced on GitHub as `matlab-wyvern` and listed on MATLAB File Exchange so it appears in MATLAB's Add-On Explorer. Follow MathWorks' official toolbox design best practices (`github.com/mathworks/toolboxdesign`).

---

## FULL REPOSITORY STRUCTURE TO BUILD

```
matlab-wyvern/
│
├── README.md
├── LICENSE                          (MIT)
├── CHANGELOG.md
│
├── toolbox/                         ← all MATLAB code users interact with
│   │
│   ├── +wyvern/                     ← MATLAB package namespace
│   │   ├── setup.m                  ← one-time setup: checks Python, installs deps, starts server
│   │   ├── start.m                  ← start the FastAPI server (called by setup or manually)
│   │   ├── stop.m                   ← gracefully stop the server
│   │   ├── status.m                 ← check if server is running, return health info
│   │   │
│   │   ├── agent/
│   │   │   ├── create.m             ← define a LangGraph agent with tools + memory
│   │   │   ├── run.m                ← invoke agent, return final response as string/struct
│   │   │   ├── stream.m             ← invoke agent, print tokens as they arrive
│   │   │   └── reset.m              ← clear agent memory/state
│   │   │
│   │   ├── rag/
│   │   │   ├── loadDocs.m           ← index folder of PDFs/TXTs into vector store
│   │   │   ├── search.m             ← semantic search, return top-k chunks as cell array
│   │   │   └── ask.m                ← RAG question answering, return answer string
│   │   │
│   │   ├── hf/
│   │   │   ├── load.m               ← load a HuggingFace model by model_id string
│   │   │   ├── embed.m              ← get embeddings matrix from text cell array
│   │   │   ├── generate.m           ← text generation, return string
│   │   │   └── classify.m           ← zero-shot or sequence classification
│   │   │
│   │   └── util/
│   │       ├── mat2json.m           ← safe MATLAB → JSON string conversion
│   │       ├── json2mat.m           ← JSON string → MATLAB struct/array
│   │       ├── checkServer.m        ← internal: ping server, throw friendly error if down
│   │       └── postRequest.m        ← internal: wrapper around webwrite with error handling
│   │
│   └── doc/
│       └── GettingStarted.mlx       ← MATLAB Live Script walkthrough
│
├── examples/
│   ├── example_basic_agent.mlx
│   ├── example_rag_pipeline.mlx
│   ├── example_huggingface.mlx
│   └── example_multiagent.mlx
│
├── server/                          ← Python FastAPI backend (invisible to users)
│   ├── main.py                      ← FastAPI app entry point
│   ├── requirements.txt             ← pinned Python dependencies
│   │
│   ├── routers/
│   │   ├── agent.py                 ← /agent/create, /agent/run, /agent/stream, /agent/reset
│   │   ├── rag.py                   ← /rag/load, /rag/search, /rag/ask
│   │   └── hf.py                   ← /hf/load, /hf/embed, /hf/generate, /hf/classify
│   │
│   ├── core/
│   │   ├── agent_manager.py         ← LangGraph agent lifecycle, state persistence
│   │   ├── rag_manager.py           ← document loading, FAISS vector store, retrieval
│   │   └── hf_manager.py            ← HuggingFace pipeline management, caching
│   │
│   └── models/
│       ├── agent_models.py          ← Pydantic request/response schemas for agent routes
│       ├── rag_models.py            ← Pydantic schemas for RAG routes
│       └── hf_models.py             ← Pydantic schemas for HF routes
│
└── tests/
    ├── matlab/
    │   ├── test_agent.m
    │   ├── test_rag.m
    │   └── test_hf.m
    └── python/
        ├── test_agent_router.py
        ├── test_rag_router.py
        └── test_hf_router.py
```

---

## DETAILED SPECIFICATIONS

### SERVER — `server/main.py`

```
- FastAPI app on localhost:5173 (default port, configurable)
- CORS enabled for localhost only
- Lifespan startup: initialise agent_manager, rag_manager, hf_manager singletons
- GET /health → {"status": "ok", "version": "x.x.x"}
- Include routers: /agent, /rag, /hf
- Uvicorn run with single worker (MATLAB is single-threaded caller anyway)
- Graceful shutdown cleans up loaded models and vector stores
```

### SERVER — `server/requirements.txt`

```
fastapi>=0.111.0
uvicorn[standard]>=0.29.0
langchain>=0.2.0
langchain-openai>=0.1.0
langchain-community>=0.2.0
langgraph>=0.1.0
huggingface-hub>=0.23.0
transformers>=4.40.0
sentence-transformers>=3.0.0
faiss-cpu>=1.8.0
pydantic>=2.0.0
python-dotenv>=1.0.0
torch>=2.0.0
```

### SERVER — Agent Router `/agent`

```
POST /agent/create
  body: {
    agent_id: string,           ← user-defined name, e.g. "signal_analyst"
    model: string,              ← "gpt-4o", "claude-sonnet-4-6", etc.
    api_key: string | null,     ← if null, reads from env
    system_prompt: string,
    tools: string[],            ← list of built-in tool names: "web_search", "calculator", "matlab_exec"
    memory: bool                ← whether to persist conversation state
  }
  response: { agent_id: string, status: "created" }

POST /agent/run
  body: { agent_id: string, message: string, context: object | null }
  response: { response: string, steps: object[], tokens_used: int }

POST /agent/stream
  body: { agent_id: string, message: string }
  response: StreamingResponse (text/event-stream, SSE)
  ← each event is a token chunk; MATLAB reads full response when done

POST /agent/reset
  body: { agent_id: string }
  response: { status: "reset" }
```

### SERVER — RAG Router `/rag`

```
POST /rag/load
  body: {
    collection_id: string,      ← user-defined name for this document set
    path: string,               ← absolute path to folder or single file
    file_types: string[],       ← e.g. ["pdf", "txt", "md"]
    chunk_size: int,            ← default 500
    chunk_overlap: int,         ← default 50
    embedding_model: string     ← default "all-MiniLM-L6-v2"
  }
  response: { collection_id: string, chunks_indexed: int, status: "ready" }

POST /rag/search
  body: { collection_id: string, query: string, top_k: int }
  response: { chunks: [{ text: string, source: string, score: float }] }

POST /rag/ask
  body: {
    collection_id: string,
    question: string,
    model: string,
    api_key: string | null,
    top_k: int
  }
  response: { answer: string, sources: string[], chunks_used: int }
```

### SERVER — HuggingFace Router `/hf`

```
POST /hf/load
  body: { model_id: string, task: string, device: "cpu"|"cuda"|"auto" }
  response: { model_id: string, task: string, status: "loaded" }

POST /hf/embed
  body: { model_id: string, texts: string[] }
  response: { embeddings: float[][], shape: int[] }

POST /hf/generate
  body: {
    model_id: string,
    prompt: string,
    max_new_tokens: int,
    temperature: float,
    do_sample: bool
  }
  response: { generated_text: string }

POST /hf/classify
  body: {
    model_id: string,
    texts: string[],
    labels: string[] | null    ← null for standard classification, list for zero-shot
  }
  response: { labels: string[], scores: float[][] }
```

---

### MATLAB — `toolbox/+wyvern/setup.m`

This is the most important MATLAB file. It must:

1. Check Python is installed and version ≥ 3.10
2. Check pip is available
3. Run `pip install -r server/requirements.txt` (path relative to toolbox root)
4. Write a `.env` file in `server/` if the user provides API keys (prompt them)
5. Start the FastAPI server as a background process using MATLAB's `system()` with `&` (Unix) or `start /B` (Windows)
6. Poll `GET /health` in a loop (max 30s) until server responds
7. Save server PID to a temp file for `wyvern.stop()` to use later
8. Print a friendly success message with example usage

```matlab
% Example usage printed on success:
% ✓ Wyvern server running on localhost:5173
% 
% Quick start:
%   wyvern.agent.create("myAgent", model="claude-sonnet-4-6", systemPrompt="You are a signal processing expert")
%   response = wyvern.agent.run("myAgent", "Explain this FFT output")
%   wyvern.rag.loadDocs("myDocs", "/path/to/papers/")
%   answer = wyvern.rag.ask("myDocs", "What preprocessing steps were used?")
```

### MATLAB — `toolbox/+wyvern/agent/create.m`

```matlab
function agentId = create(agentId, options)
% WYVERN.AGENT.CREATE  Create a LangGraph agent
%
%   wyvern.agent.create("analyst") creates agent with defaults
%   wyvern.agent.create("analyst", model="claude-sonnet-4-6", systemPrompt="You are...")
%   wyvern.agent.create("analyst", tools=["web_search","calculator"], memory=true)
%
% Arguments:
%   agentId     - string, unique name for this agent
%   model       - string, LLM model name (default: "claude-sonnet-4-6")
%   apiKey      - string, API key (default: reads from .env)
%   systemPrompt- string, agent persona/instructions
%   tools       - string array, tool names to equip agent with
%   memory      - logical, persist conversation history (default: true)
```

Use `arguments` block with `options.model = "gpt-4o"` etc. for named args.
Call `wyvern.util.postRequest("/agent/create", payload)` internally.
Return the agentId for chaining.

### MATLAB — `toolbox/+wyvern/agent/run.m`

```matlab
function result = run(agentId, message, options)
% WYVERN.AGENT.RUN  Run a LangGraph agent and return the response
%
%   response = wyvern.agent.run("analyst", "Summarise the signal anomaly")
%   result = wyvern.agent.run("analyst", "Analyse this", context=myStruct)
%
% Returns either a string (default) or struct with .response, .steps, .tokensUsed
% if options.verbose = true

% result.response — string answer
% result.steps    — cell array of intermediate reasoning steps
% result.tokensUsed — integer
```

### MATLAB — `toolbox/+wyvern/rag/loadDocs.m`

```matlab
function status = loadDocs(collectionId, folderPath, options)
% WYVERN.RAG.LOADDOCS  Index documents into a vector store
%
%   wyvern.rag.loadDocs("papers", "/home/user/research/")
%   wyvern.rag.loadDocs("papers", "/home/user/research/", fileTypes=["pdf","txt"])
%   wyvern.rag.loadDocs("papers", "/home/user/research/", chunkSize=800)
%
% Prints progress: "Indexing 47 chunks from 12 documents..."
% Returns struct: status.collectionId, status.chunksIndexed, status.ready
```

### MATLAB — `toolbox/+wyvern/hf/embed.m`

```matlab
function embeddings = embed(modelId, texts)
% WYVERN.HF.EMBED  Get embedding vectors from a HuggingFace model
%
%   E = wyvern.hf.embed("all-MiniLM-L6-v2", {"sentence one", "sentence two"})
%   % E is an N×D double matrix (N texts, D embedding dimensions)
%
%   % Find most similar text:
%   query = wyvern.hf.embed("all-MiniLM-L6-v2", {"my query"})
%   similarities = E * query' ./ (vecnorm(E,2,2) * norm(query))
%   [~, idx] = max(similarities)

% texts can be a string array, char, or cell array of strings
% Always returns double matrix regardless of model output format
```

### MATLAB — `toolbox/+wyvern/util/postRequest.m`

This is the internal HTTP workhorse. Must handle:
- Build full URL from `http://localhost:5173` + endpoint
- Set Content-Type to application/json
- Use `webwrite` with `weboptions('MediaType','application/json')`
- Catch `webwrite` errors and throw friendly MATLAB errors
- Handle server-not-running case with: "Wyvern server is not running. Call wyvern.setup() to start it."
- Return parsed JSON as MATLAB struct

---

## ERROR HANDLING STANDARDS

Every MATLAB function must handle these cases gracefully:

```
Server not running     → "Wyvern server is not running. Call wyvern.setup() first."
Agent not found        → "Agent 'X' does not exist. Create it first with wyvern.agent.create('X')."
Invalid model name     → "Model 'X' is not supported. Supported: gpt-4o, claude-sonnet-4-6, ..."
API key missing        → "No API key found. Set it in wyvern.setup() or in server/.env"
Python not found       → "Python 3.10+ is required. Install from python.org and re-run wyvern.setup()."
Port conflict          → "Port 5173 is in use. Call wyvern.start(port=5174) to use a different port."
File not found (RAG)   → "Path 'X' does not exist or is not accessible."
```

Never expose Python tracebacks to MATLAB users. Catch all server 4xx/5xx responses and translate to human-readable MATLAB errors using `error('Wyvern:category', 'message')`.

---

## TESTING REQUIREMENTS

### Python tests (`tests/python/`)
Use `pytest` with `httpx` for async FastAPI testing.
Each router needs tests for:
- Happy path (valid inputs, expected outputs)
- Invalid agent/collection ID (404 response)
- Missing required fields (422 validation error)
- Server startup and health check

### MATLAB tests (`tests/matlab/`)
Use MATLAB's built-in `matlab.unittest` framework.
Each test file should extend `matlab.unittest.TestCase`.
Tests need a running server (call `wyvern.setup()` in `TestClassSetup`).
Test:
- `wyvern.agent.create` returns correct agentId
- `wyvern.agent.run` returns non-empty string
- `wyvern.rag.loadDocs` returns correct chunk count
- `wyvern.rag.ask` returns non-empty string
- `wyvern.hf.embed` returns correct matrix dimensions
- All error cases throw expected error IDs

---

## DOCUMENTATION REQUIREMENTS

### `README.md` must include:
1. One-paragraph description of what this is
2. Prerequisites (MATLAB R2024a+, Python 3.10+, API key)
3. Installation (3 steps: clone, open MATLAB, run `wyvern.setup()`)
4. Quick start code block (5 lines showing agent + RAG + HF)
5. API reference table (function | description | returns)
6. "Open in MATLAB Online" badge (placeholder link)
7. "View on File Exchange" badge (placeholder link)
8. License section (MIT)
9. Contributing section
10. "Built on top of" credits: LangChain, LangGraph, HuggingFace, FastAPI

### `GettingStarted.mlx` (MATLAB Live Script) must:
- Be runnable top-to-bottom with no modifications (just needs API key in .env)
- Section 1: Setup and health check
- Section 2: First agent (simple Q&A)
- Section 3: RAG over a sample document (include a small sample .txt in examples/)
- Section 4: HuggingFace embedding + similarity search
- Section 5: Multi-turn conversation with memory
- Include inline output and plots where relevant

---

## CROSS-PLATFORM REQUIREMENTS

The server startup in `wyvern.setup()` must work on:

```matlab
% Windows
system('start /B python server/main.py > server.log 2>&1')

% macOS / Linux  
system('python3 server/main.py > server/server.log 2>&1 &')
```

Detect OS using `ispc`, `ismac`, `isunix`.
Store the server log path in a persistent variable for debugging.
`wyvern.status()` should tail the last 20 lines of server.log and display them.

---

## BUILD ORDER — IMPLEMENT IN THIS SEQUENCE

Build in this exact order. Each step should be complete and tested before moving to the next:

```
Step 1  server/main.py + /health endpoint only
        → verify with curl http://localhost:5173/health

Step 2  server/routers/hf.py + server/core/hf_manager.py
        → /hf/load, /hf/embed, /hf/generate, /hf/classify

Step 3  server/routers/rag.py + server/core/rag_manager.py
        → /rag/load, /rag/search, /rag/ask

Step 4  server/routers/agent.py + server/core/agent_manager.py
        → /agent/create, /agent/run (stream last)

Step 5  toolbox/+wyvern/util/ (postRequest.m, mat2json.m, json2mat.m, checkServer.m)
        → unit test each utility independently

Step 6  toolbox/+wyvern/setup.m + start.m + stop.m + status.m
        → full end-to-end: MATLAB starts server, MATLAB pings health

Step 7  toolbox/+wyvern/hf/ (load.m, embed.m, generate.m, classify.m)
        → test from MATLAB against running server

Step 8  toolbox/+wyvern/rag/ (loadDocs.m, search.m, ask.m)
        → test from MATLAB

Step 9  toolbox/+wyvern/agent/ (create.m, run.m, stream.m, reset.m)
        → test from MATLAB

Step 10 tests/ (Python pytest suite + MATLAB unittest suite)

Step 11 docs/ (README.md + GettingStarted.mlx + all example .mlx files)

Step 12 Package as Wyvern.mltbx using MATLAB toolbox packaging
```

---

## STYLE CONSTRAINTS

### Python (server/)
- Python 3.10+ type hints everywhere
- Pydantic v2 models for all request/response schemas
- Async route handlers throughout (`async def`)
- Structured logging with `logging` module (not print statements)
- All managers as singletons initialised at server startup
- No global mutable state outside manager classes
- Docstrings on every class and public method

### MATLAB (toolbox/)
- `arguments` blocks for all function inputs (MATLAB R2021a+ style)
- `%` comments explaining every non-obvious line
- Function docstrings in standard MATLAB help format (first line = H1 line)
- Use string type (double-quoted) not char arrays
- Package namespace `+wyvern` for all user-facing functions
- `private/` subfolder for internal utilities not meant for users
- No `global` variables — use persistent variables in utility functions where state is needed

---

## WHAT NOT TO BUILD

To keep scope tight for v1.0, explicitly do NOT build:

- A MATLAB GUI or App Designer interface (command-line only)
- Multi-user server (single user, localhost only)
- Authentication or API key management beyond .env file
- Model fine-tuning (inference only for HuggingFace)
- GPU training pipelines
- Cloud deployment of the FastAPI server
- Support for MATLAB versions before R2024a
- Windows ARM support
- Any re-implementation of what `llms-with-matlab` already does (basic chat, simple tool calling)

---

## FIRST MESSAGE TO SEND AFTER THIS PROMPT

After reading and confirming you understand this spec, start with Step 1:

Build `server/main.py` with the FastAPI app, lifespan context manager, and the `/health` endpoint. Also create `server/requirements.txt`. Show me the complete files, then tell me how to test the health endpoint manually before we proceed to Step 2.
```