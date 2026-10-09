from datetime import UTC, datetime, timedelta

import pytest

from app.application import access, auth
from app.application.errors import (
    AccountDisabledError,
    ForbiddenError,
    InvalidCredentialsError,
    NotAuthenticatedError,
    NotFoundError,
    TooManyLoginAttemptsError,
)
from app.application.ports import Accounts
from app.domain.user import Role, User
from tests.fakes import (
    InMemoryLoginAttempts,
    InMemorySessionRepository,
    InMemoryUserRepository,
    PlainTextHasher,
)

NOW = datetime(2026, 10, 9, 12, 0, tzinfo=UTC)


class World:
    def __init__(self) -> None:
        self.users = InMemoryUserRepository()
        self.sessions = InMemorySessionRepository(self.users)
        self.attempts = InMemoryLoginAttempts()
        self.hasher = PlainTextHasher()
        self.accounts = Accounts(users=self.users, sessions=self.sessions)

    async def add(self, login: str, password: str, role: Role = Role.DRIVER) -> User:
        await self.users.insert_if_absent(
            login=login, password_hash=self.hasher.hash(password), role=role, display_name=login
        )
        user = await self.users.get_by_login(login)
        assert user is not None
        return user

    async def user(self, login: str) -> User:
        user = await self.users.get_by_login(login)
        assert user is not None
        return user

    async def login(self, login: str, password: str, now: datetime = NOW) -> auth.LoginResult:
        return await auth.login(
            self.accounts,
            self.attempts,
            self.hasher,
            auth.LoginRequest(login=login, password=password, user_agent="tests"),
            now,
        )


@pytest.fixture
async def world() -> World:
    w = World()
    await w.add("user_1", "password_1")
    await w.add("user_2", "password_2")
    await w.add("admin", "admin", Role.ADMIN)
    return w


async def test_login_returns_a_token_and_stores_only_its_hash(world: World) -> None:
    result = await world.login("user_1", "password_1")

    assert result.user.login == "user_1"
    assert len(result.token) >= 43  # 32 random bytes, base64url
    assert list(world.sessions.rows) == [auth.hash_token(result.token)]
    assert world.sessions.user_agents[auth.hash_token(result.token)] == "tests"
    assert result.token not in world.sessions.rows


async def test_unknown_login_and_wrong_password_fail_the_same_way(world: World) -> None:
    with pytest.raises(InvalidCredentialsError) as wrong:
        await world.login("user_1", "nope")
    with pytest.raises(InvalidCredentialsError) as unknown:
        await world.login("ghost", "nope")

    assert str(wrong.value) == str(unknown.value)
    # The unknown login still paid for a password check (no timing difference).
    assert world.hasher.dummy_checks == 1


async def test_ten_failures_lock_the_login_for_the_window(world: World) -> None:
    for minute in range(10):
        with pytest.raises(InvalidCredentialsError):
            await world.login("user_1", "nope", NOW + timedelta(minutes=minute))

    # Locked even with the right password; other logins are not affected.
    with pytest.raises(TooManyLoginAttemptsError) as locked:
        await world.login("user_1", "password_1", NOW + timedelta(minutes=10))
    assert locked.value.retry_after == timedelta(minutes=5)
    await world.login("user_2", "password_2", NOW + timedelta(minutes=10))

    # The first failure leaves the window at 12:15: one attempt is free again.
    await world.login("user_1", "password_1", NOW + timedelta(minutes=15, seconds=1))


async def test_nine_failures_do_not_lock(world: World) -> None:
    for _ in range(9):
        with pytest.raises(InvalidCredentialsError):
            await world.login("user_1", "nope")

    await world.login("user_1", "password_1")


async def test_blocked_account_with_the_right_password(world: World) -> None:
    user = await world.user("user_1")
    await world.users.set_active(user.id, False)

    with pytest.raises(AccountDisabledError):
        await world.login("user_1", "password_1")
    with pytest.raises(InvalidCredentialsError):  # wrong password: no hint
        await world.login("user_1", "nope")


