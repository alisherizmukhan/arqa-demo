import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Two controls side by side, each half the width, or — when either one
/// cannot fit its label at 85 % in half the width — one above the other at
/// full width (DESIGN.md §10, addition B: «Выплатить» / «Отклонить» are
/// never cut). The children's minimum intrinsic width decides: a label that
/// may not be cut reports 85 % of its width (`DkLine(ellipsis: false)`).
class DkAdaptivePair extends MultiChildRenderObjectWidget {
  /// Creates the pair: [first] on the left (or on top), [second] on the
  /// right (or below).
  new({
    required Widget first,
    required Widget second,
    required this.gap,
    super.key,
  }) : super(children: [first, second]);

  /// Space between the two, both ways.
  final double gap;

  @override
  RenderDkAdaptivePair createRenderObject(BuildContext context) =>
      RenderDkAdaptivePair(gap: gap);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderDkAdaptivePair renderObject,
  ) {
    renderObject.gap = gap;
  }
}

/// Parent data of [RenderDkAdaptivePair] and [RenderDkAmountRow] children.
class DkPairParentData extends ContainerBoxParentData<RenderBox>;

/// Lays out [DkAdaptivePair].
class RenderDkAdaptivePair extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, DkPairParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, DkPairParentData> {
  /// Creates the render object.
  new({required this._gap});

  double _gap;

  /// Space between the two.
  double get gap => _gap;

  set gap(double value) {
    if (_gap == value) return;
    _gap = value;
    markNeedsLayout();
  }

