from datetime import datetime

from sqlalchemy import BigInteger, CheckConstraint, DateTime, Index, MetaData, String, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    metadata = MetaData(
        naming_convention={
            "pk": "pk_%(table_name)s",
            "ck": "ck_%(table_name)s_%(constraint_name)s",
            "ix": "ix_%(table_name)s_%(column_0_name)s",
        }
    )


class TripRow(Base):
    """`trips` table. Money is BIGINT tenge; timestamps are TIMESTAMPTZ (stored as UTC).

    Columns are start_at/end_at because END is a reserved word in SQL.
    CHECK constraints repeat the domain rules as a last line of defense.
    """

    __tablename__ = "trips"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
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
    )
