// Control measurements shared by the UI stability audit and the layout
// matrix (DESIGN.md §10): each interactive control's fixed-size body box
// against its designed height, and the labels inside it.
import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Controls measured on screens: widget type → (name, designed body height).
({String name, double? height})? controlSpec(Widget w) => switch (w) {
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
  DkListRow(subtitle: null) => (name: 'DkListRow', height: 56),
  DkListRow() => (name: 'DkListRow.twoLine', height: dkListRowTwoLineHeight),
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
      in find.byWidgetPredicate((w) => controlSpec(w) != null).evaluate()) {
    final control = controlSpec(element.widget)!;
    // The segmented control inside the language switch is the switch.
    if (control.name == 'DkSegmentedControl' &&
        element.findAncestorWidgetOfExactType<DkLanguageSwitch>() != null) {
      continue;
    }
    final root = element.renderObject;
    if (root is! RenderBox || !root.attached || !root.hasSize) continue;
    final bodies = _bodies(root, control.height);
    for (final body in bodies.isEmpty ? [root] : bodies) {
      final texts = paragraphsOf(body);
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
List<(String, int, bool, Rect)> paragraphsOf(RenderObject root) {
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
