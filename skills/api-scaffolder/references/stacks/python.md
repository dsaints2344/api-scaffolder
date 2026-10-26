# Python

## Defaults
| Concern | Default |
|---|---|
| Project tool | uv (`uv init`), Python version from `uv python list` / what's installed |
| Web | FastAPI |
| Data | SQLAlchemy 2 (async) + Alembic, PostgreSQL |
| Validation / DTOs | Pydantic models at the API boundary |
| Tests | pytest + httpx `AsyncClient`, Testcontainers for the database |
| Lint/format | Ruff |
| Architecture tests | import-linter |

## Commands
```bash
uv init --package <name>
uv add fastapi "uvicorn[standard]" sqlalchemy alembic pydantic-settings asyncpg
uv add --dev pytest pytest-asyncio httpx ruff import-linter
uv run alembic init migrations
```

## Mapping layers
Packages under `src/<pkg>/` per the architecture (Clean: `domain`, `application`, `infrastructure`, `api`). `api/main.py` creates the app and wires dependencies with FastAPI's `Depends`. Domain stays free of FastAPI, Pydantic and SQLAlchemy imports; use dataclasses there.

## Pattern libraries
| Pattern | Choice |
|---|---|
| CQRS / Mediator | hand-written command/query handlers and a small dispatcher dict |
| Result | a small `Result` dataclass union, mapped to ProblemDetails responses |
| Repository + UoW | repository protocols in application, SQLAlchemy implementations, `AsyncSession` as the unit of work |
| Outbox | outbox table in the same session transaction + background worker |

## Architecture tests
In `pyproject.toml`, an import-linter `layers` contract listing the layers from outermost to innermost (`<pkg>.api`, `<pkg>.infrastructure`, `<pkg>.application`, `<pkg>.domain`). Run `uv run lint-imports`.

## Monorepo
A uv workspace: root `pyproject.toml` with `[tool.uv.workspace] members = ["services/*", "libs/*"]`.

## Verify
```bash
uv run ruff check . && uv run pytest && uv run lint-imports
```
