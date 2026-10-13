import 'dart:async';

import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/features/trips/domain/entities/place.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:driver_diary/features/trips/presentation/widgets/trip_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The picker's start view: Almaty center, zoom 12 (DESIGN.md §9.3).
const almatyCenter = GeoPoint(43.2389, 76.8897);
const _startZoom = 12.0;

/// Zoom when a place is known (set before, or the other end of the trip).
const _placeZoom = 16.0;

/// Waits before looking up the address once the map stops (§9.3).
const reverseDebounce = Duration(milliseconds: 500);

/// Waits after typing before searching (§9.3).
const searchDebounce = Duration(milliseconds: 400);

/// Shortest search text.
const searchMinLength = 3;

/// Opens the picker for the start ([DkPlaceKind.start]) or end of a trip;
/// returns the chosen place, or null when closed.
Future<Place?> pickPlace(
  BuildContext context, {
  required DkPlaceKind kind,
  Place? current,
  Place? near,
}) => Navigator.of(context).push<Place>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => PlacePickerScreen(kind: kind, current: current, near: near),
  ),
);

/// What the bottom panel says about the center of the map.
sealed class _Address {
  const new();
}

final class _Resolving extends _Address {
  const new();
}

final class _Found extends _Address {
  const new(this.label);

  final String label;
}

final class _NotFound extends _Address {
  const new();
}

final class _Offline extends _Address {
  const new();
}

/// Full-screen place picker, DESIGN.md §9.3: address search on top, the map
/// with a fixed center marker, the address of the center and «Выбрать это
/// место» at the bottom. No GPS.
class PlacePickerScreen extends ConsumerStatefulWidget {
  const new({required this.kind, this.current, this.near, super.key});

  final DkPlaceKind kind;

  /// The place chosen before: the picker starts there.
  final Place? current;

  /// Start here when nothing was chosen yet (B starts at A).
  final Place? near;

