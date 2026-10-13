import 'dart:math' as math;

import 'package:design_kit/src/components/dk_card.dart';
import 'package:design_kit/src/components/dk_chrome.dart';
import 'package:design_kit/src/format/dk_fit_text.dart';
import 'package:design_kit/src/theme/dk_context.dart';
import 'package:design_kit/src/tokens/dk_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Which end of a trip a place is: «A» (start) or «B» (end), DESIGN.md §9.
enum DkPlaceKind {
  /// Where the trip started: «A», `markerA`.
  start,

  /// Where the trip ended: «B», `markerB`.
  end;

  /// The marker letter (Latin, the same in every language).
  String get letter => this == start ? 'A' : 'B';
}

/// Map tiles, from the app's build config (never literals in widgets),
/// DESIGN.md §9.
@immutable
class DkMapTiles {
  /// Creates the tile config.
  const new({
    required this.lightUrl,
    required this.attribution,
    required this.userAgentPackageName,
    this.darkUrl,
    this.provider,
  });

  /// `{z}/{x}/{y}` URL template of the light style.
  final String lightUrl;

  /// A dark style. Null (or the same as [lightUrl]): the dark theme shows the
  /// light tiles through flutter_map's `darkModeTileBuilder` (inverted, hue
  /// rotated), so the map is never a white block next to dark cards.
  final String? darkUrl;

  /// The tiles' credit, always visible on the map, short: «© OpenStreetMap».
  final String attribution;

  /// Sent in the User-Agent (OSM tile policy).
  final String userAgentPackageName;

  /// Replaces the network (tests and previews draw tiles locally).
  final TileProvider? provider;

  /// Whether [brightness] needs the light tiles darkened.
  bool darkens(Brightness brightness) =>
      brightness == Brightness.dark && (darkUrl == null || darkUrl == lightUrl);

  /// The URL template for [brightness].
  String url(Brightness brightness) =>
      brightness == Brightness.dark ? darkUrl ?? lightUrl : lightUrl;
}

/// A map, DESIGN.md §9: radius `lg` and clipped (unless [rounded] is false,
/// the full-screen picker), the attribution always visible at the bottom
/// right, no rotation, `surfaceMuted` behind the tiles (what shows when
/// they fail to load). With [fit] the camera fits those points with
/// padding 48; otherwise it starts at [center] / [zoom].
class DkMapView extends StatelessWidget {
  /// Creates a map. Give [fit] or [center].
  const new({
    required this.tiles,
    this.fit = const [],
    this.center,
    this.zoom = 12,
    this.layers = const [],
    this.overlays = const [],
    this.controller,
    this.onMapEvent,
    this.interactive = true,
    this.rounded = true,
    this.animateTiles = true,
    this.attributionInsets = EdgeInsets.zero,
    this.extraAttribution,
    this.onAttributionTap,
    this.attributionLabel,
    this.semanticsLabel,
    super.key,
  }) : assert(fit.length > 0 || center != null, 'give fit or center'),
       assert(
         onAttributionTap == null || attributionLabel != null,
         'a tappable attribution needs its accessible name',
       );

  /// Tile source and attribution.
  final DkMapTiles tiles;

  /// Points the camera fits (a route's points, or all routes of a day).
  final List<LatLng> fit;

  /// Start center without [fit] (or with a single point).
  final LatLng? center;

  /// Start zoom with [center].
  final double zoom;

  /// Map layers above the tiles: [DkRouteLayer], [DkPlaceMarkers].
  final List<Widget> layers;

  /// Widgets above the map, not moving with it (the picker's center pin).
  final List<Widget> overlays;

  /// Moves the camera from outside (the picker's search results).
  final MapController? controller;

  /// Camera events (the picker reverse-geocodes when the map stops).
  final void Function(MapEvent event)? onMapEvent;

  /// False: a still map (no gestures).
  final bool interactive;

  /// Radius `lg` and clip (false: full screen).
  final bool rounded;

  /// False: tiles appear at once (tests, screenshots).
  final bool animateTiles;

  /// Extra space below / at the end of the attribution, to keep it clear of
  /// overlays (the picker's bottom card).
  final EdgeInsets attributionInsets;

  /// Added after the tiles' credit with « · » while the map shows its data,
  /// e.g. «openrouteservice» when an ORS route is drawn.
  final String? extraAttribution;

  /// Opens the full credits and licence links (OSM asks that they be
  /// reachable from the map).
  final VoidCallback? onAttributionTap;

  /// Accessible name of the attribution button («Данные карты»).
  final String? attributionLabel;

