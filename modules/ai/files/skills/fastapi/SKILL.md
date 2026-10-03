---
name: fastapi
description: "Python FastAPI & Pydantic v2 engineering: async request handling, dependency injection (Depends), schema validation, Ruff linting/formatting, and OpenAPI contract generation. Use when building Python REST APIs."
---

# FastAPI & Pydantic v2 Standards

Standards for building type-safe, asynchronous RESTful APIs using Python 3.11+, FastAPI, and Pydantic v2.

## Core Rules

1. **Async vs Sync Route Handlers**:
   - Use `async def` only when performing non-blocking async I/O (`await db.execute()`, `await httpx_client.get()`).
   - If performing blocking CPU computation or using synchronous third-party SDKs, use standard `def`; FastAPI automatically offloads synchronous handlers to an internal threadpool.

2. **Pydantic v2 Schema Modeling**:
   - Model all request bodies and responses with `pydantic.BaseModel`.
   - Separate models by layer: `UserCreate`, `UserUpdate`, and `UserResponse` (`from_attributes = True`). Never expose raw ORM models or database IDs directly to client responses.
   - Use `typing.Annotated` and `Field(...)` for validation constraints (`gt=0`, `max_length=255`).

3. **Dependency Injection**:
   - Encapsulate database sessions, authentication guards, and configuration access via `fastapi.Depends`:
     ```python
     async def get_current_user(token: Annotated[str, Depends(oauth2_scheme)], db: Annotated[AsyncSession, Depends(get_db)]) -> User:
         ...
     ```
   - Ensure resources are cleaned up safely using `async def` context-manager generators with `yield`.

4. **Code Quality & Tooling**:
   - Strictly format and lint with `ruff` (`ruff check --fix` and `ruff format`).
   - Enable strict type annotations and verify with `mypy` or `pyright`.
