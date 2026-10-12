import 'dart:math' as math;

import 'package:design_kit/src/format/dk_grouped_text.dart';
import 'package:design_kit/src/format/dk_money.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The smallest a label may shrink to fit its control: 85 % of its style
/// size (DESIGN.md §10, rule 3).
const double dkMinFitScale = 0.85;

/// The largest system text scale the app follows (DESIGN.md §10, rule 1).
const double dkMaxTextScale = 1.3;

/// One line of a [DkFitLines].
@immutable
class DkLine {
  /// A line of [text] in [style]. U+202F gaps are widened as in
  /// `DkGroupedText`. With [ellipsis] false the line is never cut: it
  /// shrinks to [dkMinFitScale] and no further (times, amounts — rule 7).
  const new(
    this.text, {
    this.style,
    this.ellipsis = true,
    this.trailing,
    this.short,
  }) : span = null;

  /// A line drawn from a ready [span] (e.g. a number and a `₸` in another
  /// style). [text] is its plain text.
  const new span(
    InlineSpan this.span, {
    required this.text,
    this.ellipsis = true,
    this.trailing,
    this.short,
  }) : style = null;

  /// An amount (`DkMoney.format`): never cut.
  factory money(int amount, {TextStyle? style, bool negative = false}) =>
      DkLine(
        DkMoney.format(negative && amount > 0 ? -amount : amount),
        style: style,
        ellipsis: false,
      );

  /// The text (one line).
  final String text;

  /// Merged over the ambient `DefaultTextStyle`.
  final TextStyle? style;

  /// Whether the line may end in «…» when it cannot fit at 85 %.
  final bool ellipsis;

  /// Drawn instead of [text] when set.
  final InlineSpan? span;

  /// A small widget after the text on the same line (the day switcher's
  /// chevron); the text gives way to it.
  final Widget? trailing;

  /// A shorter form shown instead when the line cannot fit at 85 % (the
  /// payment tile «Наличные · 38%» → «Наличные», the badge «+1 день» →
  /// «+1»). Screen readers always get [text].
  final String? short;
}

/// Text that never wraps and never grows its control (DESIGN.md §10):
/// every line is one line; when the lines do not fit the width (or a fixed
/// height), they first scale down together, to at most 85 % of their size;
/// a line that still does not fit ends in «…» — the full text stays in
/// semantics and in a tooltip (long press). Lines with `ellipsis: false`
/// (times, amounts) are never cut: they report 85 % of their width as their
/// minimum, so a parent can make room (`DkAmountRow`, `DkAdaptivePair`).
///
/// The lines are ordinary one-line `Text` widgets, scaled when painted.
class DkFitLines extends StatefulWidget {
  /// Creates the text block.
  const new(
    this.lines, {
    this.textAlign = TextAlign.start,
    this.minScale = dkMinFitScale,
    this.tooltip = true,
    this.gap = 0,
    super.key,
  });

  /// Top to bottom.
  final List<DkLine> lines;

  /// Horizontal alignment of the lines.
  final TextAlign textAlign;

  /// Smallest scale before «…».
  final double minScale;

  /// Long press shows the full text when a line is cut.
  final bool tooltip;

  /// Space between lines.
  final double gap;

  @override
  State<DkFitLines> createState() => _DkFitLinesState();
}

class _DkFitLinesState extends State<DkFitLines> {
  bool _cut = false;

  Widget _text(DkLine line, InlineSpan span) => Text.rich(
    span,
    maxLines: 1,
    softWrap: false,
    textAlign: widget.textAlign,
    overflow: line.ellipsis ? TextOverflow.ellipsis : TextOverflow.visible,
    // The line height comes from the style, never from the glyphs: «…» or
    // `₸` from a fallback font must not make a cut line taller.
    strutStyle: span.style == null
        ? null
        : StrutStyle.fromTextStyle(span.style!, forceStrutHeight: true),
  );