  /// The map's accessible name («Маршрут», «Карта дня»): an interactive
  /// map is a tappable node and needs one.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    final brightness = Theme.of(context).brightness;
    return LayoutBuilder(
      builder: (context, constraints) {
        final map = _map(context, constraints.biggest, brightness);
        final stack = Stack(
          children: [
            Positioned.fill(
              child: Semantics(label: semanticsLabel, child: map),
            ),
            ...overlays,
            PositionedDirectional(
              end: spacing.s4 + attributionInsets.right,
              bottom: attributionInsets.bottom,
              start: spacing.s48,
              child: Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: _Attribution(
                  [tiles.attribution, ?extraAttribution].join(' · '),
                  onTap: onAttributionTap,
                  label: attributionLabel,
                ),
              ),
            ),
          ],
        );
        if (!rounded) return stack;
        return ClipRRect(
          borderRadius: BorderRadius.circular(context.dkRadii.lg),
          child: stack,
        );
      },
    );
  }

  /// The fit padding: 48, less on a small map (a quarter of its shorter
  /// side), and a little more at the bottom so the attribution never covers
  /// a marker.
  EdgeInsets _fitPadding(BuildContext context, Size size) {
    final side = size.shortestSide.isFinite ? size.shortestSide : 400.0;
    final pad = math.min(context.dkSpacing.s48, side / 4);
    return EdgeInsets.fromLTRB(pad, pad, pad, pad + math.min(16, side / 8));
  }

  Widget _map(BuildContext context, Size size, Brightness brightness) {
    final colors = context.dkColors;
    final camera = fit.length > 1
        ? CameraFit.coordinates(
            coordinates: fit,
            padding: _fitPadding(context, size),
            maxZoom: _maxFitZoom,
          )
        : null;
    return FlutterMap(
      // flutter_map fits its camera once, at its first size. A fitted map is
      // built again when its size or its points change, so the fit always
      // matches what is shown (the picker centers instead and keeps its
      // camera).
      key: camera == null
          ? null
          : ValueKey(
              Object.hash(
                size.width.round(),
                size.height.round(),
                Object.hashAll(fit),
              ),
            ),
      mapController: controller,
      options: MapOptions(
        initialCenter: center ?? fit.first,
        initialZoom: zoom,
        initialCameraFit: camera,
        backgroundColor: colors.surfaceMuted,
        interactionOptions: InteractionOptions(
          flags: interactive
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
        onMapEvent: onMapEvent,
      ),
      children: [
        TileLayer(
          urlTemplate: tiles.url(brightness),
          userAgentPackageName: tiles.userAgentPackageName,
          tileProvider: tiles.provider,
          tileBuilder: tiles.darkens(brightness) ? darkModeTileBuilder : null,
          tileDisplay: animateTiles
              ? const TileDisplay.fadeIn()
              : const TileDisplay.instantaneous(),
        ),
        // Fits again after the first frame: the initial fit can be lost
        // when the map is first laid out before its final size.
        if (camera != null) _FitOnReady(camera),
        ...layers,
      ],
    );
  }
}

/// Fits the map's camera once its first frame is drawn.
class _FitOnReady extends StatefulWidget {
  const new(this.fit);

  final CameraFit fit;

  @override
  State<_FitOnReady> createState() => _FitOnReadyState();
}

class _FitOnReadyState extends State<_FitOnReady> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) MapController.of(context).fitCamera(widget.fit);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Closest a fitted camera goes: a short trip still shows its streets.
const double _maxFitZoom = 16;

/// The attribution chip, DESIGN.md §9.1: one line, 11 px, textSecondary on
/// `surface` (90 %), radius `xs`. It never wraps: a long credit scales down
/// instead. Tappable ([onTap]) through a 48 dp high area, though the chip
/// itself is small.
class _Attribution extends StatelessWidget {
  const new(this.text, {this.onTap, this.label});

  final String text;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final spacing = context.dkSpacing;
    final chip = Padding(
      padding: EdgeInsets.only(bottom: spacing.s4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(context.dkRadii.xs),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.s4, vertical: 1),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              style: context.dkText.caption.copyWith(
                fontSize: _attributionSize,
                height: _attributionLine / _attributionSize,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
    final tap = onTap;
    if (tap == null) return chip;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: context.dkSizes.tapTargetMin,
            minWidth: context.dkSizes.tapTargetMin,
          ),
          child: Align(
            alignment: AlignmentDirectional.bottomEnd,
            widthFactor: 1,
            heightFactor: 1,
            child: chip,
          ),
        ),
      ),
    );
  }
}

const double _attributionSize = 11;
const double _attributionLine = 14;

/// One route on a map: its points (decoded by the app) and whether it is
/// the straight-line fallback.
@immutable
class DkRoute {
  /// Creates a route.
  const new({required this.points, this.straight = false, this.id});

