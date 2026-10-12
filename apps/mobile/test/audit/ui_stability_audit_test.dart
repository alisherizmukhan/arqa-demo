// UI stability audit (docs/UI_STABILITY_AUDIT.md). Not part of the normal
// run: it only measures, and it runs when AUDIT_DIR is set:
//
//   AUDIT_DIR=build/audit flutter test test/audit/ui_stability_audit_test.dart
//
// 1. Screens: every scenario × ru/kk × 360×780 / 390×844 × text 1.0 / 1.15 /
//    1.3. Each interactive control is measured: its fixed-size body box (the
//    box DESIGN.md gives a height) against the designed height, and every
//    label inside the body: wraps (more than one line), cut (ellipsis or
//    clipped at maxLines) or overflows the body. One JSON object per control
//    in `screens.jsonl`.
// 2. Probes: each kit control alone in a 328-wide column with a short label
//    and a long one (3× the longest real label) — whether its size depends on
//    the label. `probes.jsonl`.
// 3. AUDIT_SHOTS="id|locale|width|scale,…" also saves those screens as PNG.
//
// CI runs it as a guard (DESIGN.md §10): AUDIT_STRICT=1 fails on any control
// off its designed height, a wrapped label, a cut amount, a cut label at ×1.0,
// a cut action button or tab at ×1.15, a layout error, or a probe whose size
// depends on its label (the decision pair excepted: it stacks by design).
// AUDIT_CHEAP=1 measures the 360-wide phone only.
@Tags(['audit'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/account_scenarios.dart';
import '../helpers/app_harness.dart';
import '../helpers/control_metrics.dart';
import '../helpers/scenarios.dart';

final String? _dir = Platform.environment['AUDIT_DIR'];
final Set<String> _shots = {
  ...?Platform.environment['AUDIT_SHOTS']
      ?.split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty),
};

final bool _strict = Platform.environment['AUDIT_STRICT'] == '1';
final bool _cheap = Platform.environment['AUDIT_CHEAP'] == '1';

final List<Size> _sizes = [
  const Size(360, 780),
  if (!_cheap) const Size(390, 844),
];
const _scales = [1.0, 1.15, 1.3];

void main() {
  setUpAll(loadAppFonts);

  group('screens', () {
    for (final locale in ['ru', 'kk']) {
      for (final scenario in [
        ...scenarios,
        ...stressScenarios,
        ...behaviourScenarios,
        ...accountScenarios,
      ]) {
        for (final size in _sizes) {
          for (final scale in _scales) {
            final key = '${scenario.id}|$locale|${size.width.toInt()}|$scale';
            testWidgets(key, skip: _dir == null, (tester) async {
              scenarioLocale = locale;
              addTearDown(() => scenarioLocale = 'ru');
              useDevice(tester, (
                size: size,
                textScale: scale,
                brightness: Brightness.light,
                pixelRatio: _shots.contains(key) ? 2 : 1,
              ));
              final errors = <String>[];
              final previous = FlutterError.onError;
              FlutterError.onError = (d) => errors.add(d.exceptionAsString());
              try {
                await scenario.run(tester);
              } finally {
                FlutterError.onError = previous;
              }
              final records = measureControls(tester).map(
                (r) => {
                  'scenario': scenario.id,
                  'locale': locale,
                  'width': size.width.toInt(),
                  'scale': scale,
                  ...r,
                },
              );
              _append('screens.jsonl', records);
              _append('errors.jsonl', [
                for (final e in errors)
                  {
                    'scenario': scenario.id,
                    'locale': locale,
                    'width': size.width.toInt(),
                    'scale': scale,
                    'error': e.split('\n').first,
                  },
              ]);
              if (_shots.contains(key)) await _shot(tester, key);
              if (_strict) {
                expect(errors, isEmpty, reason: key);
                for (final r in records) {
                  _expectStable(r, scale, key);
                }
              }
              await disposeApp(tester);
            });
          }
        }
      }
    }
  });

  group('probes', () {
    for (final locale in ['ru', 'kk']) {
      for (final scale in _scales) {
        for (final probe in _probes) {
          testWidgets('${probe.name}|$locale|$scale', skip: _dir == null, (
            tester,
          ) async {
            final l10n = lookupAppLocalizations(Locale(locale));
            final sizes = <String, Size>{};
            final notes = <String, Map<String, Object?>>{};
            for (final (kind, label) in [
              ('short', probe.short(l10n)),
              ('long', probe.long(l10n)),
            ]) {
              useDevice(tester, (
                size: const Size(360, 780),
                textScale: scale,
                brightness: Brightness.light,
                pixelRatio: 1,
              ));
              final errors = <String>[];
              final previous = FlutterError.onError;
              FlutterError.onError = (d) => errors.add(d.exceptionAsString());
              await tester.pumpWidget(
                MaterialApp(
                  theme: DkTheme.light(),
                  home: Scaffold(
                    body: Center(
                      child: SizedBox(
                        width: 328,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            KeyedSubtree(
                              key: const ValueKey('probe'),
                              child: probe.build(label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pump();
              FlutterError.onError = previous;
              final box = tester.renderObject<RenderBox>(
                find.byKey(const ValueKey('probe')),
              );
              sizes[kind] = box.size;
              final texts = paragraphsOf(box);
              notes[kind] = {
                'size': [box.size.width, box.size.height],
                'maxLines': texts.fold<int>(0, (m, t) => t.$2 > m ? t.$2 : m),
                'cut': texts.any((t) => t.$3),
                'overflowErrors': errors.length,
              };
            }
            _append('probes.jsonl', [
              {
                'control': probe.name,
                'locale': locale,
                'scale': scale,
                'designedHeight': probe.designedHeight,
                'short': notes['short'],
                'long': notes['long'],
                'sizeDependsOnLabel': sizes['short'] != sizes['long'],
              },
            ]);
            if (_strict) {
              for (final note in notes.values) {
                expect(note['overflowErrors'], 0, reason: probe.name);
                expect(note['maxLines'], lessThanOrEqualTo(1));
              }
              if (!probe.name.contains('decision row')) {
                expect(sizes['long'], sizes['short'], reason: probe.name);
              }
            }
          });
        }
      }
    }
  });
}

/// DESIGN.md §10 on one measured control (strict mode).
void _expectStable(Map<String, Object?> r, double scale, String key) {
  final control = r['control']! as String;
  final what = '$control (${r['place']}) ${r['labels']} at $key';
  if (control == 'money text') {
    expect(r['cut'], isFalse, reason: 'amount cut: $what');
    return;
  }
  expect(r['bodyFound'], isTrue, reason: 'no fixed body: $what');
  final height = r['bodyHeight']! as double;
  expect(height, closeTo(r['designedHeight']! as double, 0.5), reason: what);
  expect(r['maxLines'], lessThanOrEqualTo(1), reason: 'wraps: $what');
  if (r['cut'] != true) return;
  final action =
      control.startsWith('DkButton') ||
      control == 'DkFab' ||
      control == 'DkSegmentedControl';
  expect(scale > (action ? 1.15 : 1.0), isTrue, reason: 'cut: $what');
}

void _append(String file, Iterable<Map<String, Object?>> records) {
  final dir = _dir;
  if (dir == null) return;
  File('$dir/$file')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      records.map((r) => '${jsonEncode(r)}\n').join(),
      mode: FileMode.append,
    );
}

Future<void> _shot(WidgetTester tester, String key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(shotKey),
  );
  final png = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  File('$_dir/shots/${key.replaceAll('|', '_')}.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!);
}

typedef _Probe = ({
  String name,
  double designedHeight,
  String Function(AppLocalizations) short,
  String Function(AppLocalizations) long,
  Widget Function(String label) build,
});

String _x3(String s) => '$s $s $s';

final List<_Probe> _probes = [
  for (final variant in DkButtonVariant.values)
    (
      name: 'DkButton.${variant.name} (full width)',
      designedHeight: variant == DkButtonVariant.text ? 48.0 : 56.0,
      short: (l) => l.save,
      long: (l) => _x3(l.conflictNew),
      build: (label) => DkButton(
        label: label,
        variant: variant,
        expand: true,
        onPressed: () {},
      ),
    ),
  (
    name: 'DkButton.compact (decision row)',
    designedHeight: 48,
    short: (l) => l.approve,
    long: (l) => _x3(l.reject),
    build: (label) => DkDecisionButtons(
      rejectLabel: label,
      approveLabel: label,
      onReject: () {},
      onApprove: () {},
    ),
  ),
  (
    name: 'DkButton.text (inline «Всё»)',
    designedHeight: 48,
    short: (l) => l.all,
    long: (l) => _x3(l.all),
    build: (label) => Row(
      children: [
        DkButton(label: label, variant: DkButtonVariant.text, onPressed: () {}),
      ],
    ),
  ),
  (
    name: 'DkFab',
    designedHeight: 56,
    short: (l) => l.addTripFab,
    long: (l) => _x3(l.emptyAction),
    build: (label) => Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: DkFab(label: label, icon: DkIcons.add, onPressed: () {}),
        ),
      ],
    ),
  ),
  (
    name: 'DkSegmentedControl (3 tabs)',
    designedHeight: 56,
    short: (l) => l.tabTrips,
    long: (l) => _x3(l.tabDrivers),
    build: (label) => DkSegmentedControl<int>(
      segments: [
        DkSegment(value: 0, label: label),
        DkSegment(value: 1, label: label),
        DkSegment(value: 2, label: label),
      ],
      selected: 0,
      onChanged: (_) {},
    ),
  ),
  (
    name: 'DkLanguageSwitch',
    designedHeight: 56,
    short: (l) => l.languageRu,
    long: (l) => _x3(l.languageKk),
    build: (label) => DkLanguageSwitch(
      languages: [(code: 'ru', name: label), (code: 'kk', name: label)],
      selected: 'ru',
      onChanged: (_) {},
    ),
  ),
  (
    name: 'DkFilterChips',
    designedHeight: 48,
    short: (l) => l.filterAll,
    long: (l) => _x3(l.allDrivers),
    build: (label) => DkFilterChips<int>(
      options: [(value: 0, label: label), (value: 1, label: label)],
      selected: 0,
      onChanged: (_) {},
    ),
  ),
  (
    name: 'DkBadge',
    designedHeight: 24,
    short: (l) => l.nextDayBadge,
    long: (l) => _x3(l.nextDayLabel),
    build: (label) => Row(children: [Flexible(child: DkBadge(label))]),
  ),
  (
    name: 'DkStatusChip',
    designedHeight: 24,
    short: (l) => l.statusPaid,
    long: (l) => _x3(l.statusRejected),
    build: (label) => Row(
      children: [
        Flexible(
          child: DkStatusChip(kind: DkStatusKind.rejected, label: label),
        ),
      ],
    ),
  ),
  (
    name: 'DkTodayButton',
    designedHeight: 48,
    short: (l) => l.today,
    long: (l) => _x3(l.today),
    build: (label) => Row(
      children: [
        Flexible(
          child: DkTodayButton(label: label, onPressed: () {}),
        ),
      ],
    ),
  ),
  (
    name: 'DkListRow',
    designedHeight: 56,
    short: (l) => l.language,
    long: (l) => _x3(l.revokeSessions),
    build: (label) => DkListGroup(
      children: [DkListRow(icon: DkIcons.user, title: label, onTap: () {})],
    ),
  ),
  (
    name: 'DkDaySwitcher',
    designedHeight: 56,
    short: (l) => l.today,
    long: (l) => _x3(l.date(DateTime(2026, 9, 30))),
    build: (label) => DkDaySwitcher(
      title: label,
      subtitle: label,
      prevLabel: 'p',
      nextLabel: 'n',
      pickLabel: 'd',
      onPrev: () {},
      onPickDate: () {},
    ),
  ),
  (
    name: 'DkTextField (label + helper)',
    designedHeight: 56,
    short: (l) => l.amount,
    long: (l) => _x3(l.withdrawAmount),
    build: (label) => _Field(label: label),
  ),
  (
    name: 'DkTimeField',
    designedHeight: 56,
    short: (l) => l.start,
    long: (l) => _x3(l.endPickerHelp),
    build: (label) => DkTimeField(
      label: label,
      value: '08:10',
      emptyValueLabel: '-',
      trailing: DkBadge(label),
      onTap: () {},
    ),
  ),
  (
    name: 'DkDialogView buttons',
    designedHeight: 56,
    short: (l) => l.ok,
    long: (l) => _x3(l.conflictNew),
    build: (label) => SizedBox(
      height: 700,
      child: DkDialogView(
        icon: DkIcons.alert,
        title: 't',
        message: 'm',
        primaryLabel: label,
        onPrimary: () {},
        secondaryLabel: label,
        onSecondary: () {},
        popOnAction: false,
      ),
    ),
  ),
  (
    name: 'DkSnackbarView action',
    designedHeight: 56,
    short: (l) => l.retry,
    long: (l) => _x3(l.retry),
    build: (label) => DkSnackbarView(
      message: 'm',
      tone: DkSnackTone.error,
      actionLabel: label,
      onAction: () {},
    ),
  ),
];

class _Field extends StatefulWidget {
  const new({required this.label});

  final String label;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  final _controller = TextEditingController(text: '1000');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DkTextField(
    label: widget.label,
    controller: _controller,
    trailing: DkButton(
      label: widget.label,
      variant: DkButtonVariant.text,
      onPressed: () {},
    ),
  );
}
