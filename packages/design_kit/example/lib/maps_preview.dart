// Previews of the DESIGN.md §9 screens (add trip with places, place picker,
// trip details, day screen, day map), built only from kit components with
// static data, in Russian and Kazakh. Stage 2: not wired to the app; the app
// builds its screens from the same components in stage 3. Tiles are drawn
// locally (DkSketchTileProvider); the routes are real ORS routes between the
// seed places (maps_routes.dart).

import 'package:design_kit/design_kit.dart';
import 'package:design_kit_example/maps_copy.dart';
import 'package:design_kit_example/maps_routes.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// One screen state, in one language.
typedef MapsPreview = ({
  String id,
  String title,
  Widget Function(MapsCopy copy) build,
});

/// The seed places (data/trips.json).
abstract final class Places {
  /// Зелёный базар.
  static const bazaar = LatLng(43.26275, 76.95519);

  /// ТРЦ Есентай Молл.
  static const esentai = LatLng(43.2189, 76.9279);

  /// Площадь Республики.
  static const republic = LatLng(43.238, 76.9455);

  /// Аэропорт Алматы.
  static const airport = LatLng(43.3521, 77.0405);

  /// ТРЦ MEGA Alma-Ata.
  static const mega = LatLng(43.2026, 76.8946);

  /// Almaty center: the picker's start view.
  static const almaty = LatLng(43.2389, 76.8897);
}

/// The compact credits (DESIGN.md §9.1); the full ones open from the chip.
const _osm = '© OpenStreetMap';
const _ors = '© openrouteservice.org by HeiGIT';

DkMapTiles _tiles({bool offline = false}) => DkMapTiles(
  lightUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  attribution: _osm,
  userAgentPackageName: 'kz.driverdiary.design_kit_example',
  provider: DkSketchTileProvider(offline: offline),
);

String _km(MapsCopy c, int metres) => DkFormat.distance(
  metres,
  metresUnit: c.metres,
  kilometresUnit: c.kilometres,
);

/// A trip on the previews.
typedef _Trip = ({
  String start,
  String end,
  Duration duration,
  int amount,
  int commission,
  DkPaymentMethod method,
  String? from,
  String? to,
  PreviewRoute? route,
  LatLng? a,
  LatLng? b,
});

_Trip _t1(MapsCopy c) => (
  start: '08:10',
  end: '08:32',
  duration: const Duration(minutes: 22),
  amount: 2400,
  commission: 360,
  method: DkPaymentMethod.card,
  from: 'Зелёный базар',
  to: 'ТРЦ Есентай Молл',
  route: bazaarToEsentai,
  a: Places.bazaar,
  b: Places.esentai,
);

_Trip _t2(MapsCopy c) => (
  start: '09:05',
  end: '09:20',
  duration: const Duration(minutes: 15),
  amount: 1500,
  commission: 225,
  method: DkPaymentMethod.cash,
  from: 'ТРЦ Есентай Молл',
  to: 'Площадь Республики',
  route: esentaiToRepublic,
  a: Places.esentai,
  b: Places.republic,
);

/// A trip saved without places (stays read-only).
_Trip _plain(MapsCopy c) => (
  start: '13:40',
  end: '14:05',
  duration: const Duration(minutes: 25),
  amount: 1900,
  commission: 285,
  method: DkPaymentMethod.cash,
  from: null,
  to: null,
  route: null,
  a: null,
  b: null,
);

_Trip _u2t1(MapsCopy c) => (
  start: '10:00',
  end: '10:40',
  duration: const Duration(minutes: 40),
  amount: 3000,
  commission: 450,
  method: DkPaymentMethod.card,
  from: 'Площадь Республики',
  to: 'Аэропорт Алматы',
  route: republicToAirport,
  a: Places.republic,
  b: Places.airport,
);

_Trip _u2t2(MapsCopy c) => (
  start: '12:15',
  end: '12:35',
  duration: const Duration(minutes: 20),
  amount: 1800,
  commission: 270,
  method: DkPaymentMethod.cash,
  from: 'ТРЦ MEGA Alma-Ata',
  to: 'ТРЦ Есентай Молл',
  route: megaToEsentai,
  a: Places.mega,
  b: Places.esentai,
);