  Widget _lineText(DkLine line, TextStyle base) {
    TextSpan plain(String text) {
      final style = base.merge(line.style);
      return TextSpan(style: style, children: dkGroupedSpans(text, style));
    }

    final full = _text(line, line.span ?? plain(line.text));
    final short = line.short;
    if (short == null) return full;
    return Semantics(
      label: line.text,
      excludeSemantics: true,
      child: _LineChoice(full: full, short: _text(line, plain(short))),
    );
  }

  static Widget _withTrailing(Widget? trailing, Widget text) {
    if (trailing == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: text),
        trailing,
      ],
    );
  }

  void _onCut(bool cut) {
    if (cut == _cut) return;
    // Reported during layout: rebuild after this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && cut != _cut) setState(() => _cut = cut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    final align = switch (widget.textAlign) {
      TextAlign.center => CrossAxisAlignment.center,
      TextAlign.end || TextAlign.right => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.start,
    };
    Widget text = _FitScale(
      minScale: widget.minScale,
      textAlign: widget.textAlign,
      onCut: _onCut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: align,
        spacing: widget.gap,
        children: [
          for (final line in widget.lines)
            _LineMinWidth(
              minScale: line.ellipsis ? 0 : widget.minScale,
              child: _withTrailing(line.trailing, _lineText(line, base)),
            ),
        ],
      ),
    );
    if (_cut && widget.tooltip) {
      text = Tooltip(
        message: widget.lines.map((l) => l.text).join('\n'),
        excludeFromSemantics: true,
        child: text,
      );
    }
    return text;
  }
}

/// One line of fitting text: [DkFitLines] with a single [DkLine].
class DkFitText extends StatelessWidget {
  /// Creates the text.
  const new(
    this.text, {
    this.style,
    this.textAlign = TextAlign.start,
    this.ellipsis = true,
    this.tooltip = true,
    super.key,
  });

  /// The text.
  final String text;

  /// Merged over the ambient `DefaultTextStyle`.
  final TextStyle? style;

  /// Alignment inside the given width.
  final TextAlign textAlign;

  /// False: never cut (stops at 85 %).
  final bool ellipsis;

  /// Long press shows the full text when it is cut.
  final bool tooltip;

  @override
  Widget build(BuildContext context) => DkFitLines(
    [DkLine(text, style: style, ellipsis: ellipsis)],
    textAlign: textAlign,
    tooltip: tooltip,
  );
}

/// A line's minimum intrinsic width: [minScale] × its natural width (0 for
/// a line that may be cut).
class _LineMinWidth extends SingleChildRenderObjectWidget {
  const new({required this.minScale, required super.child});

  final double minScale;

  @override
  _RenderLineMinWidth createRenderObject(BuildContext context) =>
      _RenderLineMinWidth(minScale);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLineMinWidth renderObject,
  ) {
    renderObject.minScale = minScale;
  }
}

class _RenderLineMinWidth extends RenderProxyBox {
  new(this._minScale);

  double _minScale;

  double get minScale => _minScale;

  set minScale(double value) {
    if (_minScale == value) return;
    _minScale = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      (child?.getMaxIntrinsicWidth(height) ?? 0) * _minScale;
}

class _FitScale extends SingleChildRenderObjectWidget {
  const new({
    required this.minScale,
    required this.textAlign,
    required this.onCut,
    required super.child,
  });

  final double minScale;
  final TextAlign textAlign;
  final ValueChanged<bool> onCut;

  @override
  RenderDkFitLines createRenderObject(BuildContext context) => RenderDkFitLines(
    minScale: minScale,
    textAlign: textAlign,
    textDirection: Directionality.of(context),
    onCut: onCut,
  );

  @override
  void updateRenderObject(BuildContext context, RenderDkFitLines renderObject) {
    renderObject
      ..minScale = minScale
      ..textAlign = textAlign
      ..textDirection = Directionality.of(context)
      ..onCut = onCut;
  }
}

/// Scales its one-line `Text` children down to fit (see [DkFitLines]).
class RenderDkFitLines extends RenderProxyBox {
  /// Creates the render object.
  new({
    required this._minScale,
    required this._textAlign,
    required this._textDirection,
    required this.onCut,
  });

