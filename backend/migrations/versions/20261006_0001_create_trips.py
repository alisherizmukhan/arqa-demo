"""create trips table

Revision ID: 0001
Revises:
Create Date: 2026-10-06
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "trips",
        sa.Column("id", sa.String(64), nullable=False),
        sa.Column("start_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("end_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("amount", sa.BigInteger(), nullable=False),
        sa.Column("payment", sa.String(8), nullable=False),
        sa.Column("commission", sa.BigInteger(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id", name="pk_trips"),
        sa.CheckConstraint("amount > 0", name="amount_positive"),
        sa.CheckConstraint(
            "commission >= 0 AND commission <= amount", name="commission_range"
        ),
        sa.CheckConstraint("end_at > start_at", name="time_range"),
        sa.CheckConstraint("payment IN ('cash', 'card')", name="payment_method"),
    )
    op.create_index("ix_trips_start_at", "trips", ["start_at"])


def downgrade() -> None:
    op.drop_index("ix_trips_start_at", table_name="trips")
    op.drop_table("trips")
