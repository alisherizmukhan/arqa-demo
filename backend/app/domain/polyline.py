"""Google's encoded polyline format, precision 5 (what ORS returns).

https://developers.google.com/maps/documentation/utilities/polylinealgorithm
"""

from collections.abc import Iterable

from app.domain.geo import GeoPoint

_FACTOR = 1e5


def _encode_value(value: int) -> str:
    value = ~(value << 1) if value < 0 else value << 1
    chunks = []
    while value >= 0x20:
        chunks.append(chr((0x20 | (value & 0x1F)) + 63))
        value >>= 5
    chunks.append(chr(value + 63))
    return "".join(chunks)


def encode(points: Iterable[GeoPoint]) -> str:
    out = []
    prev_lat = prev_lng = 0
    for point in points:
        lat, lng = round(point.lat * _FACTOR), round(point.lng * _FACTOR)
        out.append(_encode_value(lat - prev_lat))
        out.append(_encode_value(lng - prev_lng))
        prev_lat, prev_lng = lat, lng
    return "".join(out)


def decode(encoded: str) -> list[GeoPoint]:
    """Raises ValueError for a string that is not a polyline."""
    values: list[int] = []
    shift = result = 0
    for char in encoded:
        byte = ord(char) - 63
        if not 0 <= byte < 64:
            raise ValueError(f"not a polyline character: {char!r}")
        result |= (byte & 0x1F) << shift
        shift += 5
        if byte < 0x20:
            values.append(~(result >> 1) if result & 1 else result >> 1)
            shift = result = 0
    if shift or len(values) % 2:
        raise ValueError("truncated polyline")
    points = []
    lat = lng = 0
    for i in range(0, len(values), 2):
        lat += values[i]
        lng += values[i + 1]
        points.append(GeoPoint(lat / _FACTOR, lng / _FACTOR))
    return points
