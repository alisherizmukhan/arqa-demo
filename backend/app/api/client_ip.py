"""The client's IP address behind a known number of proxies.

Each proxy appends the address it received the request from to
`X-Forwarded-For`, so only the last `trusted_hops` entries were written by our
own proxies; everything to their left came from the client and can be forged.
With `trusted_hops = 1` (Railway's edge) the client is the last entry.

Railway also sends `X-Real-IP` (documented as the client's address). It is used
only as a cross-check: a mismatch is logged, so a wrong TRUSTED_PROXY_HOPS or a
change in the proxy chain shows up in the logs instead of silently weakening
the login rate limit.
"""

import logging

from fastapi import Request

logger = logging.getLogger(__name__)

UNKNOWN_CLIENT = "unknown"


def client_ip(request: Request, trusted_hops: int) -> str:
    if trusted_hops > 0:
        forwarded = [
            part.strip()
            for part in request.headers.get("x-forwarded-for", "").split(",")
            if part.strip()
        ]
        if len(forwarded) >= trusted_hops:
            ip = forwarded[-trusted_hops]
            real_ip = request.headers.get("x-real-ip")
            if real_ip != ip:
                logger.warning(
                    "client IP from X-Forwarded-For (%s, %d entries, %d trusted) "
                    "differs from X-Real-IP (%s): check TRUSTED_PROXY_HOPS",
                    ip,
                    len(forwarded),
                    trusted_hops,
                    real_ip,
                )
            return ip
        # Fewer entries than proxies: the request did not come through them
        # (e.g. a direct internal call); fall back to the peer address.
    return request.client.host if request.client else UNKNOWN_CLIENT