  /// The line, start to end.
  final List<LatLng> points;

  /// `route_status = straight`: drawn dashed (6/6).
  final bool straight;

  /// Given back by [DkRouteLayer.onTap] (e.g. the trip id).
  final Object? id;
}

/// Routes, DESIGN.md §9: a 5 dp line in `routeLine` over an 8 dp
/// `routeCasing`; dashed 6/6 for a straight-line fallback. With [onTap],
/// a tap on a route gives back its [DkRoute.id] (the day map).
class DkRouteLayer extends StatefulWidget {
  /// Creates the layer.
  const new({required this.routes, this.onTap, super.key});

  /// The routes, drawn in order.
  final List<DkRoute> routes;

  /// Tap on a route.
  final ValueChanged<Object>? onTap;

  @override
  State<DkRouteLayer> createState() => _DkRouteLayerState();
}

/// Line width (dp).
const double _routeWidth = 5;

/// Casing on each side: 5 + 2 × 1.5 = 8 dp in all.
const double _casingWidth = 1.5;

/// Straight-line fallback: 6 dp dash, 6 dp gap.
const List<double> _dashes = [6, 6];

class _DkRouteLayerState extends State<DkRouteLayer> {
  final LayerHitNotifier<Object> _hits = ValueNotifier(null);

  @override
  void dispose() {
    _hits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final layer = PolylineLayer<Object>(
      hitNotifier: widget.onTap == null ? null : _hits,
      minimumHitbox: context.dkSizes.tapTargetMin / 2,
      polylines: [
        for (final route in widget.routes)
          Polyline<Object>(
            points: route.points,
            strokeWidth: _routeWidth,
            color: colors.routeLine,
            borderStrokeWidth: _casingWidth,
            borderColor: colors.routeCasing,
            pattern: route.straight
                ? StrokePattern.dashed(segments: _dashes)
                : const StrokePattern.solid(),
            hitValue: route.id,
          ),
      ],
    );
    final onTap = widget.onTap;
    if (onTap == null) return layer;
    // Not a semantics node: the screen lists the same routes for screen
    // readers (the day map's legend).
    return GestureDetector(
      excludeFromSemantics: true,
      onTap: () {
        final hit = _hits.value?.hitValues;
        if (hit != null && hit.isNotEmpty) onTap(hit.first);
      },
      child: layer,
    );
  }
}

/// A place marker, DESIGN.md §9: a 32 dp circle with a 2 dp `markerRing`,
/// the letter «A» / «B» (13/800); A = `markerA`, B = `markerB`.
/// [semanticsLabel]: «Начало поездки» / «Конец поездки».
class DkPlaceMarker extends StatelessWidget {
  /// Creates a marker.
  const new({required this.kind, required this.semanticsLabel, super.key});

  /// A or B.
  final DkPlaceKind kind;

  /// Accessible name.
  final String semanticsLabel;

