from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from fastapi import Request
from fastapi.responses import JSONResponse


@dataclass
class APIError(Exception):
    status_code: int
    code: str
    message: str
    details: dict[str, Any] | None = None


def _error_payload(code: str, message: str, details: dict[str, Any] | None, request_id: str | None) -> dict[str, Any]:
    return {
        "error": {
            "code": code,
            "message": message,
            "details": details,
        },
        "request_id": request_id,
    }


def register_error_handlers(app) -> None:
    @app.exception_handler(APIError)
    async def handle_api_error(request: Request, exc: APIError) -> JSONResponse:
        payload = _error_payload(
            code=exc.code,
            message=exc.message,
            details=exc.details,
            request_id=request.headers.get("x-request-id"),
        )
        return JSONResponse(status_code=exc.status_code, content=payload)

    @app.exception_handler(Exception)
    async def handle_unexpected_error(request: Request, _: Exception) -> JSONResponse:
        payload = _error_payload(
            code="internal_error",
            message="Unexpected server error",
            details=None,
            request_id=request.headers.get("x-request-id"),
        )
        return JSONResponse(status_code=500, content=payload)
