from datetime import timedelta

from app.domain.errors import DomainError


class TripConflictError(DomainError):
    """The id is already taken by a trip with a different payload, or by another
    driver's trip. The message is the same in both cases: it never reveals
    another driver's data."""

    def __init__(self, trip_id: str) -> None:
        super().__init__(f"trip {trip_id!r} already exists with a different payload")
        self.trip_id = trip_id


class InvalidCredentialsError(DomainError):
    """Unknown login or wrong password (deliberately indistinguishable)."""

    def __init__(self) -> None:
        super().__init__("invalid login or password")


class AccountDisabledError(DomainError):
    """The password is right, but an admin has blocked the account."""

    def __init__(self) -> None:
        super().__init__("this account is blocked")


class TooManyLoginAttemptsError(DomainError):
    def __init__(self, retry_after: timedelta) -> None:
        super().__init__("too many failed login attempts, try again later")
        self.retry_after = retry_after


class NotAuthenticatedError(DomainError):
    """No token, or an unknown / revoked token, or the user is blocked."""

    def __init__(self, message: str = "a valid bearer token is required") -> None:
        super().__init__(message)


class ForbiddenError(DomainError):
    """Signed in, but this role may not do this."""


class NotFoundError(DomainError):
    pass


class DemoAccountProtectedError(DomainError):
    """Demo mode: visitors must not be able to break the shared demo accounts."""

    def __init__(self, login: str) -> None:
        super().__init__(f"{login!r} is a demo account and cannot be blocked or signed out")
        self.login = login


class InsufficientFundsError(DomainError):
    def __init__(self, available: int) -> None:
        super().__init__(f"amount is more than the available balance ({available})")
        self.available = available


class WithdrawalConflictError(DomainError):
    """The id is taken by a withdrawal with another amount, or by another
    driver's withdrawal (same message: nothing about it is revealed)."""

    def __init__(self, withdrawal_id: object) -> None:
        super().__init__(f"withdrawal {withdrawal_id} already exists with a different amount")


class WithdrawalAlreadyDecidedError(DomainError):
    def __init__(self, withdrawal_id: object, status: str) -> None:
        super().__init__(f"withdrawal {withdrawal_id} is already {status}")
        self.status = status