/// Every state, in review order.
final List<MapsPreview> mapsPreviews = [
  (
    id: 'm01_add_trip_no_places',
    title: 'Новая поездка — места не выбраны',
    build: (c) => _AddTrip(copy: c),
  ),
  (
    id: 'm02_add_trip_places',
    title: 'Новая поездка — оба места выбраны',
    build: (c) =>
        _AddTrip(copy: c, from: 'Зелёный базар', to: 'ТРЦ Есентай Молл'),
  ),
  (
    id: 'm03_add_trip_incomplete',
    title: 'Новая поездка — только «Откуда»',
    build: (c) =>
        _AddTrip(copy: c, from: 'Зелёный базар', error: c.errIncomplete),
  ),
  (
    id: 'm04_add_trip_outside',
    title: 'Новая поездка — точка вне Алматы (ответ сервера)',
    build: (c) => _AddTrip(
      copy: c,
      from: 'Зелёный базар',
      to: '43.5100, 76.9000',
      error: c.errOutside,
    ),
  ),
  (
    id: 'm05_picker_start',
    title: 'Выбор места — «Откуда», адрес найден',
    build: (c) => _Picker(copy: c, address: 'площадь Республики, 2'),
  ),
  (
    id: 'm06_picker_resolving',
    title: 'Выбор места — определяем адрес',
    build: (c) => _Picker(copy: c, resolving: true),
  ),
  (
    id: 'm07_picker_not_found',
    title: 'Выбор места — адрес не найден',
    build: (c) => _Picker(copy: c, notFound: true),
  ),
  (
    id: 'm08_picker_search',
    title: 'Выбор места — поиск адреса',
    build: (c) =>
        _Picker(copy: c, address: 'площадь Республики, 2', search: 'Зелёный'),
  ),
  (
    id: 'm09_picker_offline',
    title: 'Выбор места — нет связи',
    build: (c) => _Picker(copy: c, offline: true),
  ),
  (
    id: 'm10_picker_end',
    title: 'Выбор места — «Куда» (начинается у «Откуда»)',
    build: (c) => _Picker(
      copy: c,
      kind: DkPlaceKind.end,
      center: Places.bazaar,
      address: 'Зелёный базар',
    ),
  ),
  (
    id: 'm11_day_trips',
    title: 'День — поездки с местами и без',
    build: (c) => _Day(copy: c),
  ),
  (
    id: 'm12_details_ready',
    title: 'Поездка — маршрут построен',
    build: (c) => _Details(copy: c, trip: _t1(c)),
  ),
  (
    id: 'm13_details_straight',
    title: 'Поездка — маршрут по прямой',
    build: (c) => _Details(copy: c, trip: _t1(c), status: _Status.straight),
  ),
  (
    id: 'm14_details_pending',
    title: 'Поездка — маршрут ещё строится',
    build: (c) => _Details(copy: c, trip: _t2(c), status: _Status.pending),
  ),
  (
    id: 'm15_details_no_tiles',
    title: 'Поездка — карта не загрузилась',
    build: (c) => _Details(copy: c, trip: _t2(c), tilesFail: true),
  ),
  (
    id: 'm16_details_loading',
    title: 'Поездка — загрузка',
    build: (c) => _DetailsLoading(copy: c),
  ),
  (
    id: 'm17_details_error',
    title: 'Поездка — ошибка',
    build: (c) => _DetailsError(copy: c),
  ),
  (
    id: 'm18_day_map',
    title: 'Карта дня — водитель, 2 маршрута',
    build: (c) => _DayMap(copy: c, trips: [_t1(c), _t2(c)]),
  ),
  (
    id: 'm19_day_map_admin',
    title: 'Карта дня — администратор, все водители',
    build: (c) => _DayMap(
      copy: c,
      trips: [_t1(c), _t2(c), _u2t1(c), _u2t2(c)],
      caption: c.allDrivers,
    ),
  ),
  (
    id: 'm20_day_map_admin_driver',
    title: 'Карта дня — администратор, Водитель 2',
    build: (c) =>
        _DayMap(copy: c, trips: [_u2t1(c), _u2t2(c)], caption: c.driver2),
  ),
  (
    id: 'm21_day_map_selected',
    title: 'Карта дня — выбран маршрут 2',
    build: (c) => _DayMap(copy: c, trips: [_t1(c), _t2(c)], selected: 1),
  ),
  (
    id: 'm22_kit',
    title: 'Кит — маркеры, поля мест, линии, статистика',
    build: (c) => _Kit(copy: c),
  ),
];

