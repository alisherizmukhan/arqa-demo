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
