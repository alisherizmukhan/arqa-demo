import 'package:meta/meta.dart';

/// A point on the map, in degrees.
@immutable
final class GeoPoint {
  const new(this.lat, this.lng);

  final double lat;
  final double lng;

  /// «43.2380, 76.9455»: the label of a place whose address was not found
  /// (DESIGN.md §9.6). Four decimals (~11 m), a dot, not a localized number.
  String get coordinatesLabel =>
      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'GeoPoint($lat, $lng)';
}

/// Where a trip started or ended: a point and the address the driver saw.
@immutable
final class Place {
  const new({required this.point, this.label});

  final GeoPoint point;

  /// The address or place name; null when none was found.
  final String? label;

  /// What to show for the place: its label, or its coordinates.
  String get displayLabel => label ?? point.coordinatesLabel;

  @override
  bool operator ==(Object other) =>
      other is Place && other.point == point && other.label == label;

  @override
  int get hashCode => Object.hash(point, label);

  @override
  String toString() => 'Place(${point.lat}, ${point.lng}, $label)';
}

/// An address search result.
typedef GeoPlace = ({String label, GeoPoint point});