async def test_authenticate_logout_and_revoked_tokens(world: World) -> None:
    token = (await world.login("user_1", "password_1")).token

    user = await auth.authenticate(sessions=world.sessions, token=token, now=NOW)
    assert user.login == "user_1"

    await auth.logout(sessions=world.sessions, token=token, now=NOW)
    with pytest.raises(NotAuthenticatedError):
        await auth.authenticate(sessions=world.sessions, token=token, now=NOW)
    with pytest.raises(NotAuthenticatedError):
        await auth.authenticate(sessions=world.sessions, token="made-up", now=NOW)


async def test_a_blocked_users_token_stops_working(world: World) -> None:
    token = (await world.login("user_1", "password_1")).token
    user = await world.user("user_1")
    await world.users.set_active(user.id, False)

    with pytest.raises(NotAuthenticatedError):
        await auth.authenticate(sessions=world.sessions, token=token, now=NOW)


async def test_last_used_at_is_written_at_most_once_per_hour(world: World) -> None:
    token = (await world.login("user_1", "password_1")).token
    token_hash = auth.hash_token(token)

    await auth.authenticate(sessions=world.sessions, token=token, now=NOW + timedelta(minutes=59))
    assert world.sessions.rows[token_hash][2] == world.sessions.now

    later = NOW + timedelta(hours=1)
    await auth.authenticate(sessions=world.sessions, token=token, now=later)
    assert world.sessions.rows[token_hash][2] == later


async def test_driver_scope_is_always_their_own(world: World) -> None:
    driver = await world.user("user_1")
    other = await world.user("user_2")

    assert await access.trip_scope(world.users, driver, None) == driver.id
    with pytest.raises(ForbiddenError):
        await access.trip_scope(world.users, driver, other.id)
    with pytest.raises(ForbiddenError):  # even their own id: drivers never choose
        await access.trip_scope(world.users, driver, driver.id)


async def test_admin_scope_is_all_or_one_driver(world: World) -> None:
    admin = await world.user("admin")
    driver = await world.user("user_2")

    assert await access.trip_scope(world.users, admin, None) is None
    assert await access.trip_scope(world.users, admin, driver.id) == driver.id
    with pytest.raises(NotFoundError):  # an admin is not a driver
        await access.trip_scope(world.users, admin, admin.id)


async def test_only_drivers_create_records(world: World) -> None:
    admin = await world.user("admin")
    driver = await world.user("user_1")

    assert access.require_driver(driver) == driver.id
    with pytest.raises(ForbiddenError):
        access.require_driver(admin)


async def test_blocking_ends_sessions_and_admins_cannot_block_themselves(world: World) -> None:
    admin = await world.user("admin")
    driver = await world.user("user_1")
    token = (await world.login("user_1", "password_1")).token

    blocked = await access.set_user_active(
        world.accounts, admin, driver.id, is_active=False, now=NOW
    )
    assert not blocked.is_active
    with pytest.raises(NotAuthenticatedError):
        await auth.authenticate(sessions=world.sessions, token=token, now=NOW)

    with pytest.raises(ForbiddenError):
        await access.set_user_active(world.accounts, admin, admin.id, is_active=False, now=NOW)
    with pytest.raises(ForbiddenError):
        await access.set_user_active(world.accounts, driver, admin.id, is_active=False, now=NOW)


async def test_revoke_sessions(world: World) -> None:
    admin = await world.user("admin")
    driver = await world.user("user_1")
    await world.login("user_1", "password_1")
    await world.login("user_1", "password_1")

    assert await access.revoke_user_sessions(world.accounts, admin, driver.id, now=NOW) == 2
    assert await access.revoke_user_sessions(world.accounts, admin, driver.id, now=NOW) == 0
    with pytest.raises(ForbiddenError):
        await access.revoke_user_sessions(world.accounts, driver, admin.id, now=NOW)
