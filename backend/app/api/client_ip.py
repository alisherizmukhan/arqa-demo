"""The client's IP address behind a known number of proxies.

Each proxy appends the address it received the request from to
`X-Forwarded-For`, so only the last `trusted_hops` entries were written by our
own proxies; everything to their left came from the client and can be forged.
With `trusted_hops = 1` (Railway's edge) the client is the last entry.
"""

from fastapi import Request

UNKNOWN_CLIENT = "unknown"


def client_ip(request: Request, trusted_hops: int) -> str:
    if trusted_hops > 0:
        forwarded = [
            part.strip()
            for part in request.headers.get("x-forwarded-for", "").split(",")
            if part.strip()
        ]
        if len(forwarded) >= trusted_hops:
            return forwarded[-trusted_hops]
        # Fewer entries than proxies: the request did not come through them
        # (e.g. a direct internal call); fall back to the peer address.
    return request.client.host if request.client else UNKNOWN_CLIENT
