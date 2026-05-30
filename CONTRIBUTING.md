# Contributing to Wyvern

Welcome, and thank you for your interest in contributing to Wyvern! Whether you're fixing a bug,
proposing a new feature, improving documentation, or sharing an example, every contribution helps
make Wyvern better for the MATLAB community. Start by browsing the
[open issues](https://github.com/abhay-lal/matlab-wyvern/issues) — especially those tagged
`good first issue`.

---

## Ways to Contribute

- **Bug reports** — Found something broken? Open an issue using the bug report template.
- **Feature requests** — Have an idea for a new function or capability? Open a feature request.
- **Code** — Fix a bug or implement a feature; submit a pull request.
- **Documentation** — Improve docstrings, the README, or the Getting Started guide.
- **Examples** — Add a new `.mlx` example showing a real-world Wyvern workflow.

---

## Development Setup

### 1. Fork and clone

```bash
git clone https://github.com/YOUR_USERNAME/matlab-wyvern.git
cd matlab-wyvern
```

### 2. Install Python dependencies

```bash
pip install -r server/requirements.txt
```

### 3. Install developer tools

```bash
pip install pytest httpx pytest-asyncio ruff
```

### 4. Set up MATLAB

Open MATLAB R2024a or later, then:

```matlab
addpath(genpath('toolbox'))
wyvern.setup()
```

`wyvern.setup()` installs Python deps (if not already done), starts the FastAPI server, and
verifies the `/health` endpoint responds.

### 5. Run the Python tests

```bash
pytest tests/python/ -v
```

### 6. Run the MATLAB tests

```matlab
% Run from the matlab-wyvern root directory
runtests('tests/matlab/')
```

Or run the full suite in one command:

```matlab
run('tests/run_all_tests.m')
```

---

## Project Structure

```
matlab-wyvern/
├── server/                 Python FastAPI backend (invisible to end users)
│   ├── main.py             App entry point + /health endpoint
│   ├── requirements.txt    Pinned Python dependencies
│   ├── routers/            Route handlers: agent.py, rag.py, hf.py
│   ├── core/               Business logic: agent_manager.py, rag_manager.py, hf_manager.py
│   └── models/             Pydantic v2 schemas
│
├── toolbox/                All MATLAB code users interact with
│   └── +wyvern/            MATLAB package namespace
│       ├── setup.m         One-time setup
│       ├── agent/          wyvern.agent.* functions
│       ├── rag/            wyvern.rag.* functions
│       ├── hf/             wyvern.hf.* functions
│       └── util/           Internal helpers (not part of public API)
│
├── tests/
│   ├── python/             pytest test suite for the server
│   └── matlab/             matlab.unittest test suite for the toolbox
│
└── examples/               .mlx live scripts and sample data
```

---

## Submitting a Pull Request

1. **Create a branch** from `main` using the naming conventions below.
2. Make your changes, following the code style guidelines.
3. Ensure all tests pass locally (Python and MATLAB).
4. Update `CHANGELOG.md` under the `[Unreleased]` section.
5. Open a pull request against `main` using the PR template.

### Branch naming

| Type | Branch prefix | Example |
|---|---|---|
| New feature | `feat/` | `feat/ollama-support` |
| Bug fix | `fix/` | `fix/stream-disconnect` |
| Documentation | `docs/` | `docs/improve-readme` |
| Tests | `test/` | `test/rag-edge-cases` |
| Maintenance | `chore/` | `chore/bump-fastapi` |

---

## Code Style

### Python (`server/`)

- **Linter**: `ruff check server/` must pass with zero errors.
- **Type hints**: required on all function signatures.
- **Docstrings**: required on every class and public method (Google style).
- **Async**: all route handlers must be `async def`.
- **No print statements**: use the `logging` module.

Run the linter:

```bash
ruff check server/
ruff format server/
```

### MATLAB (`toolbox/`)

- **`arguments` blocks**: required on all functions that accept inputs.
- **H1 help line**: the first comment line must be a one-line description in all caps, e.g.
  `% WYVERN.AGENT.RUN  Run a LangGraph agent and return the response`.
- **Double-quoted strings**: use `"string"` not `'char'` for string values.
- **No `global` variables**: use `persistent` only in utility functions where shared state is
  genuinely needed.
- **Error IDs**: all `error()` calls must use the `'Wyvern:category'` identifier format.

---

## Commit Message Format

Wyvern uses [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add Ollama model support in agent_manager
fix: handle empty response from /hf/classify
docs: add zero-shot classification example
test: add edge case for empty RAG collection
chore: update langchain to 0.3.0
```

Prefix | When to use
`feat:` | A new function, endpoint, or capability
`fix:` | A bug fix
`docs:` | Documentation only (README, docstrings, .mlx files)
`test:` | Adding or improving tests
`chore:` | Dependency updates, CI, tooling — no user-visible change
`refactor:` | Code restructure with no behaviour change

Commits that introduce a breaking API change must include `BREAKING CHANGE:` in the body.

---

## Reporting Bugs

Open a [GitHub Issue](https://github.com/abhay-lal/matlab-wyvern/issues/new?template=bug_report.md)
using the bug report template. Include:

- Your MATLAB version (`version` in the MATLAB command window)
- Your Python version (`python3 --version` in terminal)
- Your OS and architecture
- The Wyvern version (`wyvern.version()`)
- The exact error message from the MATLAB command window
- The output of `wyvern.status()` (includes the last 20 server log lines)
- A minimal code example that reproduces the issue

The more detail you provide, the faster the issue can be resolved.
