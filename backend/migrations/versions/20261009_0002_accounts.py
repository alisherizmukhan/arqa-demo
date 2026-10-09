"""accounts: users, sessions, withdrawals; trips get an owner (driver_id)

Runs on a database that already has trips: every existing trip is assigned to
the demo driver `user_1`. If trips exist but `user_1` does not, the migration
creates it with an unusable password hash ("!" never verifies); the startup
seed then sets the configured password.

Revision ID: 0002
Revises: 0001
Create Date: 2026-10-09
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_UUID_DEFAULT = sa.text("gen_random_uuid()")


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(), server_default=_UUID_DEFAULT, nullable=False),
        sa.Column("login", sa.Text(), nullable=False),
        sa.Column("password_hash", sa.Text(), nullable=False),
        sa.Column("role", sa.Text(), nullable=False),
        sa.Column("display_name", sa.Text(), nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.PrimaryKeyConstraint("id", name="pk_users"),
        sa.UniqueConstraint("login", name="uq_users_login"),
        sa.CheckConstraint("role IN ('driver', 'admin')", name="role"),
    )

    op.create_table(
        "sessions",
        sa.Column("id", sa.Uuid(), server_default=_UUID_DEFAULT, nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("token_hash", sa.Text(), nullable=False),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "last_used_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("user_agent", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id", name="pk_sessions"),
        sa.UniqueConstraint("token_hash", name="uq_sessions_token_hash"),
        sa.ForeignKeyConstraint(
            ["user_id"], ["users.id"], name="fk_sessions_user_id_users", ondelete="CASCADE"
        ),
    )
    op.create_index("ix_sessions_user_id", "sessions", ["user_id"])

    # trips.driver_id: add nullable, backfill, then NOT NULL.
    op.add_column("trips", sa.Column("driver_id", sa.Uuid(), nullable=True))
    op.execute(
        """
        INSERT INTO users (login, password_hash, role, display_name)
        SELECT 'user_1', '!', 'driver', 'Водитель 1'
        WHERE EXISTS (SELECT 1 FROM trips)
        ON CONFLICT (login) DO NOTHING
        """
    )
    op.execute(
        """
        UPDATE trips SET driver_id = (SELECT id FROM users WHERE login = 'user_1')
        WHERE driver_id IS NULL
        """
    )
    op.alter_column("trips", "driver_id", nullable=False)
    op.create_foreign_key("fk_trips_driver_id_users", "trips", "users", ["driver_id"], ["id"])
    op.create_index("ix_trips_driver_id_start_at", "trips", ["driver_id", "start_at"])

    op.create_table(
        "withdrawals",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("driver_id", sa.Uuid(), nullable=False),
        sa.Column("amount", sa.BigInteger(), nullable=False),
        sa.Column("status", sa.Text(), server_default=sa.text("'pending'"), nullable=False),
        sa.Column("reject_reason", sa.Text(), nullable=True),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column("decided_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("decided_by", sa.Uuid(), nullable=True),
        sa.PrimaryKeyConstraint("id", name="pk_withdrawals"),
        sa.ForeignKeyConstraint(
            ["driver_id"], ["users.id"], name="fk_withdrawals_driver_id_users"
        ),
        sa.ForeignKeyConstraint(
            ["decided_by"], ["users.id"], name="fk_withdrawals_decided_by_users"
        ),
        sa.CheckConstraint("amount > 0", name="amount_positive"),
        sa.CheckConstraint("status IN ('pending', 'paid', 'rejected')", name="status"),
    )
    op.create_index(
        "ix_withdrawals_driver_id_created_at", "withdrawals", ["driver_id", "created_at"]
    )


def downgrade() -> None:
    op.drop_index("ix_withdrawals_driver_id_created_at", table_name="withdrawals")
    op.drop_table("withdrawals")
    op.drop_index("ix_trips_driver_id_start_at", table_name="trips")
    op.drop_constraint("fk_trips_driver_id_users", "trips", type_="foreignkey")
    op.drop_column("trips", "driver_id")
    op.drop_index("ix_sessions_user_id", table_name="sessions")
    op.drop_table("sessions")
    op.drop_table("users")
