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
    group('$name theme meets WCAG AA', () {
      final textPairs = <String, (Color, Color)>{
        'text on surface': (c.textPrimary, c.surface),
        'text on background': (c.textPrimary, c.background),
        'secondary text on surface': (c.textSecondary, c.surface),
        'secondary text on background': (c.textSecondary, c.background),
        'secondary text on muted': (c.textSecondary, c.surfaceMuted),
        'on primary': (c.onPrimary, c.primary),
        'primary text on background': (c.primary, c.background),
        'positive figure': (c.positive, c.surface),
        'cash accent': (c.cash, c.surface),
        'card accent': (c.card, c.surface),
        'error text': (c.error, c.surface),
        'on error': (c.onError, c.error),
        'error banner text': (c.onErrorContainer, c.errorContainer),
      };
      for (final MapEntry(key: label, value: (fg, bg)) in textPairs.entries) {
        test('$label >= 4.5:1', () {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }

      test('control outline >= 3:1 against surface', () {
        expect(contrast(c.outline, c.surface), greaterThanOrEqualTo(3));
      });

      test('focus ring >= 3:1 against surface', () {
        expect(contrast(c.focus, c.surface), greaterThanOrEqualTo(3));
      });
    });
  }
}
