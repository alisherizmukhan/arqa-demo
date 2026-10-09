import uuid
from datetime import datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Identity,
    Index,
    MetaData,
    String,
    Text,
    Uuid,
    func,
    text,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    metadata = MetaData(
        naming_convention={
            "pk": "pk_%(table_name)s",
            "ck": "ck_%(table_name)s_%(constraint_name)s",
            "ix": "ix_%(table_name)s_%(column_0_name)s",
            "uq": "uq_%(table_name)s_%(column_0_name)s",
            "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
        }
    )


class UserRow(Base):
    """`users`: drivers and admins. Only an argon2id hash of the password is stored."""

    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid, primary_key=True, server_default=text("gen_random_uuid()")
    )
    login: Mapped[str] = mapped_column(Text, unique=True)
    password_hash: Mapped[str] = mapped_column(Text)
    role: Mapped[str] = mapped_column(Text)
    display_name: Mapped[str] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (CheckConstraint("role IN ('driver', 'admin')", name="role"),)


class SessionRow(Base):
    """`sessions`: one row per login. Only sha256(token) is stored; no expiry,
    a session ends when revoked (logout or admin)."""

    __tablename__ = "sessions"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid, primary_key=True, server_default=text("gen_random_uuid()")
    )
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    token_hash: Mapped[str] = mapped_column(Text, unique=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    last_used_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    user_agent: Mapped[str | None] = mapped_column(Text)

    __table_args__ = (Index("ix_sessions_user_id", "user_id"),)


class TripRow(Base):
    """`trips` table. Money is BIGINT tenge; timestamps are TIMESTAMPTZ (stored as UTC).

    Columns are start_at/end_at because END is a reserved word in SQL.
    CHECK constraints repeat the domain rules as a last line of defense.
    """

    __tablename__ = "trips"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    driver_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"))
    start_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    end_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    amount: Mapped[int] = mapped_column(BigInteger)
    payment: Mapped[str] = mapped_column(String(8))
    commission: Mapped[int] = mapped_column(BigInteger)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint("amount > 0", name="amount_positive"),
        CheckConstraint("commission >= 0 AND commission <= amount", name="commission_range"),
        CheckConstraint("end_at > start_at", name="time_range"),
        CheckConstraint("payment IN ('cash', 'card')", name="payment_method"),
        Index("ix_trips_start_at", "start_at"),
        Index("ix_trips_driver_id_start_at", "driver_id", "start_at"),
    )


class WithdrawalRow(Base):
    """`withdrawals`: a driver's payout request. `id` is the client's idempotency key."""

    __tablename__ = "withdrawals"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True)
    driver_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"))
    amount: Mapped[int] = mapped_column(BigInteger)
    status: Mapped[str] = mapped_column(Text, server_default=text("'pending'"))
    reject_reason: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    decided_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    decided_by: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"))

    __table_args__ = (
        CheckConstraint("amount > 0", name="amount_positive"),
        CheckConstraint("status IN ('pending', 'paid', 'rejected')", name="status"),
        Index("ix_withdrawals_driver_id_created_at", "driver_id", "created_at"),
    )


class LoginFailureRow(Base):
    """`login_failures`: failed sign-in attempts, for the per-login rate limit.
    Rows older than the window are deleted as new failures are recorded."""

    __tablename__ = "login_failures"

    id: Mapped[int] = mapped_column(BigInteger, Identity(), primary_key=True)
    login: Mapped[str] = mapped_column(Text)
    attempted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))

    __table_args__ = (Index("ix_login_failures_login_attempted_at", "login", "attempted_at"),)
