import pytest
from starlette.requests import Request

from app.api.client_ip import UNKNOWN_CLIENT, client_ip


def _request(forwarded_for: str | None = None, peer: str | None = "10.0.0.5") -> Request:
    headers = [] if forwarded_for is None else [(b"x-forwarded-for", forwarded_for.encode())]
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
