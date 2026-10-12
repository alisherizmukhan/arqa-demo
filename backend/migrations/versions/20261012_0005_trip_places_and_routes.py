"""trips: pickup / dropoff places and the server-built route

All new columns are nullable (old trips have no places); route_status is
'none' for them.

Revision ID: 0005
Revises: 0004
Create Date: 2026-10-12
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0005"
down_revision: str | None = "0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_COLUMNS = [
    ("pickup_lat", sa.Double()),
    ("pickup_lng", sa.Double()),
    ("dropoff_lat", sa.Double()),
    ("dropoff_lng", sa.Double()),
    ("pickup_label", sa.Text()),
    ("dropoff_label", sa.Text()),
    ("route_polyline", sa.Text()),
    ("route_distance_m", sa.Integer()),
    ("route_duration_s", sa.Integer()),
]


def upgrade() -> None:
    for name, type_ in _COLUMNS:
        op.add_column("trips", sa.Column(name, type_, nullable=True))
    op.add_column(
        "trips",
        sa.Column("route_status", sa.Text(), server_default=sa.text("'none'"), nullable=False),
    )
    op.create_check_constraint(
        op.f("ck_trips_route_status"),
        "trips",
        "route_status IN ('none', 'pending', 'ready', 'straight', 'failed')",
    )
    op.create_check_constraint(
        op.f("ck_trips_places_complete"),
        "trips",
        "(pickup_lat IS NULL) = (pickup_lng IS NULL)"
        " AND (pickup_lat IS NULL) = (dropoff_lat IS NULL)"
        " AND (pickup_lat IS NULL) = (dropoff_lng IS NULL)",
    )
    # complete_pending_routes looks these up on every start.
    op.create_index(
        "ix_trips_route_pending",
        "trips",
        ["created_at"],
        postgresql_where=sa.text("route_status = 'pending'"),
    )


def downgrade() -> None:
    op.drop_index("ix_trips_route_pending", table_name="trips")
    op.drop_constraint(op.f("ck_trips_places_complete"), "trips", type_="check")
    op.drop_constraint(op.f("ck_trips_route_status"), "trips", type_="check")
    op.drop_column("trips", "route_status")
    for name, _ in reversed(_COLUMNS):
        op.drop_column("trips", name)
