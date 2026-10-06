import 'dart:math' as math;

import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, c) in [
    ('light', DkColors.light),
    ('dark', DkColors.dark),
  ]) {
    group('$name: text pairs used by the spec meet WCAG AA (4.5:1)', () {
      final pairs = <String, (Color, Color)>{
        'textPrimary on surface': (c.textPrimary, c.surface),
        'textPrimary on bg': (c.textPrimary, c.bg),
        'textSecondary on surface': (c.textSecondary, c.surface),
        'textSecondary on bg': (c.textSecondary, c.bg),
        // DESIGN.md §2.1: "textTertiary ≥ 4.5:1 on surface in both themes".
        'textTertiary on surface': (c.textTertiary, c.surface),
        'textSecondary on surfaceMuted (disabled field)': (
          c.textSecondary,
          c.surfaceMuted,
        ),
        'textSecondary on segmentTrack': (c.textSecondary, c.segmentTrack),
        'textPrimary on segmentThumb': (c.textPrimary, c.segmentThumb),
        'accent (hero, links) on surface': (c.accent, c.surface),
        'onAccent on accent (buttons, FAB)': (c.onAccent, c.accent),
        'accent on accentSoft (secondary button, badge)': (
          c.accent,
          c.accentSoft,
        ),
        'textPrimary on accentSoft (highlighted row)': (
          c.textPrimary,
          c.accentSoft,
        ),
        'error on surface (field errors)': (c.error, c.surface),
        'error on bg (error rows below fields)': (c.error, c.bg),
        'onInverse on inverseSurface (snackbar)': (
          c.onInverse,
          c.inverseSurface,
        ),
        'inverseAccent on inverseSurface (snackbar action)': (
          c.inverseAccent,
          c.inverseSurface,
        ),
      };
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        test(label, () => expect(contrast(fg, bg), greaterThanOrEqualTo(4.5)));
      }
    });

    group('$name: meaningful icons meet 3:1', () {
      final pairs = <String, (Color, Color)>{
        'error icon on errorSoft tile': (c.error, c.errorSoft),
        'accent icon on accentSoft tile': (c.accent, c.accentSoft),
        'inverseError icon on snackbar': (c.inverseError, c.inverseSurface),
        'inverseSuccess icon on snackbar': (c.inverseSuccess, c.inverseSurface),
        // WCAG 1.4.11: control boundaries ≥ 3:1 (token changed from the
        // mockup values, see DECISIONS.md).
        'field border on surface': (c.border, c.surface),
      };
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        test(label, () => expect(contrast(fg, bg), greaterThanOrEqualTo(3)));
      }
    });
  }

  // Disabled text (`textDisabled` on `disabledFill`) is exempt from WCAG.
}