  /// Diameter (dp).
  static const double size = 32;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final (fill, letter) = switch (kind) {
      DkPlaceKind.start => (colors.markerA, colors.surface),
      DkPlaceKind.end => (colors.markerB, colors.onAccent),
    };
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: colors.markerRing, width: _ringWidth),
            boxShadow: context.dkElevation.e1,
          ),
          // Fixed: the letter does not grow with the text scale (§10).
          child: Center(
            child: MediaQuery.withNoTextScaling(
              child: Text(
                kind.letter,
                style: context.dkText.badge.copyWith(
                  fontSize: _letterSize,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: letter,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const double _ringWidth = 2;
const double _letterSize = 13;

/// Markers on a map: one [DkPlaceMarker] per entry, centered on its point.
class DkPlaceMarkers extends StatelessWidget {
  /// Creates the layer.
  const new({required this.places, super.key});

  /// Point, kind, accessible name.
  final List<({LatLng point, DkPlaceKind kind, String label})> places;

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        for (final place in places)
          Marker(
            point: place.point,
            width: DkPlaceMarker.size,
            height: DkPlaceMarker.size,
            child: DkPlaceMarker(kind: place.kind, semanticsLabel: place.label),
          ),
      ],
    );
  }
}

/// «Откуда» / «Куда», DESIGN.md §9: a `DkListRow`-like row, 64 high: the
/// [DkPlaceMarker] · [label] (`caption`, textTertiary) over the address
/// (`bodyStrong`) or [placeholder] (`body`, textTertiary) · a clear button
/// (48) when set and [onClear] · a chevron when [onTap]. Read-only (trip
/// details) without both. Each line is one line (§10).
class DkPlaceField extends StatelessWidget {
  /// Creates the field.
  const new({
    required this.kind,
    required this.label,
    required this.markerLabel,
    this.value,
    this.placeholder,
    this.onTap,
    this.onClear,
    this.clearLabel,
    super.key,
  }) : assert(
         onClear == null || clearLabel != null,
         'a clear button needs its accessible name',
       );

  /// A or B.
  final DkPlaceKind kind;

  /// «Откуда» / «Куда».
  final String label;

  /// «Начало поездки» / «Конец поездки» (the marker's name).
  final String markerLabel;

  /// The address, or null when not chosen.
  final String? value;

  /// «Выбрать на карте».
  final String? placeholder;

  /// Opens the place picker.
  final VoidCallback? onTap;

  /// Clears the place.
  final VoidCallback? onClear;

  /// Accessible name of the clear button.
  final String? clearLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final sizes = context.dkSizes;
    final address = value;
    final clear = address != null ? onClear : null;
    // The marker, the texts and the chevron are one node (a button when
    // [onTap]): «Начало поездки, Откуда, Зелёный базар». The clear button
    // is its own node beside it.
    final main = Padding(
      padding: EdgeInsetsDirectional.only(
        start: spacing.s16,
        end: clear != null ? 0 : spacing.s16,
      ),
      child: Row(
        spacing: spacing.s12,
        children: [
          SizedBox(
            width: sizes.iconTile,
            child: Center(
              child: DkPlaceMarker(kind: kind, semanticsLabel: markerLabel),
            ),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: DkFitLines([
                DkLine(
                  label,
                  style: text.caption.copyWith(color: colors.textTertiary),
                ),
                if (address != null)
                  DkLine(
                    address,
                    style: text.bodyStrong.copyWith(color: colors.textPrimary),
                  )
                else if (placeholder case final hint?)
                  DkLine(
                    hint,
                    style: text.body.copyWith(color: colors.textTertiary),
                  ),
              ]),
            ),
          ),
          if (clear == null && onTap != null)
            Icon(
              DkIcons.next,
              size: sizes.iconField,
              color: colors.textTertiary,
            ),
        ],
      ),
    );
    final tap = onTap;
    final tappable = MergeSemantics(
      child: tap == null
          ? main
          : Semantics(
              button: true,
              child: InkWell(onTap: tap, child: main),
            ),
    );
    return SizedBox(
      height: dkPlaceFieldHeight,
      child: Row(
        children: [
          Expanded(child: tappable),
          if (clear != null)
            Padding(
              padding: EdgeInsetsDirectional.only(end: spacing.s4),
              child: DkIconButton(
                icon: DkIcons.close,
                label: clearLabel!,
                onPressed: clear,
              ),
            ),
        ],
      ),
    );
  }
}

/// Height of a [DkPlaceField] (two lines, like a `DkListRow` with a
/// subtitle).
const double dkPlaceFieldHeight = 64;

/// «Расстояние» · «В пути» · «За км», DESIGN.md §9: three [DkSummaryTile]s
/// in a card. Values come formatted (`7,4 км`, `22 мин`, `324 ₸`).
class DkRouteStats extends StatelessWidget {
  /// Creates the stats.
  const new({required this.stats, super.key});

  /// Label and value of each tile, in order.
  final List<({String label, String value})> stats;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return DkCard(
      child: Row(
        spacing: spacing.s12,
        children: [
          for (final stat in stats)
            Expanded(
              child: DkSummaryTile(label: stat.label, value: stat.value),
            ),
        ],
      ),
    );
  }
}

/// The map's full credits (DESIGN.md §9.1): opened from the attribution
/// chip. [credits] are shown as they are (licence texts are not translated)
/// and can be selected and copied, links included.
Future<void> showDkMapCredits(
  BuildContext context, {
  required String title,
  required List<String> credits,
}) {
  final colors = context.dkColors;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surface,
    barrierColor: colors.scrim,
    useSafeArea: true,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.dkRadii.xl),
      ),
    ),
    builder: (_) => DkMapCredits(title: title, credits: credits),
  );
}

/// The content of [showDkMapCredits] (public for previews and tests).
class DkMapCredits extends StatelessWidget {
  /// Creates the content.
  const new({required this.title, required this.credits, super.key});

  /// «Данные карты».
  final String title;

  /// One paragraph each.
  final List<String> credits;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          spacing.s16,
          spacing.s20,
          spacing.s16,
          spacing.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: spacing.s12,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: text.titleM.copyWith(color: colors.textPrimary),
              ),
            ),
            for (final credit in credits)
              SelectableText(
                credit,
                style: text.bodyS.copyWith(color: colors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
