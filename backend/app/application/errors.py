from app.domain.errors import DomainError


class TripConflictError(DomainError):
    """The id is already taken by a trip with a different payload."""

    def __init__(self, trip_id: str) -> None:
        super().__init__(f"trip {trip_id!r} already exists with a different payload")
        self.trip_id = trip_id