/// App bar + body + bottom bar inside the safe area.
class _Screen extends StatelessWidget {
  const new({required this.body, this.top, this.bottomBar});

  final Widget body;
  final Widget? top;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          ?top,
          Expanded(child: body),
          ?bottomBar,
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------- Add trip

class _AddTrip extends StatelessWidget {
  const new({required this.copy, this.from, this.to, this.error});

  final MapsCopy copy;
  final String? from;
  final String? to;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = copy;
    final spacing = context.dkSpacing;
    return _Screen(
      top: DkModalAppBar(
        title: c.formTitle,
        closeLabel: c.close,
        onClose: () {},
      ),
      body: ListView(
        padding: EdgeInsets.all(spacing.s16),
        children: [
          Row(
            spacing: spacing.s12,
            children: [
              Expanded(
                child: DkTimeField(
                  label: c.start,
                  value: '08:10',
                  emptyValueLabel: '',
                  onTap: () {},
                ),
              ),
              Expanded(
                child: DkTimeField(
                  label: c.end,
                  value: '08:32',
                  emptyValueLabel: '',
                  onTap: () {},
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.s16),
          DkListGroup(
            children: [
              DkPlaceField(
                kind: DkPlaceKind.start,
                label: c.from,
                markerLabel: c.startOfTrip,
                value: from,
                placeholder: c.pickOnMap,
                onTap: () {},
                onClear: () {},
                clearLabel: c.clear,
              ),
              DkPlaceField(
                kind: DkPlaceKind.end,
                label: c.to,
                markerLabel: c.endOfTrip,
                value: to,
                placeholder: c.pickOnMap,
                onTap: () {},
                onClear: () {},
                clearLabel: c.clear,
              ),
            ],
          ),
          if (error case final message?) ...[
            SizedBox(height: spacing.s6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.s4),
              child: DkFieldMessage(text: message, isError: true),
            ),
          ],
          SizedBox(height: spacing.s16),
          DkTextField.money(
            label: c.amount,
            controller: DkMoneyEditingController(amount: 2400),
          ),
          SizedBox(height: spacing.s16),
          DkTextField.money(
            label: c.commission,
            controller: DkMoneyEditingController(amount: 360),
          ),
          SizedBox(height: spacing.s16),
          DkSegmentedControl<DkPaymentMethod>(
            label: c.payment,
            segments: [
              DkSegment(
                value: DkPaymentMethod.cash,
                label: c.cash,
                icon: DkPaymentMethod.cash.icon,
              ),
              DkSegment(
                value: DkPaymentMethod.card,
                label: c.card,
                icon: DkPaymentMethod.card.icon,
              ),
            ],
            selected: DkPaymentMethod.card,
            onChanged: (_) {},
          ),
        ],
      ),
      bottomBar: DkBottomBar(
        child: DkButton(label: c.save, expand: true, onPressed: () {}),
      ),
    );
  }
}

// ------------------------------------------------------------- Place picker

class _Picker extends StatelessWidget {
  const new({
    required this.copy,
    this.kind = DkPlaceKind.start,
    this.center = Places.republic,
    this.address,
    this.resolving = false,
    this.notFound = false,
    this.offline = false,
    this.search,
  });

  final MapsCopy copy;
  final DkPlaceKind kind;
  final LatLng center;
  final String? address;
  final bool resolving;
  final bool notFound;
  final bool offline;
  final String? search;

