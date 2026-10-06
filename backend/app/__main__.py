"""Local entry point: `uv run python -m app` (production uses uvicorn directly)."""

import uvicorn

from app.infrastructure.settings import Settings

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="127.0.0.1", port=Settings().port, reload=True)
