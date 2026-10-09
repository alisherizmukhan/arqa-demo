"""Sign-in (/auth) and account administration (/admin)."""

from typing import Annotated, Any, cast
from uuid import UUID

from fastapi import APIRouter, Depends, Request, Response, status
from fastapi.security import HTTPAuthorizationCredentials

from app.api.deps import AccountsDep, CurrentUserDep, NowDep, SessionDep, bearer_scheme
from app.api.routes import AUTH_ERRORS
from app.api.schemas import (
    AdminUserOut,
    LoginIn,
    LoginOut,
    RevokedOut,
    UserOut,
    UserPatchIn,
    error_example,
)
from app.application import access, auth
from app.application.ports import PasswordHasher
from app.infrastructure.repository import SqlLoginAttemptRepository

router = APIRouter()

_ADMIN_ERRORS: dict[int | str, dict[str, Any]] = {
    **AUTH_ERRORS,
    **error_example(status.HTTP_403_FORBIDDEN, "Not an admin", "forbidden", "admin only"),
    **error_example(status.HTTP_404_NOT_FOUND, "No such user", "not_found", "user … not found"),
    **error_example(
        status.HTTP_422_UNPROCESSABLE_CONTENT,
        "Validation error (bad user id or body)",
        "invalid_type",
        "Input should be a valid boolean",
    ),
}


def _hasher(request: Request) -> PasswordHasher:
    return cast(PasswordHasher, request.app.state.hasher)


@router.post(
    "/auth/login",
    tags=["auth"],
    responses={
        **error_example(
            status.HTTP_401_UNAUTHORIZED,
            "Unknown login or wrong password (the same answer for both)",
            "invalid_credentials",
            "invalid login or password",
        ),
        **error_example(
            status.HTTP_403_FORBIDDEN,
            "Right password, but the account is blocked",
            "account_disabled",
            "this account is blocked",
        ),
        **error_example(
            status.HTTP_429_TOO_MANY_REQUESTS,
            "10 failed attempts for this login in 15 minutes; see Retry-After (seconds)",
            "rate_limited",
            "too many failed login attempts, try again later",
        ),
        **error_example(
            status.HTTP_422_UNPROCESSABLE_CONTENT,
            "Validation error",
            "missing_field",
            "Field required",
        ),
    },
)
async def login(
    body: LoginIn,
    request: Request,
    session: SessionDep,
    accounts: AccountsDep,
    now: NowDep,
) -> LoginOut:
    """Sign in. Returns an opaque bearer token that stays valid until logout or
    until an admin ends the session (it does not expire)."""
    result = await auth.login(
        accounts,
        SqlLoginAttemptRepository(session, auth.FAILED_LOGIN_WINDOW),
        _hasher(request),
        auth.LoginRequest(
            login=body.login,
            password=body.password,
            user_agent=request.headers.get("user-agent"),
        ),
        now,
    )
    return LoginOut(token=result.token, user=UserOut.from_domain(result.user))


@router.post(
    "/auth/logout",
    tags=["auth"],
    status_code=status.HTTP_204_NO_CONTENT,
    responses=AUTH_ERRORS,
)
async def logout(
    actor: CurrentUserDep,
    accounts: AccountsDep,
    now: NowDep,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
) -> Response:
    """End the current session: its token stops working at once."""
    del actor  # resolved for the 401 on a bad token
    if credentials is not None:  # without a token (AUTH_REQUIRED off) there is no session
        await auth.logout(sessions=accounts.sessions, token=credentials.credentials, now=now)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/auth/me", tags=["auth"], responses=AUTH_ERRORS)
async def me(actor: CurrentUserDep) -> UserOut:
    """The signed-in user."""
    return UserOut.from_domain(actor)


@router.get("/admin/users", tags=["admin"], responses=_ADMIN_ERRORS)
async def list_users(actor: CurrentUserDep, accounts: AccountsDep) -> list[AdminUserOut]:
    """All accounts, drivers first."""
    users = await access.list_users(accounts.users, actor)
    return [AdminUserOut.from_domain(user) for user in users]


@router.patch("/admin/users/{user_id}", tags=["admin"], responses=_ADMIN_ERRORS)
async def update_user(
    user_id: UUID, body: UserPatchIn, actor: CurrentUserDep, accounts: AccountsDep, now: NowDep
) -> AdminUserOut:
    """Block (`is_active: false`) or unblock an account. Blocking ends all its
    sessions. An admin cannot block their own account (403)."""
    user = await access.set_user_active(accounts, actor, user_id, is_active=body.is_active, now=now)
    return AdminUserOut.from_domain(user)


@router.post("/admin/users/{user_id}/revoke-sessions", tags=["admin"], responses=_ADMIN_ERRORS)
async def revoke_sessions(
    user_id: UUID, actor: CurrentUserDep, accounts: AccountsDep, now: NowDep
) -> RevokedOut:
    """End every session of the user: they are signed out on all devices."""
    return RevokedOut(revoked=await access.revoke_user_sessions(accounts, actor, user_id, now=now))
