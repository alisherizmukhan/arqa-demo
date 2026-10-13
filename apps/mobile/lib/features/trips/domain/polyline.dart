import 'package:driver_diary/features/trips/domain/entities/place.dart';

/// Decodes Google's encoded polyline format, precision 5 (what the server
/// stores, docs/MAPS.md). Throws [FormatException] for a string that is not
/// a polyline.
///
/// https://developers.google.com/maps/documentation/utilities/polylinealgorithm
List<GeoPoint> decodePolyline(String encoded) {
  final values = <int>[];
  var shift = 0;
  var result = 0;
  for (final unit in encoded.codeUnits) {
    final byte = unit - 63;
    if (byte < 0 || byte >= 64) {
      throw FormatException('not a polyline character', encoded);
    }
    result |= (byte & 0x1F) << shift;
    shift += 5;
    if (byte < 0x20) {
      values.add(result.isOdd ? ~(result >> 1) : result >> 1);
      shift = 0;
      result = 0;
    }
  }
  if (shift != 0 || values.length.isOdd) {
    throw FormatException('truncated polyline', encoded);
  }
  final points = <GeoPoint>[];
  var lat = 0;
  var lng = 0;
  for (var i = 0; i < values.length; i += 2) {
    lat += values[i];
    lng += values[i + 1];
    points.add(GeoPoint(lat / 1e5, lng / 1e5));
  }
  return points;
}
