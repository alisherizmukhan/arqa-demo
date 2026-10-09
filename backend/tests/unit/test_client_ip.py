import logging

import pytest
from starlette.requests import Request

from app.api.client_ip import UNKNOWN_CLIENT, client_ip


def _request(
    forwarded_for: str | None = None, peer: str | None = "10.0.0.5", real_ip: str | None = None
) -> Request:
    headers = [] if forwarded_for is None else [(b"x-forwarded-for", forwarded_for.encode())]
    if real_ip is not None:
        headers.append((b"x-real-ip", real_ip.encode()))
    scope = {
        "type": "http",
        "headers": headers,
        "client": None if peer is None else (peer, 1234),
    }
    return Request(scope)


def test_no_trusted_proxy_uses_the_peer_and_ignores_the_header() -> None:
    assert client_ip(_request("1.2.3.4"), trusted_hops=0) == "10.0.0.5"


def test_one_proxy_hop_uses_the_last_entry() -> None:
    assert client_ip(_request("203.0.113.7"), trusted_hops=1) == "203.0.113.7"


def test_a_forged_header_cannot_choose_the_ip() -> None:
    # The client sent "X-Forwarded-For: 1.2.3.4"; the proxy appended the real IP.
    assert client_ip(_request("1.2.3.4, 203.0.113.7"), trusted_hops=1) == "203.0.113.7"
    assert client_ip(_request("1.2.3.4,  5.6.7.8 ,203.0.113.7"), trusted_hops=1) == "203.0.113.7"


def test_two_hops_skip_the_inner_proxy() -> None:
    assert client_ip(_request("1.2.3.4, 203.0.113.7, 10.1.1.1"), trusted_hops=2) == "203.0.113.7"


@pytest.mark.parametrize("header", [None, "", " , "])
def test_without_forwarded_entries_falls_back_to_the_peer(header: str | None) -> None:
    assert client_ip(_request(header), trusted_hops=1) == "10.0.0.5"


def test_no_peer_at_all() -> None:
    assert client_ip(_request(None, peer=None), trusted_hops=0) == UNKNOWN_CLIENT


def test_proxy_set_header_wins_over_forwarded_for() -> None:
    # Railway: X-Real-IP is the client; X-Forwarded-For has the forged value
    # and Railway's own hop, but not the client.
    request = _request("1.2.3.4, 152.233.12.241", real_ip="147.30.27.152")

    assert client_ip(request, trusted_hops=0, header="x-real-ip") == "147.30.27.152"


def test_missing_proxy_header_falls_back_to_the_peer(caplog: pytest.LogCaptureFixture) -> None:
    with caplog.at_level(logging.WARNING):
        ip = client_ip(_request("1.2.3.4"), trusted_hops=0, header="x-real-ip")

    assert ip == "10.0.0.5"  # never the client's X-Forwarded-For
    assert "is missing" in caplog.text
