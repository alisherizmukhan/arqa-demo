from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum
from uuid import UUID


class Role(StrEnum):
    DRIVER = "driver"
    ADMIN = "admin"


@dataclass(frozen=True, slots=True, kw_only=True)
class User:
    """An account. The password hash never leaves the infrastructure layer."""

    id: UUID
    login: str
    role: Role
    display_name: str
    is_active: bool = True


@dataclass(frozen=True, slots=True, kw_only=True)
class DemoAccount:
    """A seeded account with its plaintext password (from settings, never stored)."""

    login: str
    password: str
    role: Role
    display_name: str