  double _minScale;
  TextAlign _textAlign;
  TextDirection _textDirection;

  /// Told after each layout whether a line ended in «…».
  ValueChanged<bool> onCut;

  /// The scale of the last layout (1 = full size).
  double scale = 1;

  /// Whether a line ended in «…» in the last layout.
  bool cut = false;

  /// Smallest scale.
  double get minScale => _minScale;

  set minScale(double value) {
    if (_minScale == value) return;
    _minScale = value;
    markNeedsLayout();
  }

  /// Horizontal alignment inside a wider box.
  TextAlign get textAlign => _textAlign;

  set textAlign(TextAlign value) {
    if (_textAlign == value) return;
    _textAlign = value;
    markNeedsLayout();
  }

  /// For start / end.
  TextDirection get textDirection => _textDirection;

  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  Offset _offset = Offset.zero;

  double _scaleFor(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return 1;
    var width = child.getMaxIntrinsicWidth(double.infinity);
    final height = child.getMaxIntrinsicHeight(width);
    if (constraints.hasBoundedWidth) {
      width = _fittedWidth(child, constraints.maxWidth, width);
    }
    var s = 1.0;
    if (constraints.hasBoundedWidth && width > 0) {
      s = math.min(s, constraints.maxWidth / width);
    }
    if (constraints.hasBoundedHeight && height > 0) {
      s = math.min(s, constraints.maxHeight / height);
    }
    return s.clamp(_minScale, 1.0);
  }

  BoxConstraints _childConstraints(BoxConstraints constraints, double s) =>
      BoxConstraints(
        maxWidth: constraints.hasBoundedWidth
            ? constraints.maxWidth / s
            : double.infinity,
      );

  @override
  double computeMinIntrinsicWidth(double height) =>
      child?.getMinIntrinsicWidth(double.infinity) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      child?.getMaxIntrinsicWidth(double.infinity) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      (child?.getMaxIntrinsicHeight(double.infinity) ?? 0) * _minScale;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(double.infinity) ?? 0;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final s = _scaleFor(constraints);
    final size = child.getDryLayout(_childConstraints(constraints, s));
    return constraints.constrain(Size(size.width * s, size.height));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    scale = _scaleFor(constraints);
    child.layout(_childConstraints(constraints, scale), parentUsesSize: true);
    // Shrinking to fit the width never changes the height: the box keeps the
    // lines' natural height (the scaled text is centred in it), so a control
    // is as tall with a long label as with a short one. Only a fixed height
    // smaller than that shrinks it.
    size = constraints.constrain(
      Size(child.size.width * scale, child.size.height),
    );
    final free = size.width - child.size.width * scale;
    final ltr = _textDirection == TextDirection.ltr;
    final dx = switch (_textAlign) {
      TextAlign.center => free / 2,
      TextAlign.right => free,
      TextAlign.left => 0.0,
      TextAlign.end => ltr ? free : 0.0,
      TextAlign.start || TextAlign.justify => ltr ? 0.0 : free,
    };
    _offset = Offset(dx, (size.height - child.size.height * scale) / 2);
    cut = _anyCut(child);
    onCut(cut);
  }

  /// The lines' natural width when every line that has a short form and
  /// cannot fit at the smallest scale is measured by that short form.
  double _fittedWidth(RenderBox column, double maxWidth, double natural) {
    if (column is! RenderFlex) return natural;
    var width = 0.0;
    var line = column.firstChild;
    while (line != null) {
      var w = line.getMaxIntrinsicWidth(double.infinity);
      final choice = _choiceOf(line);
      if (choice != null && w * _minScale > maxWidth) {
        w = choice.shortWidth;
      }
      width = math.max(width, w);
      line = (line.parentData! as FlexParentData).nextSibling;
    }
    return width;
  }

  static _RenderLineChoice? _choiceOf(RenderObject? node) {
    var n = node;
    while (n is RenderProxyBox && n is! _RenderLineChoice) {
      n = n.child;
    }
    if (n is RenderFlex) n = n.firstChild;
    while (n is RenderProxyBox && n is! _RenderLineChoice) {
      n = n.child;
    }
    return n is _RenderLineChoice ? n : null;
  }

