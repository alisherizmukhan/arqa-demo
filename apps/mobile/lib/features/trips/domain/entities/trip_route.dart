import 'package:driver_diary/features/trips/domain/entities/place.dart';
import 'package:driver_diary/features/trips/domain/polyline.dart';
import 'package:meta/meta.dart';

/// The server's `route.status`.
enum RouteStatus {
  /// The trip has no places.
  none,

  /// Places set, the route is not built yet.
  pending,

  /// Built by the routing engine (by road).
  ready,

  /// The map service was down: a straight line instead.
  straight,

  /// Reserved by the server (never set today).
  failed;

  /// Unknown values (a newer server) read as [none]: no line is drawn.
  static RouteStatus parse(String value) =>
      values.where((s) => s.name == value).firstOrNull ?? none;
}

/// A trip's route, built by the server; never sent by the app.
@immutable
final class TripRoute {
  const new({
    required this.status,
    this.polyline,
    this.distanceMetres,
    this.durationSeconds,
  });

  static const TripRoute none = TripRoute(status: RouteStatus.none);

  final RouteStatus status;

  /// Google encoded polyline, precision 5.
  final String? polyline;

  /// By road, or the straight-line length.
  final int? distanceMetres;

  /// The routing engine's estimate (not shown: the app shows the trip's own
  /// time, DESIGN.md §9.1).
  final int? durationSeconds;

  /// A line to draw: ready or straight, with a readable polyline.
  bool get hasLine =>
      (status == RouteStatus.ready || status == RouteStatus.straight) &&
      points.length >= 2;

  /// The line's points; empty when there is none or it cannot be read.
  List<GeoPoint> get points {
    final encoded = polyline;
    if (encoded == null || encoded.isEmpty) return const [];
    try {
      return decodePolyline(encoded);
    } on FormatException {
      return const [];
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TripRoute &&
      other.status == status &&
      other.polyline == polyline &&
      other.distanceMetres == distanceMetres &&
      other.durationSeconds == durationSeconds;

  @override
  int get hashCode =>
      Object.hash(status, polyline, distanceMetres, durationSeconds);
}
