"""trips: background retries of routes the engine could not build

route_attempts counts the background attempts; route_retry_at is when the
next one is due (NULL: none planned). The due-route index replaces the
pending-only one.

Revision ID: 0006
Revises: 0005
Create Date: 2026-10-14
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0006"
down_revision: str | None = "0005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "trips",
        sa.Column("route_attempts", sa.Integer(), server_default=sa.text("0"), nullable=False),
    )
    op.add_column("trips", sa.Column("route_retry_at", sa.DateTime(timezone=True), nullable=True))
    op.drop_index("ix_trips_route_pending", table_name="trips")
    op.create_index(
        "ix_trips_route_due",
        "trips",
        ["route_retry_at"],
        postgresql_where=sa.text("route_status IN ('pending', 'straight')"),
    )


def downgrade() -> None:
    op.drop_index("ix_trips_route_due", table_name="trips")
    op.create_index(
        "ix_trips_route_pending",
        "trips",
        ["created_at"],
        postgresql_where=sa.text("route_status = 'pending'"),
    )
    op.drop_column("trips", "route_retry_at")
    op.drop_column("trips", "route_attempts")