  @override
  ConsumerState<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends ConsumerState<PlacePickerScreen> {
  final MapController _map = MapController();
  final TextEditingController _query = TextEditingController();
  late GeoPoint _center =
      widget.current?.point ?? widget.near?.point ?? almatyCenter;
  late _Address _address = switch (widget.current?.label) {
    final label? => _Found(label),
    null => const _Resolving(),
  };
  Timer? _reverseTimer;
  Timer? _searchTimer;
  List<GeoPlace> _results = const [];

  /// Answers to older lookups are dropped.
  int _reverseRun = 0;
  int _searchRun = 0;

  @override
  void initState() {
    super.initState();
    if (_address is _Resolving) _scheduleReverse();
  }

  @override
  void dispose() {
    _reverseTimer?.cancel();
    _searchTimer?.cancel();
    _map.dispose();
    _query.dispose();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    // A move by the search (the controller) keeps the result's name.
    if (event.source == MapEventSource.mapController) return;
    if (event is! MapEventMove &&
        event is! MapEventMoveEnd &&
        event is! MapEventFlingAnimationEnd &&
        event is! MapEventDoubleTapZoomEnd &&
        event is! MapEventScrollWheelZoom) {
      return;
    }
    final center = geoPoint(event.camera.center);
    if (center == _center) return;
    setState(() {
      _center = center;
      _address = const _Resolving();
    });
    _scheduleReverse();
  }

  void _scheduleReverse() {
    _reverseTimer?.cancel();
    _reverseTimer = Timer(reverseDebounce, _reverse);
  }

  Future<void> _reverse() async {
    final run = ++_reverseRun;
    final point = _center;
    final result = await ref.read(geoRepositoryProvider).reverse(point);
    if (!mounted || run != _reverseRun) return;
    setState(() {
      _address = switch (result) {
        Ok(value: final label?) => _Found(label),
        Ok() => const _NotFound(),
        Err(failure: NetworkFailure()) => const _Offline(),
        // The map service is down or over its quota: the place can still be
        // chosen, with its coordinates as the label.
        Err() => const _NotFound(),
      };
    });
  }

  void _onQueryChanged(String text) {
    _searchTimer?.cancel();
    _searchRun++;
    if (text.trim().length < searchMinLength) {
      if (_results.isNotEmpty) setState(() => _results = const []);
      return;
    }
    _searchTimer = Timer(searchDebounce, () => _search(text.trim()));
  }

  Future<void> _search(String text) async {
    final run = ++_searchRun;
    final result = await ref.read(geoRepositoryProvider).search(text);
    if (!mounted || run != _searchRun) return;
    setState(() {
      _results = switch (result) {
        Ok(:final value) => value,
        Err() => const [],
      };
    });
  }

  void _choose(GeoPlace place) {
    FocusScope.of(context).unfocus();
    _reverseTimer?.cancel();
    _reverseRun++;
    _searchRun++;
    _searchTimer?.cancel();
    setState(() {
      _center = place.point;
      _address = _Found(place.label);
      _results = const [];
      _query.clear();
    });
    _map.move(latLng(place.point), _placeZoom);
  }

  void _clearQuery() {
    _query.clear();
    _onQueryChanged('');
  }

  void _confirm() => Navigator.of(context).pop(
    Place(
      point: _center,
      label: switch (_address) {
        _Found(:final label) => label,
        _ => null,
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final start = widget.kind == DkPlaceKind.start;
    final known = widget.current ?? widget.near;
    final (line, lineColor) = switch (_address) {
      _Resolving() => (l10n.resolvingAddress, colors.textTertiary),
      _Found(:final label) => (label, colors.textPrimary),
      _NotFound() ||
      _Offline() => (_center.coordinatesLabel, colors.textPrimary),
    };
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Material(
            color: colors.surface,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  spacing.s8,
                  spacing.s8,
                  spacing.s16,
                  spacing.s8,
                ),
                child: Row(
                  spacing: spacing.s4,
                  children: [
                    DkIconButton(
                      icon: DkIcons.close,
                      label: l10n.close,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: DkTextField(
                        label: l10n.searchAddress,
                        showLabel: false,
                        hint: l10n.searchAddress,
                        prefixIcon: DkIcons.search,
                        controller: _query,
                        textInputAction: TextInputAction.search,
                        onChanged: _onQueryChanged,
                        onClear: _clearQuery,
                        clearLabel: l10n.clearPlace,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: DkMapView(
              tiles: ref.watch(mapTilesProvider),
              controller: _map,
              center: latLng(known?.point ?? almatyCenter),
              zoom: known == null ? _startZoom : _placeZoom,
              rounded: false,
              onMapEvent: _onMapEvent,
              onAttributionTap: () => openMapCredits(context),
              attributionLabel: l10n.mapCredits,
              semanticsLabel: start ? l10n.placeFrom : l10n.placeTo,
              overlays: [
                // Drags that start on the pin still move the map.
                IgnorePointer(
                  child: Center(
                    child: DkPlaceMarker(
                      kind: widget.kind,
                      semanticsLabel: start ? l10n.markerStart : l10n.markerEnd,
                    ),
                  ),
                ),
                if (_results.isNotEmpty)
                  Positioned(
                    left: spacing.s16,
                    right: spacing.s16,
                    top: spacing.s8,
                    child: DkListGroup(
                      children: [
                        for (final place in _results)
                          DkListRow(
                            title: place.label,
                            icon: DkIcons.place,
                            trailing: const SizedBox.shrink(),
                            onTap: () => _choose(place),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: context.dkElevation.e3,
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.all(spacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: DkFitLines([
                        DkLine(
                          start ? l10n.placeFrom : l10n.placeTo,
                          style: text.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                        DkLine(
                          line,
                          style: text.bodyStrong.copyWith(color: lineColor),
                        ),
                        if (_address is _NotFound)
                          DkLine(
                            l10n.addressNotFound,
                            style: text.bodyS.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                      ]),
                    ),
                    if (_address is _Offline) ...[
                      SizedBox(height: spacing.s12),
                      DkInfoRow(text: l10n.mapOffline),
                    ],
                    SizedBox(height: spacing.s16),
                    DkButton(
                      label: l10n.pickThisPlace,
                      expand: true,
                      onPressed: _address is _Resolving ? null : _confirm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