  /// The paragraph a line shows: its text, the chosen form of a line with a
  /// short form, or the text before a trailing widget.
  static RenderParagraph? _lineParagraph(RenderObject? node) {
    var n = node;
    while (n is RenderProxyBox && n is! _RenderLineChoice) {
      n = n.child;
    }
    if (n is RenderFlex) n = n.firstChild;
    while (n is RenderProxyBox && n is! _RenderLineChoice) {
      n = n.child;
    }
    if (n is _RenderLineChoice) n = n.chosen;
    return n is RenderParagraph ? n : null;
  }

  /// Whether a line's own text ended in «…» (each line is a
  /// [_RenderLineMinWidth] over the text, or over a row of the text and its
  /// trailing widget). Other paragraphs (icons, `+1`) are not looked at.
  static bool _anyCut(RenderObject column) {
    var found = false;
    column.visitChildren((line) {
      if (found || line is! _RenderLineMinWidth) return;
      final text = _lineParagraph(line.child);
      if (text != null && text.didExceedMaxLines) found = true;
    });
    return found;
  }

  Matrix4 get _transform => Matrix4.identity()
    ..translateByDouble(_offset.dx, _offset.dy, 0, 1)
    ..scaleByDouble(scale, scale, 1, 1);

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    void paintChild(PaintingContext context, Offset offset) {
      context.pushTransform(
        needsCompositing,
        offset,
        _transform,
        (context, offset) => context.paintChild(child, offset),
      );
    }

    // Taller than the box even at 85 %: clip rather than draw over the
    // neighbours (only past the 1.3 text-scale clamp).
    if (child.size.height * scale > size.height + 0.5) {
      context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        paintChild,
      );
    } else {
      paintChild(context, offset);
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transform);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintTransform(
        transform: _transform,
        position: position,
        hitTest: (result, position) =>
            child?.hitTest(result, position: position) ?? false,
      );
}

/// A line with a short form: the full text when it fits the width it is
/// given, else the short one (see [DkLine.short]).
class _LineChoice extends MultiChildRenderObjectWidget {
  new({required Widget full, required Widget short})
    : super(children: [full, short]);

  @override
  _RenderLineChoice createRenderObject(BuildContext context) =>
      _RenderLineChoice();
}

class _ChoiceParentData extends ContainerBoxParentData<RenderBox>;

class _RenderLineChoice extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ChoiceParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ChoiceParentData> {
  bool useShort = false;

  RenderBox get _full => firstChild!;
  RenderBox get _short => lastChild!;

  /// The child on screen.
  RenderBox get chosen => useShort ? _short : _full;

  double get shortWidth => _short.getMaxIntrinsicWidth(double.infinity);

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ChoiceParentData) {
      child.parentData = _ChoiceParentData();
    }
  }

  bool _usesShort(BoxConstraints constraints) =>
      constraints.hasBoundedWidth &&
      _full.getMaxIntrinsicWidth(double.infinity) > constraints.maxWidth + 0.5;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _short.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _full.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => math.max(
    _full.getMinIntrinsicHeight(width),
    _short.getMinIntrinsicHeight(width),
  );

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    _full.getMaxIntrinsicHeight(width),
    _short.getMaxIntrinsicHeight(width),
  );

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      (_usesShort(constraints) ? _short : _full).getDryLayout(constraints);

  @override
  void performLayout() {
    useShort = _usesShort(constraints);
    // The form not shown is laid out at its natural width, so it never
    // reads as cut.
    final unbounded = BoxConstraints(maxHeight: constraints.maxHeight);
    _full.layout(useShort ? unbounded : constraints, parentUsesSize: true);
    _short.layout(useShort ? constraints : unbounded, parentUsesSize: true);
    size = constraints.constrain(chosen.size);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      context.paintChild(chosen, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      chosen.hitTest(result, position: position);

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) =>
      visitor(chosen);
}