  @override
  Widget build(BuildContext context) {
    final c = copy;
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final coordinates =
        '${center.latitude.toStringAsFixed(4)}, '
        '${center.longitude.toStringAsFixed(4)}';
    final (line, lineColor) = resolving
        ? (c.resolving, colors.textTertiary)
        : notFound || offline
        ? (coordinates, colors.textPrimary)
        : (address ?? '', colors.textPrimary);
    final query = search;
    return Scaffold(
      body: Column(
        children: [
          // Top panel: close + address search (no visible label).
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
                      label: c.close,
                      onPressed: () {},
                    ),
                    Expanded(
                      child: DkTextField(
                        label: c.searchAddress,
                        showLabel: false,
                        hint: c.searchAddress,
                        prefixIcon: DkIcons.search,
                        controller: TextEditingController(text: query),
                        onClear: () {},
                        clearLabel: c.clear,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: DkMapView(
              tiles: _tiles(offline: offline),
              center: center,
              zoom: 16,
              rounded: false,
              animateTiles: false,
              overlays: [
                Center(
                  child: DkPlaceMarker(
                    kind: kind,
                    semanticsLabel: kind == DkPlaceKind.start
                        ? c.startOfTrip
                        : c.endOfTrip,
                  ),
                ),
                if (query != null)
                  Positioned(
                    left: spacing.s16,
                    right: spacing.s16,
                    top: spacing.s8,
                    child: DkListGroup(
                      children: [
                        for (final result in const [
                          'Зелёный базар',
                          'Зеленый базар, проспект Жибек Жолы, 53',
                          'Зелёный квартал',
                        ])
                          DkListRow(
                            title: result,
                            icon: DkIcons.place,
                            onTap: () {},
                            trailing: const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Bottom panel: the place, then the confirm button.
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
                    DkFitLines([
                      DkLine(
                        kind == DkPlaceKind.start ? c.from : c.to,
                        style: text.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      DkLine(
                        line,
                        style: text.bodyStrong.copyWith(color: lineColor),
                      ),
                      if (notFound)
                        DkLine(
                          c.notFound,
                          style: text.bodyS.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ]),
                    if (offline) ...[
                      SizedBox(height: spacing.s12),
                      DkInfoRow(text: c.offlineMap),
                    ],
                    SizedBox(height: spacing.s16),
                    DkButton(
                      label: c.pickThisPlace,
                      expand: true,
                      onPressed: resolving ? null : () {},
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

// ---------------------------------------------------------------- Day screen

class _Day extends StatelessWidget {
  const new({required this.copy});

  final MapsCopy copy;

  @override
  Widget build(BuildContext context) {
    final c = copy;
    final spacing = context.dkSpacing;
    final trips = [_t1(c), _t2(c), _plain(c)];
    return _Screen(
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: spacing.screenGutter),
        children: [
          DkWordmark(
            title: c.wordmark,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: DkTodayButton(label: c.today, onPressed: () {}),
                ),
                DkIconButton(
                  icon: DkIcons.menu,
                  label: c.menu,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.s8),
          DkDaySwitcher(
            title: c.date,
            subtitle: c.weekday,
            prevLabel: c.prevDay,
            nextLabel: c.nextDayLabel,
            pickLabel: c.pickDate,
            onPrev: () {},
            onNext: () {},
            onPickDate: () {},
          ),
          SizedBox(height: spacing.s16),
          DkSummaryCard(
            netLabel: c.netLabel,
            revenueLabel: c.revenueLabel,
            commissionLabel: c.commission,
            tripsLabel: c.tripsLabel,
            net: 4710,
            revenue: 5800,
            commission: 870,
            tripsCount: 3,
          ),
          SizedBox(height: spacing.s16),
          DkListHeader(
            title: c.trips,
            trailing:
                '${c.tripsCount(3)} · '
                '${c.duration(const Duration(minutes: 62))}',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DkIconButton(
                  icon: DkIcons.map,
                  label: c.dayMap,
                  onPressed: () {},
                ),
                DkIconButton(
                  icon: DkIcons.sort,
                  label: c.sort,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.s8),
          DkTripList(children: [for (final t in trips) _tile(c, t)]),
          SizedBox(height: spacing.s24),
        ],
      ),
    );
  }
}

DkTripTile _tile(MapsCopy c, _Trip t, {String? driver}) => DkTripTile(
  timeRange: DkFormat.timeRange(t.start, t.end),
  endsNextDay: false,
  meta:
      '${c.duration(t.duration)} · '
      '${t.method == DkPaymentMethod.card ? c.card : c.cash}',
  amount: DkMoney.format(t.amount),
  commission: c.commissionLine(DkMoney.format(t.commission)),
  method: t.method,
  nextDayLabel: c.nextDay,
  driver: driver,
  route: t.from == null ? null : '${t.from} → ${t.to}',
  onTap: t.from == null ? null : () {},
);

// -------------------------------------------------------------- Trip details

enum _Status { ready, straight, pending }

class _Details extends StatelessWidget {
  const new({
    required this.copy,
    required this.trip,
    this.status = _Status.ready,
    this.tilesFail = false,
  });

  final MapsCopy copy;
  final _Trip trip;
  final _Status status;
  final bool tilesFail;

  @override
  Widget build(BuildContext context) {
    final c = copy;
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final a = trip.a!;
    final b = trip.b!;
    final road = decodePolyline(trip.route!.polyline);
    final points = switch (status) {
      _Status.ready => road,
      _Status.straight => [a, b],
      _Status.pending => <LatLng>[a, b],
    };
    final metres = switch (status) {
      _Status.ready => trip.route!.metres,
      _Status.straight => const Distance().as(LengthUnit.Meter, a, b).round(),
      _Status.pending => null,
    };
    final perKm = metres == null
        ? null
        : DkFormat.perKilometre(trip.amount, metres);
    return _Screen(
      top: DkModalAppBar(
        title: c.tripTitle,
        leadingIcon: DkIcons.previous,
        closeLabel: c.back,
        onClose: () {},
      ),
      body: ListView(
        padding: EdgeInsets.all(spacing.s16),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: DkMapView(
              tiles: _tiles(offline: tilesFail),
              extraAttribution: status == _Status.ready ? _ors : null,
              fit: points,
              animateTiles: false,
              layers: [
                if (status != _Status.pending)
                  DkRouteLayer(
                    routes: [
                      DkRoute(
                        points: points,
                        straight: status == _Status.straight,
                        connectors: _connectors(points, a, b),
                      ),
                    ],
                  ),
                DkPlaceMarkers(
                  places: [
                    (point: a, kind: DkPlaceKind.start, label: c.startOfTrip),
                    (point: b, kind: DkPlaceKind.end, label: c.endOfTrip),
                  ],
                ),
              ],
            ),
          ),
          if (status == _Status.straight) ...[
            SizedBox(height: spacing.s12),
            DkInfoRow(text: c.straightInfo),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DkButton(
                label: c.rebuild,
                icon: DkIcons.route,
                variant: DkButtonVariant.text,
                onPressed: () {},
              ),
            ),
          ],
          SizedBox(height: spacing.s16),
          DkAmountRow(
            gap: spacing.s12,
            start: DkFitLines([
              DkLine(
                DkFormat.timeRange(trip.start, trip.end),
                ellipsis: false,
                style: text.titleM.copyWith(color: colors.textPrimary),
              ),
              DkLine(
                '${c.duration(trip.duration)} · '
                '${trip.method == DkPaymentMethod.card ? c.card : c.cash}',
                style: text.bodyS.copyWith(color: colors.textSecondary),
              ),
            ]),
            end: DkFitLines(textAlign: TextAlign.end, [
              DkLine(
                DkMoney.format(trip.amount),
                ellipsis: false,
                style: text.moneyM.copyWith(color: colors.textPrimary),
              ),
              DkLine(
                c.commissionLine(DkMoney.format(trip.commission)),
                ellipsis: false,
                style: text.caption.copyWith(color: colors.textTertiary),
              ),
            ]),
          ),
          SizedBox(height: spacing.s16),
          DkRouteStats(
            stats: [
              (label: c.distance, value: metres == null ? '—' : _km(c, metres)),
              (
                label: c.perKm,
                value: perKm == null ? '—' : DkMoney.format(perKm),
              ),
              (
                label: c.perMinute,
                value: DkMoney.format(
                  DkFormat.perMinute(trip.amount, trip.duration)!,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.s16),
          DkListGroup(
            children: [
              DkPlaceField(
                kind: DkPlaceKind.start,
                label: c.from,
                markerLabel: c.startOfTrip,
                value: trip.from,
              ),
              DkPlaceField(
                kind: DkPlaceKind.end,
                label: c.to,
                markerLabel: c.endOfTrip,
                value: trip.to,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailsLoading extends StatelessWidget {
  const new({required this.copy});

  final MapsCopy copy;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return _Screen(
      top: DkModalAppBar(
        title: copy.tripTitle,
        leadingIcon: DkIcons.previous,
        closeLabel: copy.back,
        onClose: () {},
      ),
      body: ListView(
        padding: EdgeInsets.all(spacing.s16),
        children: [
          LayoutBuilder(
            builder: (context, constraints) => DkSkeleton.line(
              width: constraints.maxWidth,
              height: MediaQuery.sizeOf(context).height * 0.45,
              radius: context.dkRadii.lg,
            ),
          ),
          SizedBox(height: spacing.s16),
          const DkSkeleton.line(width: 160, height: 20),
          SizedBox(height: spacing.s8),
          const DkSkeleton.line(width: 120, height: 14),
          SizedBox(height: spacing.s16),
          const DkSkeleton.summaryCard(),
        ],
      ),
    );
  }
}

class _DetailsError extends StatelessWidget {
  const new({required this.copy});

  final MapsCopy copy;

  @override
  Widget build(BuildContext context) => _Screen(
    top: DkModalAppBar(
      title: copy.tripTitle,
      leadingIcon: DkIcons.previous,
      closeLabel: copy.back,
      onClose: () {},
    ),
    body: Center(
      child: DkErrorState(
        title: copy.loadFailed,
        message: copy.loadFailedMessage,
        retryLabel: copy.retry,
        onRetry: () {},
      ),
    ),
  );
}

// ------------------------------------------------------------------- Day map

class _DayMap extends StatelessWidget {
  const new({
    required this.copy,
    required this.trips,
    this.caption,
    this.selected,
  });

  final MapsCopy copy;

  /// In time order: numbered 1, 2, … as on the map.
  final List<_Trip> trips;
  final String? caption;

  /// The selected trip's index (its route over the others, the map fitted
  /// to it).
  final int? selected;

  @override
  Widget build(BuildContext context) {
    final c = copy;
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final routes = [
      for (final (i, t) in trips.indexed)
        DkRoute(
          points: decodePolyline(t.route!.polyline),
          id: i,
          connectors: _connectors(
            decodePolyline(t.route!.polyline),
            t.a!,
            t.b!,
          ),
        ),
    ];
    final shown = selected == null ? routes : [routes[selected!]];
    return _Screen(
      top: DkModalAppBar(
        title: c.dayMap,
        leadingIcon: DkIcons.previous,
        closeLabel: c.back,
        onClose: () {},
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DkMapView(
              tiles: _tiles(),
              extraAttribution: _ors,
              fit: [for (final r in shown) ...r.points],
              rounded: false,
              animateTiles: false,
              layers: [
                DkRouteLayer(routes: routes, selected: selected, onTap: (_) {}),
                DkPlaceMarkers(markers: _markers(c)),
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
              // The legend is the day's trips, numbered as on the map
              // (DESIGN.md §9.5): a row selects its route, its button opens
              // the trip.
              child: Padding(
                padding: EdgeInsets.only(top: spacing.s16, bottom: spacing.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: spacing.s16),
                      child: DkFitLines([
                        DkLine(
                          c.routes(trips.length),
                          style: text.titleM.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        DkLine(
                          caption == null ? c.date : '$caption · ${c.date}',
                          style: text.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ]),
                    ),
                    SizedBox(height: spacing.s8),
                    for (final (i, t) in trips.indexed)
                      DkListRow(
                        leading: DkPlaceMarker(
                          kind: DkPlaceKind.start,
                          number: i + 1,
                          semanticsLabel: '',
                        ),
                        semanticsLabel: c.routeOf(i + 1, trips.length),
                        title:
                            '${DkFormat.timeRange(t.start, t.end)} · '
                            '${DkMoney.format(t.amount)}',
                        subtitle: '${t.from} → ${t.to}',
                        selected: i == selected,
                        onTap: () {},
                        trailingIsAction: true,
                        trailing: DkIconButton(
                          icon: DkIcons.next,
                          label: c.openTrip,
                          onPressed: () {},
                        ),
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

  /// Numbered starts; an end dot unless the next trip starts within 50 m
  /// (one marker there: the next trip's number).
  List<({LatLng point, DkPlaceMarker marker})> _markers(MapsCopy c) {
    const distance = Distance();
    final dots = <({LatLng point, DkPlaceMarker marker})>[];
    final numbers = <({LatLng point, DkPlaceMarker marker})>[];
    for (final (i, t) in trips.indexed) {
      numbers.add((
        point: t.a!,
        marker: DkPlaceMarker(
          kind: DkPlaceKind.start,
          number: i + 1,
          semanticsLabel: c.startOfTrip,
        ),
      ));
      final next = i + 1 < trips.length ? trips[i + 1].a : null;
      if (next == null || distance.as(LengthUnit.Meter, t.b!, next) > 50) {
        dots.add((
          point: t.b!,
          marker: DkPlaceMarker.dot(semanticsLabel: c.endOfTrip),
        ));
      }
    }
    return [...dots, ...numbers];
  }
}

/// A dashed connector from a place to its line's end where they are more
/// than 30 m apart (the routing engine snaps places to a road; DESIGN.md
/// §9.1).
List<List<LatLng>> _connectors(List<LatLng> line, LatLng a, LatLng b) {
  const distance = Distance();
  bool far(LatLng x, LatLng y) => distance.as(LengthUnit.Meter, x, y) > 30;
  return [
    if (far(a, line.first)) [a, line.first],
    if (far(line.last, b)) [line.last, b],
  ];
}

// ----------------------------------------------------------------------- Kit

class _Kit extends StatelessWidget {
  const new({required this.copy});

  final MapsCopy copy;

  @override
  Widget build(BuildContext context) {
    final c = copy;
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final road = decodePolyline(bazaarToEsentai.polyline);
    Widget caption(String s) => Padding(
      padding: EdgeInsets.only(top: spacing.s16, bottom: spacing.s8),
      child: Text(
        s,
        style: text.captionStrong.copyWith(color: colors.textTertiary),
      ),
    );
    return _Screen(
      body: ListView(
        padding: EdgeInsets.all(spacing.s16),
        children: [
          caption('DkPlaceMarker · DkRouteLayer (ready / straight)'),
          SizedBox(
            height: 260,
            child: DkMapView(
              tiles: _tiles(),
              extraAttribution: _ors,
              fit: [...road, Places.republic],
              animateTiles: false,
              layers: [
                DkRouteLayer(
                  routes: [
                    DkRoute(points: road),
                    const DkRoute(
                      points: [Places.esentai, Places.republic],
                      straight: true,
                    ),
                  ],
                ),
                DkPlaceMarkers(
                  places: [
                    (
                      point: Places.bazaar,
                      kind: DkPlaceKind.start,
                      label: c.startOfTrip,
                    ),
                    (
                      point: Places.republic,
                      kind: DkPlaceKind.end,
                      label: c.endOfTrip,
                    ),
                  ],
                ),
              ],
            ),
          ),
          caption('DkPlaceField'),
          DkListGroup(
            children: [
              DkPlaceField(
                kind: DkPlaceKind.start,
                label: c.from,
                markerLabel: c.startOfTrip,
                placeholder: c.pickOnMap,
                onTap: () {},
                onClear: () {},
                clearLabel: c.clear,
              ),
              DkPlaceField(
                kind: DkPlaceKind.end,
                label: c.to,
                markerLabel: c.endOfTrip,
                value: 'улица Розыбакиева, 247А (ТРЦ MEGA Alma-Ata, вход 3)',
                placeholder: c.pickOnMap,
                onTap: () {},
                onClear: () {},
                clearLabel: c.clear,
              ),
              DkPlaceField(
                kind: DkPlaceKind.end,
                label: c.to,
                markerLabel: c.endOfTrip,
                value: 'Аэропорт Алматы',
              ),
            ],
          ),
          caption('DkRouteStats'),
          DkRouteStats(
            stats: [
              (label: c.distance, value: _km(c, 7429)),
              (
                label: c.perKm,
                value: DkMoney.format(DkFormat.perKilometre(2400, 7429)!),
              ),
              (
                label: c.perMinute,
                value: DkMoney.format(
                  DkFormat.perMinute(2400, const Duration(minutes: 22))!,
                ),
              ),
            ],
          ),
          caption('DkFormat.distance'),
          Text(
            [850, 999, 1000, 7429, 25641].map((m) => _km(c, m)).join('   '),
            style: text.body.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// The «Карты» tab of the showcase: every state, in Russian or Kazakh.
class MapsPreviewList extends StatefulWidget {
  /// Creates the list.
  const new({super.key});

  @override
  State<MapsPreviewList> createState() => _MapsPreviewListState();
}

class _MapsPreviewListState extends State<MapsPreviewList> {
  MapsCopy _copy = ruCopy;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(context.dkSpacing.screenGutter),
    children: [
      DkLanguageSwitch(
        languages: const [
          (code: 'ru', name: 'Русский'),
          (code: 'kk', name: 'Қазақша'),
        ],
        selected: _copy.code,
        onChanged: (code) =>
            setState(() => _copy = code == 'kk' ? kkCopy : ruCopy),
      ),
      SizedBox(height: context.dkSpacing.s16),
      DkListGroup(
        children: [
          for (final preview in mapsPreviews)
            DkListRow(
              title: preview.title,
              subtitle: preview.id,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => preview.build(_copy)),
              ),
            ),
        ],
      ),
    ],
  );
}
