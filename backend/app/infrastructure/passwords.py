import secrets

from argon2 import PasswordHasher as _Argon2
from argon2.exceptions import InvalidHashError, VerificationError


class Argon2PasswordHasher:
    """argon2id with the library's defaults (RFC 9106 low-memory profile)."""

    def __init__(self) -> None:
        self._argon2 = _Argon2()
        self._dummy: str | None = None

    def hash(self, password: str) -> str:
        return self._argon2.hash(password)

    def verify(self, password_hash: str, password: str) -> bool:
        try:
            return self._argon2.verify(password_hash, password)
        except (VerificationError, InvalidHashError):
            return False

    def dummy_hash(self) -> str:
        if self._dummy is None:
            self._dummy = self._argon2.hash(secrets.token_urlsafe(16))
        return self._dummy
