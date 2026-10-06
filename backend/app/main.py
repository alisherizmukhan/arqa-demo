from fastapi import FastAPI


def create_app() -> FastAPI:
    app = FastAPI(
        title="Driver Shift Diary API",
        version="0.1.0",
        description="Trips per day, daily summary and idempotent trip creation.",
    )

    @app.get("/health", tags=["meta"])
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    return app


app = create_app()
