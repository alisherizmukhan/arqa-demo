"""login_failures: failed sign-in attempts for the per-login rate limit

Revision ID: 0003
Revises: 0002
Create Date: 2026-10-09
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0003"
down_revision: str | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "login_failures",
        sa.Column("id", sa.BigInteger(), sa.Identity(), nullable=False),
        sa.Column("login", sa.Text(), nullable=False),
        sa.Column("attempted_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_login_failures"),
    )
    op.create_index(
        "ix_login_failures_login_attempted_at", "login_failures", ["login", "attempted_at"]
    )


def downgrade() -> None:
    op.drop_index("ix_login_failures_login_attempted_at", table_name="login_failures")
    op.drop_table("login_failures")