  /// Whether the last layout stacked the two (for tests).
  bool stacked = false;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! DkPairParentData) {
      child.parentData = DkPairParentData();
    }
  }

  RenderBox get _first => firstChild!;
  RenderBox get _second => lastChild!;

  bool _stacks(double width) {
    final half = (width - _gap) / 2;
    return _first.getMinIntrinsicWidth(double.infinity) > half ||
        _second.getMinIntrinsicWidth(double.infinity) > half;
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _first.getMinIntrinsicWidth(height),
    _second.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _first.getMaxIntrinsicWidth(height) +
      _gap +
      _second.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => _height(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _height(width);

  double _height(double width) {
    if (_stacks(width)) {
      return _first.getMaxIntrinsicHeight(width) +
          _gap +
          _second.getMaxIntrinsicHeight(width);
    }
    final half = (width - _gap) / 2;
    return math.max(
      _first.getMaxIntrinsicHeight(half),
      _second.getMaxIntrinsicHeight(half),
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final width = constraints.maxWidth;
    if (_stacks(width)) {
      final c = BoxConstraints(minWidth: width, maxWidth: width);
      final a = _first.getDryLayout(c);
      final b = _second.getDryLayout(c);
      return constraints.constrain(Size(width, a.height + _gap + b.height));
    }
    final half = (width - _gap) / 2;
    final c = BoxConstraints(minWidth: half, maxWidth: half);
    final a = _first.getDryLayout(c);
    final b = _second.getDryLayout(c);
    return constraints.constrain(Size(width, math.max(a.height, b.height)));
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    stacked = _stacks(width);
    final a = _first.parentData! as DkPairParentData;
    final b = _second.parentData! as DkPairParentData;
    if (stacked) {
      final c = BoxConstraints(minWidth: width, maxWidth: width);
      _first.layout(c, parentUsesSize: true);
      _second.layout(c, parentUsesSize: true);
      a.offset = Offset.zero;
      b.offset = Offset(0, _first.size.height + _gap);
      size = constraints.constrain(
        Size(width, _first.size.height + _gap + _second.size.height),
      );
      return;
    }
    final half = (width - _gap) / 2;
    final c = BoxConstraints(minWidth: half, maxWidth: half);
    _first.layout(c, parentUsesSize: true);
    _second.layout(c, parentUsesSize: true);
    final height = math.max(_first.size.height, _second.size.height);
    a.offset = Offset(0, (height - _first.size.height) / 2);
    b.offset = Offset(half + _gap, (height - _second.size.height) / 2);
    size = constraints.constrain(Size(width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A row of a text column (`start`) and an amount column (`end`)
/// (DESIGN.md §10, rule 7 and addition C): the amount keeps at least 85 %
/// of its width — the text column gives way first (its lines end in «…»);
/// if the text column would get less than its own minimum, the amount moves
/// to its own line under it (aligned to the end). Digits are never cut.
///
/// Minimum widths come from the children's minimum intrinsic width: lines
/// that may not be cut (`DkLine(ellipsis: false)`: times, amounts) report
/// 85 % of their width, lines that may be cut report nothing.
class DkAmountRow extends MultiChildRenderObjectWidget {
  /// Creates the row.
  new({
    required Widget start,
    required Widget end,
    required this.gap,
    super.key,
  }) : super(children: [start, end]);

  /// Space between the columns, both ways.
  final double gap;

  @override
  RenderDkAmountRow createRenderObject(BuildContext context) =>
      RenderDkAmountRow(gap: gap, textDirection: Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    RenderDkAmountRow renderObject,
  ) {
    renderObject
      ..gap = gap
      ..textDirection = Directionality.of(context);
  }
}

/// Lays out [DkAmountRow].
class RenderDkAmountRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, DkPairParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, DkPairParentData> {
  /// Creates the render object.
  new({required this._gap, required this._textDirection});

  double _gap;
  TextDirection _textDirection;

  /// Space between the columns.
  double get gap => _gap;

  set gap(double value) {
    if (_gap == value) return;
    _gap = value;
    markNeedsLayout();
  }

  /// Start and end follow it.
  TextDirection get textDirection => _textDirection;

  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// Whether the last layout put the amount on its own line (for tests).
  bool stacked = false;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! DkPairParentData) {
      child.parentData = DkPairParentData();
    }
  }

  RenderBox get _start => firstChild!;
  RenderBox get _end => lastChild!;

  bool _stacks(double width) =>
      _start.getMinIntrinsicWidth(double.infinity) +
          _gap +
          _end.getMinIntrinsicWidth(double.infinity) >
      width;

  /// The end column's width side by side: all it wants, unless the start
  /// column would get less than its minimum.
  double _endWidth(double width) => math.min(
    _end.getMaxIntrinsicWidth(double.infinity),
    width - _gap - _start.getMinIntrinsicWidth(double.infinity),
  );

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _start.getMinIntrinsicWidth(height),
    _end.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _start.getMaxIntrinsicWidth(height) +
      _gap +
      _end.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => _height(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _height(width);

  double _height(double width) {
    if (!width.isFinite || _stacks(width)) {
      return _start.getMaxIntrinsicHeight(width) +
          _gap +
          _end.getMaxIntrinsicHeight(width);
    }
    final endWidth = _endWidth(width);
    return math.max(
      _start.getMaxIntrinsicHeight(width - _gap - endWidth),
      _end.getMaxIntrinsicHeight(endWidth),
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final width = constraints.maxWidth;
    if (_stacks(width)) {
      final a = _start.getDryLayout(BoxConstraints.tightFor(width: width));
      final b = _end.getDryLayout(BoxConstraints(maxWidth: width));
      return constraints.constrain(Size(width, a.height + _gap + b.height));
    }
    final endWidth = _endWidth(width);
    final a = _start.getDryLayout(
      BoxConstraints.tightFor(width: width - _gap - endWidth),
    );
    final b = _end.getDryLayout(BoxConstraints(maxWidth: endWidth));
    return constraints.constrain(Size(width, math.max(a.height, b.height)));
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    stacked = _stacks(width);
    final a = _start.parentData! as DkPairParentData;
    final b = _end.parentData! as DkPairParentData;
    final ltr = _textDirection == TextDirection.ltr;
    if (stacked) {
      _start.layout(
        BoxConstraints.tightFor(width: width),
        parentUsesSize: true,
      );
      _end.layout(BoxConstraints(maxWidth: width), parentUsesSize: true);
      a.offset = Offset.zero;
      b.offset = Offset(
        ltr ? width - _end.size.width : 0,
        _start.size.height + _gap,
      );
      size = constraints.constrain(
        Size(width, _start.size.height + _gap + _end.size.height),
      );
      return;
    }
    final endWidth = _endWidth(width);
    final startWidth = width - _gap - endWidth;
    _start.layout(
      BoxConstraints.tightFor(width: startWidth),
      parentUsesSize: true,
    );
    _end.layout(BoxConstraints(maxWidth: endWidth), parentUsesSize: true);
    final height = math.max(_start.size.height, _end.size.height);
    a.offset = Offset(
      ltr ? 0 : width - startWidth,
      (height - _start.size.height) / 2,
    );
    b.offset = Offset(
      ltr ? width - _end.size.width : 0,
      (height - _end.size.height) / 2,
    );
    size = constraints.constrain(Size(width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A header row of a title (`start`) and actions (`end`) (DESIGN.md §10):
/// the title first shrinks to [minScale] of its width, then the actions give
/// way (to their minimum: their labels shrink, then end in «…»), and only
/// then does the title end in «…». It never stacks, so the row keeps its
/// height.
class DkPriorityRow extends MultiChildRenderObjectWidget {
  /// Creates the row.
  new({
    required Widget start,
    required Widget end,
    required this.gap,
    this.minScale = 0.85,
    super.key,
  }) : super(children: [start, end]);

  /// Space between the two.
  final double gap;

  /// How far the title shrinks before the actions give way.
  final double minScale;

  @override
  RenderDkPriorityRow createRenderObject(BuildContext context) =>
      RenderDkPriorityRow(
        gap: gap,
        minScale: minScale,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderDkPriorityRow renderObject,
  ) {
    renderObject
      ..gap = gap
      ..minScale = minScale
      ..textDirection = Directionality.of(context);
  }
}

/// Lays out [DkPriorityRow].
class RenderDkPriorityRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, DkPairParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, DkPairParentData> {
  /// Creates the render object.
  new({
    required this._gap,
    required this._minScale,
    required this._textDirection,
  });

  double _gap;
  double _minScale;
  TextDirection _textDirection;

  /// Space between the two.
  double get gap => _gap;

  set gap(double value) {
    if (_gap == value) return;
    _gap = value;
    markNeedsLayout();
  }

  /// How far the title shrinks first.
  double get minScale => _minScale;

  set minScale(double value) {
    if (_minScale == value) return;
    _minScale = value;
    markNeedsLayout();
  }

  /// Start and end follow it.
  TextDirection get textDirection => _textDirection;

  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! DkPairParentData) {
      child.parentData = DkPairParentData();
    }
  }

  RenderBox get _start => firstChild!;
  RenderBox get _end => lastChild!;

  /// The end's width for a row of [width].
  double _endWidth(double width) {
    final startFull = _start.getMaxIntrinsicWidth(double.infinity);
    final endFull = _end.getMaxIntrinsicWidth(double.infinity);
    final endMin = _end.getMinIntrinsicWidth(double.infinity);
    final room = width - _gap;
    // The title at its smallest before cutting; the actions take the rest,
    // but never less than their own minimum.
    if (startFull * _minScale + endFull <= room) return endFull;
    return math.max(endMin, room - startFull * _minScale);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _end.getMinIntrinsicWidth(height) + _gap;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _start.getMaxIntrinsicWidth(height) +
      _gap +
      _end.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => math.max(
    _start.getMinIntrinsicHeight(double.infinity),
    _end.getMinIntrinsicHeight(double.infinity),
  );

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    _start.getMaxIntrinsicHeight(double.infinity),
    _end.getMaxIntrinsicHeight(double.infinity),
  );

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final endWidth = _endWidth(width);
    final a = _start.getDryLayout(
      BoxConstraints(maxWidth: math.max(0, width - _gap - endWidth)),
    );
    final b = _end.getDryLayout(BoxConstraints(maxWidth: endWidth));
    return constraints.constrain(Size(width, math.max(a.height, b.height)));
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final endWidth = _endWidth(width);
    final startWidth = math.max<double>(0, width - _gap - endWidth);
    _start.layout(BoxConstraints(maxWidth: startWidth), parentUsesSize: true);
    _end.layout(BoxConstraints(maxWidth: endWidth), parentUsesSize: true);
    final height = math.max(_start.size.height, _end.size.height);
    final ltr = _textDirection == TextDirection.ltr;
    final a = _start.parentData! as DkPairParentData;
    final b = _end.parentData! as DkPairParentData;
    a.offset = Offset(
      ltr ? 0 : width - _start.size.width,
      (height - _start.size.height) / 2,
    );
    b.offset = Offset(
      ltr ? width - _end.size.width : 0,
      (height - _end.size.height) / 2,
    );
    size = constraints.constrain(Size(width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
