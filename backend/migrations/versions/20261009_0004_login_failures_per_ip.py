"""login_failures per (login, client IP): a stranger cannot lock a login for everyone

Existing rows (no IP known) get an empty client_ip; they expire within 15 minutes.

Revision ID: 0004
Revises: 0003
Create Date: 2026-10-09
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0004"
down_revision: str | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "login_failures",
        sa.Column("client_ip", sa.Text(), server_default=sa.text("''"), nullable=False),
    )
    op.alter_column("login_failures", "client_ip", server_default=None)
    op.drop_index("ix_login_failures_login_attempted_at", table_name="login_failures")
    op.create_index(
        "ix_login_failures_login_client_ip_attempted_at",
        "login_failures",
        ["login", "client_ip", "attempted_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_login_failures_login_client_ip_attempted_at", table_name="login_failures")
    op.create_index(
        "ix_login_failures_login_attempted_at", "login_failures", ["login", "attempted_at"]
    )
    op.drop_column("login_failures", "client_ip")
