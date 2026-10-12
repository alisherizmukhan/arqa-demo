// DESIGN.md §9: the map components — tokens in use, sizes, states,
// semantics, the dark tiles, and the distance formatting. No network: tiles
// come from DkSketchTileProvider.

import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

const _a = LatLng(43.26275, 76.95519);
const _b = LatLng(43.2185, 76.928);

DkMapTiles _tiles({String? darkUrl}) => DkMapTiles(
  lightUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  darkUrl: darkUrl,
  attribution: '© OpenStreetMap contributors',
  userAgentPackageName: 'kz.driverdiary.test',
  provider: DkSketchTileProvider(),
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Size size = const Size(390, 844),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light ? DkTheme.light() : DkTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('DkFormat (DESIGN.md §9.6)', () {
    String km(int m) =>
        DkFormat.distance(m, metresUnit: 'м', kilometresUnit: 'км');

    test('metres under 1 000, then km with one decimal and a comma', () {
      expect(km(0), '0 м');
      expect(km(850), '850 м');
      expect(km(999), '999 м');
      expect(km(1000), '1,0 км');
      expect(km(1049), '1,0 км');
      expect(km(1050), '1,1 км');
      expect(km(7429), '7,4 км');
      expect(km(25641), '25,6 км');
    });

    test('tenge per km is a whole number; none without a distance', () {
      expect(DkFormat.perKilometre(2400, 7429), 323);
      expect(DkFormat.perKilometre(2400, 7203), 333);
      expect(DkFormat.perKilometre(1500, 850), 1765);
      expect(DkFormat.perKilometre(2400, 0), isNull);
    });
  });

  group('DkPlaceMarker', () {
    testWidgets('A is markerA with a surface letter, B is markerB', (
      tester,
    ) async {
      await _pump(
        tester,
        const Row(
          children: [
            DkPlaceMarker(kind: DkPlaceKind.start, semanticsLabel: 'Начало'),
            DkPlaceMarker(kind: DkPlaceKind.end, semanticsLabel: 'Конец'),
          ],
        ),
      );
      const colors = DkColors.light;
      final boxes = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(DkPlaceMarker),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((b) => b.decoration as BoxDecoration)
          .toList();
      expect(boxes.map((d) => d.color), [colors.markerA, colors.markerB]);
      expect(
        boxes.map((d) => (d.border! as Border).top.color),
        everyElement(colors.markerRing),
      );
      final letters = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(DkPlaceMarker),
          matching: find.byType(Text),
        ),
      );
      expect(letters.map((t) => t.data), ['A', 'B']);
      expect(letters.map((t) => t.style!.color), [
        colors.surface,
        colors.onAccent,
      ]);
      expect(find.bySemanticsLabel('Начало'), findsOneWidget);
      expect(find.bySemanticsLabel('Конец'), findsOneWidget);
    });

    testWidgets('stays 32 dp at text scale 1.3', (tester) async {
      await _pump(
        tester,
        const Center(
          child: DkPlaceMarker(kind: DkPlaceKind.start, semanticsLabel: 'A'),
        ),
        textScale: 1.3,
      );
      expect(tester.getSize(find.byType(DkPlaceMarker)), const Size(32, 32));
    });
  });

  group('DkPlaceField', () {
    Widget field({String? value, bool editable = true, String? clear}) =>
        DkListGroup(
          children: [
            DkPlaceField(
              kind: DkPlaceKind.start,
              label: 'Откуда',
              markerLabel: 'Начало поездки',
              value: value,
              placeholder: 'Выбрать на карте',
              onTap: editable ? () {} : null,
              onClear: editable && clear != null ? () {} : null,
              clearLabel: clear,
            ),
          ],
        );

    testWidgets('empty: the placeholder and a chevron', (tester) async {
      await _pump(tester, field(clear: 'Очистить'));
      expect(find.text('Выбрать на карте'), findsOneWidget);
      expect(find.byIcon(DkIcons.next), findsOneWidget);
      expect(find.bySemanticsLabel('Очистить'), findsNothing);
    });

    testWidgets('set: the address and a clear button instead of the chevron', (
      tester,
    ) async {
      await _pump(tester, field(value: 'Зелёный базар', clear: 'Очистить'));
      expect(find.text('Зелёный базар'), findsOneWidget);
      expect(find.text('Выбрать на карте'), findsNothing);
      expect(find.byIcon(DkIcons.close), findsOneWidget);
      expect(find.byIcon(DkIcons.next), findsNothing);
    });

    testWidgets('read-only: neither chevron nor clear button', (tester) async {
      await _pump(tester, field(value: 'Зелёный базар', editable: false));
      expect(find.byIcon(DkIcons.next), findsNothing);
      expect(find.byIcon(DkIcons.close), findsNothing);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('64 high with a long address at text x$scale', (
        tester,
      ) async {
        await _pump(
          tester,
          field(value: 'улица Розыбакиева, 247А ' * 4, clear: 'Очистить'),
          textScale: scale,
          size: const Size(360, 780),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(DkPlaceField)).height,
          dkPlaceFieldHeight,
        );
      });
    }

    testWidgets('taps reach onTap and onClear', (tester) async {
      var taps = 0;
      var clears = 0;
      await _pump(
        tester,
        DkPlaceField(
          kind: DkPlaceKind.end,
          label: 'Куда',
          markerLabel: 'Конец поездки',
          value: 'ТРЦ Есентай Молл',
          onTap: () => taps++,
          onClear: () => clears++,
          clearLabel: 'Очистить',
        ),
      );
      await tester.tap(find.text('ТРЦ Есентай Молл'));
      await tester.tap(find.byIcon(DkIcons.close));
      expect((taps, clears), (1, 1));
    });
  });

  group('DkMapView', () {
    Widget map({String? darkUrl}) => SizedBox(
      height: 300,
      child: DkMapView(
        tiles: _tiles(darkUrl: darkUrl),
        fit: const [_a, _b],
        animateTiles: false,
        layers: const [
          DkRouteLayer(
            routes: [
              DkRoute(points: [_a, _b]),
              DkRoute(points: [_b, _a], straight: true),
            ],
          ),
          DkPlaceMarkers(
            places: [
              (point: _a, kind: DkPlaceKind.start, label: 'Начало поездки'),
              (point: _b, kind: DkPlaceKind.end, label: 'Конец поездки'),
            ],
          ),
        ],
      ),
    );

    testWidgets('the attribution is visible; rotation is off', (tester) async {
      await _pump(tester, map());
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      final options = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .options;
      expect(
        InteractiveFlag.hasRotate(options.interactionOptions.flags),
        isFalse,
      );
      expect(options.backgroundColor, DkColors.light.surfaceMuted);
      // Both markers are drawn. (flutter_map's moving layer does not expose
      // their semantics; the place fields under the map carry the names.)
      expect(find.byType(DkPlaceMarker), findsNWidgets(2));
    });

    testWidgets('dark theme darkens light tiles', (tester) async {
      await _pump(tester, map(), brightness: Brightness.dark);
      final layer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(layer.tileBuilder, isNotNull);
      expect(layer.urlTemplate, contains('openstreetmap'));
    });

    testWidgets('a real dark style is shown as it is', (tester) async {
      await _pump(
        tester,
        map(darkUrl: 'https://tiles.example/dark/{z}/{x}/{y}.png'),
        brightness: Brightness.dark,
      );
      final layer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(layer.tileBuilder, isNull);
      expect(layer.urlTemplate, contains('/dark/'));
    });

    testWidgets('light theme: no filter', (tester) async {
      await _pump(tester, map());
      expect(
        tester.widget<TileLayer>(find.byType(TileLayer)).tileBuilder,
        isNull,
      );
    });

    testWidgets('routes: routeLine over routeCasing, 5 + 2 × 1.5 dp; '
        'straight is dashed', (tester) async {
      await _pump(tester, map(), brightness: Brightness.dark);
      final lines = tester
          .widget<PolylineLayer<Object>>(find.byType(PolylineLayer<Object>))
          .polylines;
      expect(lines.map((l) => l.color), everyElement(DkColors.dark.routeLine));
      expect(
        lines.map((l) => l.borderColor),
        everyElement(DkColors.dark.routeCasing),
      );
      expect(lines.map((l) => l.strokeWidth + 2 * l.borderStrokeWidth), [8, 8]);
      expect(lines.first.pattern, const StrokePattern.solid());
      expect(lines.last.pattern, isNot(const StrokePattern.solid()));
    });

    testWidgets('a map whose tiles never load still shows the attribution', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          height: 300,
          child: DkMapView(
            tiles: DkMapTiles(
              lightUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              attribution: '© OpenStreetMap contributors',
              userAgentPackageName: 'kz.driverdiary.test',
              provider: DkSketchTileProvider(offline: true),
            ),
            center: _a,
            animateTiles: false,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    });
  });

  testWidgets('DkRouteStats: three tiles in a card', (tester) async {
    await _pump(
      tester,
      const DkRouteStats(
        stats: [
          (label: 'Расстояние', value: '7,4 км'),
          (label: 'В пути', value: '22 мин'),
          (label: 'За км', value: '323 ₸'),
        ],
      ),
    );
    expect(find.byType(DkSummaryTile), findsNWidgets(3));
    expect(find.text('Расстояние'), findsOneWidget);
  });

  group('DkTripTile with places', () {
    Widget tile({VoidCallback? onTap, String? route}) => DkTripList(
      children: [
        DkTripTile(
          timeRange: '08:10 – 08:32',
          endsNextDay: false,
          meta: '22 мин · Карта',
          amount: '2 400 ₸',
          commission: 'комиссия 360 ₸',
          method: DkPaymentMethod.card,
          nextDayLabel: 'следующий день',
          route: route,
          onTap: onTap,
        ),
      ],
    );

    testWidgets('tappable with a chevron and the route line', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        tile(onTap: () => taps++, route: 'Зелёный базар → ТРЦ Есентай Молл'),
      );
      expect(find.byIcon(DkIcons.next), findsOneWidget);
      expect(find.text('Зелёный базар → ТРЦ Есентай Молл'), findsOneWidget);
      await tester.tap(find.byType(DkTripTile));
      expect(taps, 1);
    });

    testWidgets('without places: no chevron, no route line', (tester) async {
      await _pump(tester, tile());
      expect(find.byIcon(DkIcons.next), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('DkTextField search variant', () {
    testWidgets('showLabel: false keeps the label as the accessible name', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        DkTextField(
          label: 'Поиск адреса',
          hint: 'Поиск адреса',
          showLabel: false,
          prefixIcon: DkIcons.search,
          controller: TextEditingController(),
        ),
      );
      // Only the placeholder is drawn; the name is still there.
      expect(find.text('Поиск адреса'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(DkTextField)).label,
        contains('Поиск адреса'),
      );
      semantics.dispose();
    });

    testWidgets('the clear button shows only with text and keeps its width', (
      tester,
    ) async {
      final controller = TextEditingController();
      var cleared = 0;
      await _pump(
        tester,
        DkTextField(
          label: 'Поиск адреса',
          showLabel: false,
          controller: controller,
          onClear: () => cleared++,
          clearLabel: 'Очистить',
        ),
      );
      expect(find.byIcon(DkIcons.close), findsNothing);

      controller.text = 'Зелёный';
      await tester.pump();
      expect(find.byIcon(DkIcons.close), findsOneWidget);
      // The input keeps the row: the button is 48, not half the field.
      final input = tester.getSize(find.byType(TextField)).width;
      final field = tester.getSize(find.byType(DkTextField)).width;
      expect(input, greaterThan(field - 48 - 40));

      await tester.tap(find.byIcon(DkIcons.close));
      expect(cleared, 1);
    });
  });
}
