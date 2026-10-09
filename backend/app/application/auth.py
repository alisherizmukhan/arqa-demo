"""Sign-in with opaque bearer tokens.

A token is 32 random bytes (base64url). Only its sha256 is stored, so a
database leak does not leak usable tokens. Sessions never expire: one ends
when the user logs out or an admin revokes it (a non-expiring JWT could not be
revoked at all, see DECISIONS.md).
"""

import hashlib
import logging
import secrets
from dataclasses import dataclass
from datetime import datetime, timedelta

from app.application.errors import (
    AccountDisabledError,
    InvalidCredentialsError,
    NotAuthenticatedError,
    TooManyLoginAttemptsError,
)
from app.application.ports import (
    Accounts,
    LoginAttemptRepository,
    PasswordHasher,
    SessionRepository,
)
from app.domain.user import User

logger = logging.getLogger(__name__)

TOKEN_BYTES = 32
MAX_FAILED_LOGINS = 10
FAILED_LOGIN_WINDOW = timedelta(minutes=15)
# last_used_at is informational; writing it on every request would turn every
# read into a write.
SESSION_TOUCH_INTERVAL = timedelta(hours=1)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("ascii")).hexdigest()


@dataclass(frozen=True, slots=True)
class LoginRequest:
    login: str
    password: str
    client_ip: str
    user_agent: str | None = None


@dataclass(frozen=True, slots=True)
class LoginResult:
    token: str
    user: User


async def login(
    accounts: Accounts,
    attempts: LoginAttemptRepository,
    hasher: PasswordHasher,
    request: LoginRequest,
    now: datetime,
) -> LoginResult:
    """Check the password and open a session.

    - 10 failed attempts for one login from one IP within 15 minutes → that IP
      is locked for that login until the oldest failure leaves the window (even
      with the right password); other IPs can still sign in, so a stranger
      cannot lock a driver out;
    - unknown login and wrong password fail the same way, in the same time;
    - a blocked account is reported only to someone who knows its password.
    """
    users, sessions = accounts.users, accounts.sessions
    failures = await attempts.failures_since(
        request.login, request.client_ip, now - FAILED_LOGIN_WINDOW
    )
    if len(failures) >= MAX_FAILED_LOGINS:
        unlock_at = failures[-MAX_FAILED_LOGINS] + FAILED_LOGIN_WINDOW
        logger.warning(
            "login %r locked for %s until %s", request.login, request.client_ip, unlock_at
        )
        raise TooManyLoginAttemptsError(retry_after=unlock_at - now)

    user = await users.get_by_login(request.login)
    stored = await users.password_hash(request.login) if user is not None else None
    password_ok = (
        hasher.verify(stored or hasher.dummy_hash(), request.password) and stored is not None
    )
    if user is None or not password_ok:
        await attempts.record_failure(request.login, request.client_ip, now)
        logger.info("failed login for %r from %s", request.login, request.client_ip)
        raise InvalidCredentialsError
    if not user.is_active:
        raise AccountDisabledError

    token = secrets.token_urlsafe(TOKEN_BYTES)
    await sessions.create(
        user_id=user.id, token_hash=hash_token(token), user_agent=request.user_agent
    )
    return LoginResult(token=token, user=user)


async def authenticate(*, sessions: SessionRepository, token: str, now: datetime) -> User:
    """The user behind a bearer token. Unknown, revoked or blocked → error."""
    found = await sessions.find_active(hash_token(token))
    if found is None:
        raise NotAuthenticatedError("the session is unknown or has ended")
    if not found.user.is_active:
        raise NotAuthenticatedError("this account is blocked")
    if now - found.last_used_at >= SESSION_TOUCH_INTERVAL:
        await sessions.touch(found.session_id, now)
    return found.user


async def logout(*, sessions: SessionRepository, token: str, now: datetime) -> None:
    await sessions.revoke(hash_token(token), now)
