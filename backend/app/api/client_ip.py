"""The client's IP address behind our own proxy, never a value the client chose.

Two ways, by what the proxy in front of the API does:

- `client_ip_header` (Railway: `x-real-ip`): the proxy **sets** this header to
  the address it received the request from and overwrites any value the client
  sent. Checked on Railway: a forged `X-Real-IP: 9.9.9.9` arrived as the real
  address. Railway's `X-Forwarded-For` does *not* contain the client at all
  (only what the client sent plus Railway's own hop), so it cannot be used there.
- `trusted_hops` (proxies that append to `X-Forwarded-For`): only the last
  `trusted_hops` entries were written by our proxies; everything to their left
  came from the client and can be forged.

Neither configured (local): the peer address.
"""

import logging

from fastapi import Request

logger = logging.getLogger(__name__)

UNKNOWN_CLIENT = "unknown"


def client_ip(request: Request, trusted_hops: int, header: str | None = None) -> str:
    peer = request.client.host if request.client else UNKNOWN_CLIENT
    if header:
        value = request.headers.get(header, "").strip()
        if value:
            return value
        # Misconfiguration or a request that bypassed the proxy: say so, and
        # fall back to the peer (never to a header the client controls).
        logger.warning("client IP header %r is missing; using the peer address", header)
        return peer
    if trusted_hops > 0:
        forwarded = [
            part.strip()
            for part in request.headers.get("x-forwarded-for", "").split(",")
            if part.strip()
        ]
        if len(forwarded) >= trusted_hops:
            return forwarded[-trusted_hops]
        # Fewer entries than proxies: the request did not come through them.
    return peer
