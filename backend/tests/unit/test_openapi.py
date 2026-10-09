from typing import Any

import pytest

from app.infrastructure.settings import Settings
from app.main import create_app


@pytest.fixture(scope="module")
def spec() -> dict[str, Any]:
    # Building the schema does not touch the database.
    return create_app(Settings(seed_on_startup=False)).openapi()


def test_endpoints_are_documented(spec: dict[str, Any]) -> None:
    assert {"/health", "/trips", "/summary"} <= spec["paths"].keys()
    assert {"get", "post"} <= spec["paths"]["/trips"].keys()


def test_post_trips_documents_idempotency_outcomes(spec: dict[str, Any]) -> None:
    responses = spec["paths"]["/trips"]["post"]["responses"]

    assert {"200", "201", "409", "422"} <= responses.keys()
    error_ref = "#/components/schemas/ErrorResponse"
    assert responses["409"]["content"]["application/json"]["schema"]["$ref"] == error_ref
    assert responses["422"]["content"]["application/json"]["schema"]["$ref"] == error_ref


def test_default_fastapi_validation_schema_is_replaced(spec: dict[str, Any]) -> None:
    assert "HTTPValidationError" not in spec["components"]["schemas"]


def test_request_body_has_examples(spec: dict[str, Any]) -> None:
    body = spec["paths"]["/trips"]["post"]["requestBody"]["content"]["application/json"]
    assert {"new trip", "invalid"} <= body["examples"].keys()
    assert spec["components"]["schemas"]["TripIn"]["examples"]


def test_money_is_integer_in_schema(spec: dict[str, Any]) -> None:
    schemas = spec["components"]["schemas"]
    for name, field in [("TripIn", "amount"), ("TripIn", "commission"), ("SummaryOut", "net")]:
        assert schemas[name]["properties"][field]["type"] == "integer"


def test_bearer_scheme_is_declared(spec: dict[str, Any]) -> None:
    schemes = spec["components"]["securitySchemes"]
    assert any(s["type"] == "http" and s["scheme"] == "bearer" for s in schemes.values())
    for path, method in [("/trips", "get"), ("/summary", "get"), ("/trips", "post")]:
        assert spec["paths"][path][method]["security"]
    assert "security" not in spec["paths"]["/health"]["get"]
    assert "security" not in spec["paths"]["/auth/login"]["post"]


def test_account_endpoints_are_documented(spec: dict[str, Any]) -> None:
    paths = spec["paths"]
    assert "post" in paths["/auth/login"]
    assert "post" in paths["/auth/logout"]
    assert "get" in paths["/auth/me"]
    assert "get" in paths["/admin/users"]
    assert "patch" in paths["/admin/users/{user_id}"]
    assert "post" in paths["/admin/users/{user_id}/revoke-sessions"]


@pytest.mark.parametrize(
    ("path", "method", "codes"),
    [
        ("/trips", "post", {"401": "unauthorized", "403": "forbidden", "409": "trip_conflict"}),
        ("/summary", "get", {"401": "unauthorized", "403": "forbidden", "404": "not_found"}),
        (
            "/auth/login",
            "post",
            {
                "401": "invalid_credentials",
                "403": "account_disabled",
                "422": "missing_field",
                "429": "rate_limited",
            },
        ),
        ("/admin/users", "get", {"401": "unauthorized", "403": "forbidden"}),
        (
            "/withdrawals",
            "post",
            {
                "401": "unauthorized",
                "403": "forbidden",
                "409": "withdrawal_conflict",
                "422": "insufficient_funds",
            },
        ),
        (
            "/admin/withdrawals/{withdrawal_id}/approve",
            "post",
            {"403": "forbidden", "404": "not_found", "409": "withdrawal_already_decided"},
        ),
    ],
)
def test_error_responses_have_the_shape_and_an_example(
    spec: dict[str, Any], path: str, method: str, codes: dict[str, str]
) -> None:
    responses = spec["paths"][path][method]["responses"]
    for status, code in codes.items():
        content = responses[status]["content"]["application/json"]
        assert content["schema"]["$ref"] == "#/components/schemas/ErrorResponse"
        assert content["example"]["error"]["code"] == code


def test_withdrawal_endpoints_are_documented(spec: dict[str, Any]) -> None:
    paths = spec["paths"]
    assert "get" in paths["/balance"]
    assert {"get", "post"} <= paths["/withdrawals"].keys()
    assert "post" in paths["/admin/withdrawals/{withdrawal_id}/approve"]
    assert "post" in paths["/admin/withdrawals/{withdrawal_id}/reject"]
    assert {"200", "201"} <= paths["/withdrawals"]["post"]["responses"].keys()
