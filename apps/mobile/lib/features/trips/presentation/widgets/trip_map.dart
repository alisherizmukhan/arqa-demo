import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/features/trips/domain/entities/place.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_route.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// The routing service's short credit, added to the tile credit while a
/// route it built is on the map (DESIGN.md §9.1).
const orsAttribution = 'openrouteservice';

/// The map's full credits (the licence texts, not translated; docs/MAPS.md).
const List<String> mapCreditLines = [_osmCredit, _tilesCredit, _orsCredit];

const _osmCredit =
    'Map data © OpenStreetMap contributors, available under the Open '
    'Database License (ODbL): https://www.openstreetmap.org/copyright';
const _tilesCredit =
    'Map tiles: OpenStreetMap, https://www.openstreetmap.org — tile usage '
    'policy: https://operations.osmfoundation.org/policies/tiles/';
const _orsCredit =
    'Routes and addresses: © openrouteservice.org by HeiGIT | Map data © '
    'OpenStreetMap contributors — https://openrouteservice.org';

/// Opens the full credits (the attribution chip's tap).
Future<void> openMapCredits(BuildContext context) => showDkMapCredits(
  context,
  title: context.l10n.mapCredits,
  credits: mapCreditLines,
);

LatLng latLng(GeoPoint point) => LatLng(point.lat, point.lng);

GeoPoint geoPoint(LatLng point) => GeoPoint(point.latitude, point.longitude);

/// The line to draw for [trip]: its route, or none (no places, or the
/// route is not built yet).
DkRoute? dkRouteOf(Trip trip) {
  final route = trip.route;
  if (!route.hasLine) return null;
  return DkRoute(
    points: [for (final p in route.points) latLng(p)],
    straight: route.status == RouteStatus.straight,
    id: trip.id,
  );
}

/// The A/B markers of [trip] (none without places).
List<({LatLng point, DkPlaceKind kind, String label})> markersOf(
  Trip trip,
  AppLocalizations l10n,
) => [
  if (trip.pickup case final a?)
    (point: latLng(a.point), kind: DkPlaceKind.start, label: l10n.markerStart),
  if (trip.dropoff case final b?)
    (point: latLng(b.point), kind: DkPlaceKind.end, label: l10n.markerEnd),
];

/// Every point a map of [trips] should fit: their lines and places.
List<LatLng> fitPointsOf(Iterable<Trip> trips) => [
  for (final trip in trips) ...[
    ...?dkRouteOf(trip)?.points,
    if (trip.pickup case final a?) latLng(a.point),
    if (trip.dropoff case final b?) latLng(b.point),
  ],
];

/// Whether a route built by the routing service is drawn (its credit is
/// then shown).
bool showsOrsRoute(Iterable<Trip> trips) =>
    trips.any((t) => t.route.status == RouteStatus.ready && t.route.hasLine);

/// «Зелёный базар → ТРЦ Есентай Молл», or null without places.
String? routeLine(Trip trip, AppLocalizations l10n) {
  final (a, b) = (trip.pickup, trip.dropoff);
  if (a == null || b == null) return null;
  return l10n.routePlaces(a.displayLabel, b.displayLabel);
}

/// «850 м» / «7,4 км».
String distanceText(int metres, AppLocalizations l10n) => DkFormat.distance(
  metres,
  metresUnit: l10n.unitMetres,
  kilometresUnit: l10n.unitKilometres,
);
