"""Who may see and change what. Enforced here, not in the HTTP layer, so every
entry point gets the same rules."""

from datetime import datetime
from uuid import UUID

from app.application.errors import DemoAccountProtectedError, ForbiddenError, NotFoundError
from app.application.ports import Accounts, UserRepository
from app.domain.user import Role, User


async def trip_scope(users: UserRepository, actor: User, driver_id: UUID | None) -> UUID | None:
    """The driver whose trips the request covers; None = all drivers.

    - a driver always gets their own trips and may not pass `driver_id` at all
      (403), so they can never ask for someone else's;
    - an admin gets all drivers, or one driver with `driver_id` (404 if that
      id is not a driver).
    """
    if actor.role is Role.DRIVER:
        if driver_id is not None:
            raise ForbiddenError("drivers cannot choose a driver_id")
        return actor.id
    if driver_id is None:
        return None
    driver = await users.get(driver_id)
    if driver is None or driver.role is not Role.DRIVER:
        raise NotFoundError(f"driver {driver_id} not found")
    return driver.id


def require_driver(actor: User) -> UUID:
    """Only drivers create their own records (trips, withdrawals)."""
    if actor.role is not Role.DRIVER:
        raise ForbiddenError("only drivers can do this")
    return actor.id


def require_admin(actor: User) -> None:
    if actor.role is not Role.ADMIN:
        raise ForbiddenError("admin only")


async def list_users(users: UserRepository, actor: User) -> list[User]:
    require_admin(actor)
    return await users.list_all()


async def set_user_active(
    accounts: Accounts, actor: User, user_id: UUID, *, is_active: bool, now: datetime
) -> User:
    """Block or unblock an account. Blocking also ends all its sessions, so
    unblocking later does not revive old tokens. An admin cannot block
    themselves (that could lock everyone out), and in demo mode nobody can
    block a demo account (409)."""
    require_admin(actor)
    target = await accounts.users.get(user_id)
    if target is None:
        raise NotFoundError(f"user {user_id} not found")
    if not is_active and user_id == actor.id:
        raise ForbiddenError("admins cannot block their own account")
    if not is_active and target.login in accounts.demo_logins:
        raise DemoAccountProtectedError(target.login)
    updated = await accounts.users.set_active(user_id, is_active)
    if updated is None:
        raise NotFoundError(f"user {user_id} not found")
    if not is_active:
        await accounts.sessions.revoke_all(user_id, now)
    return updated


async def revoke_user_sessions(
    accounts: Accounts, actor: User, user_id: UUID, *, now: datetime
) -> int:
    require_admin(actor)
    target = await accounts.users.get(user_id)
    if target is None:
        raise NotFoundError(f"user {user_id} not found")
    if target.login in accounts.demo_logins:
        raise DemoAccountProtectedError(target.login)
    return await accounts.sessions.revoke_all(user_id, now)
