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
import '../helpers/scenarios.dart';

final String? _dir = Platform.environment['AUDIT_DIR'];
final Set<String> _shots = {
  ...?Platform.environment['AUDIT_SHOTS']
      ?.split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty),
};

const _sizes = [Size(360, 780), Size(390, 844)];
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
              final texts = _paragraphs(box);
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
          });
        }
      }
    }
  });
}

/// Controls measured on screens: widget type → (name, designed body height).
({String name, double? height})? _control(Widget w) => switch (w) {
  DkButton(variant: DkButtonVariant.text) => (
    name: 'DkButton.text',
    height: 48,
  ),
  DkButton(compact: true) => (name: 'DkButton.compact', height: 48),
  DkButton(variant: final v) => (name: 'DkButton.${v.name}', height: 56),
  DkFab() => (name: 'DkFab', height: 56),
  DkLanguageSwitch() => (name: 'DkLanguageSwitch', height: 56),
  DkSegmentedControl() => (name: 'DkSegmentedControl', height: 56),
  DkFilterChips() => (name: 'DkFilterChips', height: 40),
  DkBadge() => (name: 'DkBadge', height: 24),
  DkStatusChip() => (name: 'DkStatusChip', height: 24),
  DkIconButton() => (name: 'DkIconButton', height: 48),
  DkTodayButton() => (name: 'DkTodayButton', height: 48),
  DkDaySwitcher() => (name: 'DkDaySwitcher', height: 56),
  DkTextField() => (name: 'DkTextField', height: 56),
  DkTimeField() => (name: 'DkTimeField', height: 56),
  DkListRow() => (name: 'DkListRow', height: 56),
  _ => null,
};

/// Where a button sits (its context changes what is acceptable).
String _place(Element element) {
  var place = 'screen';
  element.visitAncestorElements((a) {
    final w = a.widget;
    final found = switch (w) {
      DkDialogView() => 'dialog',
      DkSnackbarView() => 'snackbar',
      DkEmptyState() || DkErrorState() => 'state',
      DkBottomBar() => 'bottom bar',
      DkDecisionButtons() => 'decision row',
      DkTextField() => 'field trailing',
      DkModalAppBar() || DkWordmark() => 'header',
      _ => null,
    };
    if (found != null) {
      place = found;
      return false;
    }
    return true;
  });
  return place;
}

List<Map<String, Object?>> measureControls(WidgetTester tester) {
  final out = <Map<String, Object?>>[...measureMoney(tester)];
  for (final element
      in find.byWidgetPredicate((w) => _control(w) != null).evaluate()) {
    final control = _control(element.widget)!;
    // The segmented control inside the language switch is the switch.
    if (control.name == 'DkSegmentedControl' &&
        element.findAncestorWidgetOfExactType<DkLanguageSwitch>() != null) {
      continue;
    }
    final root = element.renderObject;
    if (root is! RenderBox || !root.attached || !root.hasSize) continue;
    final bodies = _bodies(root, control.height);
    for (final body in bodies.isEmpty ? [root] : bodies) {
      final texts = _paragraphs(body);
      final bodyRect = _globalRect(body);
      out.add({
        'control': control.name,
        'place': _place(element),
        'designedHeight': control.height,
        'bodyFound': bodies.isNotEmpty,
        'bodyHeight': _round(body.size.height),
        'bodyWidth': _round(body.size.width),
        'outer': [_round(root.size.width), _round(root.size.height)],
        'labels': [for (final t in texts) t.$1],
        'maxLines': texts.fold<int>(0, (m, t) => t.$2 > m ? t.$2 : m),
        'cut': texts.any((t) => t.$3),
        'overflows': texts.any(
          (t) =>
              t.$4.left < bodyRect.left - 0.5 ||
              t.$4.right > bodyRect.right + 0.5 ||
              t.$4.top < bodyRect.top - 0.5 ||
              t.$4.bottom > bodyRect.bottom + 0.5,
        ),
      });
    }
  }
  return out;
}

/// Amounts (any text with «₸») that wrap or are cut, with the nearest kit
/// widget around them (rule 7: money stays on one line).
List<Map<String, Object?>> measureMoney(WidgetTester tester) {
  final out = <Map<String, Object?>>[];
  for (final element in find.byType(RichText).evaluate()) {
    final node = element.renderObject;
    if (node is! RenderParagraph || !node.attached || !node.hasSize) continue;
    final text = node.text.toPlainText().trim();
    if (!text.contains('₸')) continue;
    final lines = _lines(node);
    if (lines <= 1 && !node.didExceedMaxLines) continue;
    var owner = '?';
    element.visitAncestorElements((a) {
      final name = a.widget.runtimeType.toString();
      if (name.startsWith('Dk')) {
        owner = name;
        return false;
      }
      return true;
    });
    out.add({
      'control': 'money text',
      'place': owner,
      'designedHeight': null,
      'bodyFound': false,
      'bodyHeight': _round(node.size.height),
      'bodyWidth': _round(node.size.width),
      'outer': [_round(node.size.width), _round(node.size.height)],
      'labels': [text],
      'maxLines': lines,
      'cut': node.didExceedMaxLines,
      'overflows': false,
    });
  }
  return out;
}

/// The control's fixed-size boxes: render boxes constrained to [height]
/// (min or exact). Nested ones inside a found body are not repeated.
List<RenderBox> _bodies(RenderObject root, double? height) {
  if (height == null) return [];
  final found = <RenderBox>[];
  void visit(RenderObject node) {
    if (node is RenderConstrainedBox) {
      final c = node.additionalConstraints;
      if (c.minHeight == height ||
          (c.maxHeight == height && c.hasTightHeight)) {
        found.add(node);
        return;
      }
    }
    node.visitChildren(visit);
  }

  visit(root);
  return found;
}

/// (text, lines, cut, global rect) for every laid-out paragraph under [root].
List<(String, int, bool, Rect)> _paragraphs(RenderObject root) {
  final out = <(String, int, bool, Rect)>[];
  void visit(RenderObject node) {
    if (node is RenderParagraph && node.attached && node.hasSize) {
      final text = node.text.toPlainText().trim();
      if (text.isNotEmpty) {
        out.add((
          text,
          _lines(node),
          node.didExceedMaxLines,
          _globalRect(node),
        ));
      }
    }
    node.visitChildren(visit);
  }

  visit(root);
  return out;
}

/// How many lines [node] lays out in (same text, scaler, width, limit).
int _lines(RenderParagraph node) {
  final painter = TextPainter(
    text: node.text,
    textDirection: node.textDirection,
    textScaler: node.textScaler,
    maxLines: node.maxLines,
    ellipsis: node.overflow == TextOverflow.ellipsis ? '…' : null,
    strutStyle: node.strutStyle,
    textHeightBehavior: node.textHeightBehavior,
  )..layout(maxWidth: node.size.width + 0.01);
  final lines = painter.computeLineMetrics().length;
  painter.dispose();
  return lines;
}

Rect _globalRect(RenderBox box) =>
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);

double _round(double v) => (v * 10).roundToDouble() / 10;

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
