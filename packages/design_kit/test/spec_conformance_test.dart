// Parses packages/design_kit/DESIGN.md and checks that the Dart tokens match
// it value by value, so "implement exactly these values" is verified by a
// machine and cannot silently drift.
import 'dart:io';

import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final String _spec = File('DESIGN.md').readAsStringSync();

/// The markdown table under [heading] as rows of trimmed cells.
List<List<String>> _table(String heading) {
  final start = _spec.indexOf(heading);
  if (start < 0) throw StateError('section $heading not found in DESIGN.md');
  final rows = <List<String>>[];
  var inTable = false;
  for (final line in _spec.substring(start).split('\n').skip(1)) {
    final trimmed = line.trim();
    if (trimmed.startsWith('|')) {
      inTable = true;
      final cells = trimmed
          .substring(1, trimmed.length - 1)
          .split('|')
          .map((c) => c.trim())
          .toList();
      if (!cells.first.startsWith('---') && cells.first != 'Token') {
        if (cells.first != 'Style') rows.add(cells);
      }
    } else if (inTable) {
      break;
    }
  }
  return rows;
}

Color _hex(String cell) {
  final hex = RegExp('#([0-9A-Fa-f]{6,8})').firstMatch(cell)![1]!;
  return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
}

double _number(String text) =>
    double.parse(text.replaceAll('−', '-').replaceAll(' ', ''));

void main() {
  group('DkColors match DESIGN.md §2.1', () {
    final rows = _table('### 2.1 DkColors');

    test('every spec token exists and nothing extra', () {
      expect(DkColors.light.all.keys.toSet(), rows.map((r) => r[0]).toSet());
    });

    for (final row in rows) {
      test(row[0], () {
        expect(DkColors.light.all[row[0]], _hex(row[1]), reason: 'light');
        expect(DkColors.dark.all[row[0]], _hex(row[2]), reason: 'dark');
      });
    }
  });

  group('DkTypography matches DESIGN.md §2.2', () {
    final rows = _table('### 2.2 DkTypography');
    final styles = DkTypography.standard.all;

    test('every spec style exists and nothing extra', () {
      expect(styles.keys.toSet(), rows.map((r) => r[0]).toSet());
    });

    for (final row in rows) {
      test(row[0], () {
        final style = styles[row[0]]!;
        final [size, line] = row[1].split('/').map(_number).toList();
        final em = RegExp('([−-]?[0-9.]+)em').firstMatch(row[3]);
        final letterSpacing = em == null ? 0.0 : _number(em[1]!) * size;

        expect(style.fontSize, size);
        expect(style.height! * size, closeTo(line, 1e-9));
        expect(style.fontWeight!.value, _number(row[2]).toInt());
        expect(style.letterSpacing, closeTo(letterSpacing, 1e-9));
        expect(style.fontFamily, 'packages/design_kit/Manrope');
        expect(
          style.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
        expect(style.fontFamilyFallback, [
          'packages/design_kit/IBMPlexSans',
        ], reason: 'Manrope lacks ₸ and U+202F');
      });
    }
  });

  test('DkSpacing matches DESIGN.md §2.3', () {
    final line = RegExp('`(s2=.*?)`').firstMatch(_spec)![1]!;
    final values = {
      for (final part in line.split(','))
        part.split('=')[0].trim(): _number(part.split('=')[1]),
    };
    const s = DkSpacing.standard;
    final actual = {
      's2': s.s2,
      's4': s.s4,
      's6': s.s6,
      's8': s.s8,
      's10': s.s10,
      's12': s.s12,
      's14': s.s14,
      's16': s.s16,
      's20': s.s20,
      's24': s.s24,
      's32': s.s32,
      's40': s.s40,
      's48': s.s48,
      's64': s.s64,
    };
    expect(actual, values);
    expect(s.screenGutter, 16);
  });

  test('DkRadii match DESIGN.md §2.4', () {
    const r = DkRadii.standard;
    final actual = {
      'xs': r.xs,
      'sm': r.sm,
      'segment': r.segment,
      'md': r.md,
      'segmentTrack': r.segmentTrack,
      'lg': r.lg,
      'xl': r.xl,
      'pill': r.pill,
    };
    expect(actual, {
      for (final row in _table('### 2.4 DkRadii')) row[0]: _number(row[1]),
    });
  });

  group('DkElevation matches DESIGN.md §2.5', () {
    final shadowPattern = RegExp(
      r'(\d+) (\d+) (\d+) rgba\((\d+),(\d+),(\d+),([\d.]+)\)',
    );
    const light = DkElevation.light;
    final actual = {
      'e1': light.e1,
      'e1Hero': light.e1Hero,
      'e2Fab': light.e2Fab,
      'e3': light.e3,
      'thumb': light.thumb,
    };

    for (final row in _table('### 2.5 DkElevation')) {
      test(row[0], () {
        // `e2Fab` is written with the accent color by name in the spec.
        final cell = row[1].replaceAll('accent', 'rgba(36,80,216,0.28)');
        final expected = [
          for (final m in shadowPattern.allMatches(cell))
            BoxShadow(
              offset: Offset(0, _number(m[2]!)),
              blurRadius: _number(m[3]!),
              color: Color.fromRGBO(
                int.parse(m[4]!),
                int.parse(m[5]!),
                int.parse(m[6]!),
                _number(m[7]!),
              ),
            ),
        ];
        expect(actual[row[0]], expected);
      });
    }

    test('dark has no shadows', () {
      const d = DkElevation.dark;
      for (final shadows in [d.e1, d.e1Hero, d.e2Fab, d.e3, d.thumb]) {
        expect(shadows, isEmpty);
      }
    });
  });

  test('DkSizes match DESIGN.md §2.6', () {
    const s = DkSizes.standard;
    expect(s.tapTargetMin, 48);
    expect((s.buttonHeight, s.textButtonHeight), (56, 48));
    expect(
      (s.fieldHeight, s.segmentedHeight, s.daySwitcherHeight),
      (56, 56, 56),
    );
    expect(s.tripTileMinHeight, 72);
    expect((s.iconTile, s.iconTileIcon), (40, 22));
    expect((s.stateIconTile, s.stateIcon), (80, 36));
    expect((s.dialogIconTile, s.dialogIcon), (56, 28));
    expect((s.splitBarHeight, s.splitBarGap), (8, 3));
    expect(
      (s.iconNav, s.iconAction, s.iconField, s.iconInline),
      (24, 22, 20, 16),
    );
    expect((s.fieldBorder, s.fieldBorderFocused, s.focusRing), (1, 2, 4));
    // From §4 / §5 (screen-level sizes kept as tokens, see DECISIONS.md).
    expect((s.headerHeight, s.appBarHeight, s.wordmarkDot), (48, 56, 12));
    expect(s.spinnerStroke, 2.6);
  });
}
