// DESIGN.md §10: a control's size never depends on its label. Every control
// is rendered with a real short label and with three times the longest real
// label, in Russian and Kazakh, at text ×1.0, ×1.15 and ×1.3 (the clamp): the
// size must be the same (inline controls: the same height and a width inside
// their cap), with no layout error and every label on one line.
import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

/// The screen and its content column (360 − 2 × 16).
const double _screen = 360;
const double _column = 328;

/// Real labels: the short one, and the longest one for that role.
typedef _Labels = ({String short, String long});

String _x3(String s) => '$s $s $s';

const Map<String, _Labels> _ru = {
  'button': (short: 'Войти', long: 'Сохранить как новую'),
  'fab': (short: 'Поездка', long: 'Добавить поездку'),
  'tab': (short: 'Выводы', long: 'Водители'),
  'decision': (short: 'Отклонить', long: 'Выплатить'),
  'language': (short: 'Русский', long: 'Қазақша'),
  'chip': (short: 'Все', long: 'Все водители'),
  'badge': (short: '+1 день', long: '+1 день'),
  'status': (short: 'Выплачено', long: 'В обработке'),
  'today': (short: 'Сегодня', long: 'Сегодня'),
  'row': (short: 'Язык', long: 'Сбросить все сессии'),
  'field': (short: 'Сумма', long: 'Сумма вывода'),
  'title': (short: 'Меню', long: 'Вывод средств'),
  'meta': (short: '22 мин · Карта', long: '15 мин · Наличные'),
  'tile': (short: 'Карта', long: 'Наличные'),
};

const Map<String, _Labels> _kk = {
  'button': (short: 'Кіру', long: 'Жаңа етіп сақтау'),
  'fab': (short: 'Сапар', long: 'Сапар қосу'),
  'tab': (short: 'Шығару', long: 'Жүргізуші'),
  'decision': (short: 'Төлеу', long: 'Қабылдамау'),
  'language': (short: 'Русский', long: 'Қазақша'),
  'chip': (short: 'Барлығы', long: 'Барлық жүргізушілер'),
  'badge': (short: '+1 күн', long: '+1 күн'),
  'status': (short: 'Төленді', long: 'Қабылданбады'),
  'today': (short: 'Бүгін', long: 'Бүгін'),
  'row': (short: 'Тіл', long: 'Барлық сессияны тоқтату'),
  'field': (short: 'Сома', long: 'Шығару сомасы'),
  'title': (short: 'Мәзір', long: 'Қаражат шығару'),
  'meta': (short: '22 мин · Карта', long: '15 мин · Қолма-қол'),
  'tile': (short: 'Карта', long: 'Қолма-қол'),
};

/// How a control's size is compared.
enum _Fit {
  /// Width and height identical (full-width or fixed controls).
  exact,

  /// Same height; width within `maxWidth` (inline controls).
  inline,
}

typedef _Probe = ({
  String name,
  String role,
  _Fit fit,
  double maxWidth,
  Widget Function(String label) build,

  /// What is measured inside the probe (default: the probe itself).
  Finder? Function()? part,
});

final List<_Probe> _probes = [
  for (final variant in DkButtonVariant.values)
    (
      name: 'DkButton.${variant.name} (full width)',
      role: 'button',
      fit: _Fit.exact,
      maxWidth: _column,
      build: (l) =>
          DkButton(label: l, variant: variant, expand: true, onPressed: () {}),
      part: null,
    ),
  (
    name: 'DkButton (inline, in a row)',
    role: 'button',
    fit: _Fit.inline,
    maxWidth: _column,
    build: (l) => Row(
      children: [DkButton(label: l, onPressed: () {})],
    ),
    part: () => find.byType(DkButton),
  ),
  (
    name: 'DkDecisionButtons (each button)',
    role: 'decision',
    fit: _Fit.inline,
    maxWidth: _column,
    build: (l) => DkDecisionButtons(
      rejectLabel: l,
      approveLabel: l,
      onReject: () {},
      onApprove: () {},
    ),
    part: () => find.byType(DkButton).first,
  ),
  (
    name: 'DkFab',
    role: 'fab',
    fit: _Fit.inline,
    maxWidth: _screen * dkFabMaxWidthShare,
    build: (l) => Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [DkFab(label: l, icon: DkIcons.add, onPressed: () {})],
    ),
    part: () => find.byType(DkFab),
  ),
  (
    name: 'DkSegmentedControl (3 tabs)',
    role: 'tab',
    fit: _Fit.exact,
    maxWidth: _column,
    build: (l) => DkSegmentedControl<int>(
      segments: [
        DkSegment(value: 0, label: l),
        DkSegment(value: 1, label: l),
        DkSegment(value: 2, label: l),
      ],
      selected: 0,
      onChanged: (_) {},
    ),
    part: null,
  ),
  (
    name: 'DkLanguageSwitch',
    role: 'language',
    fit: _Fit.exact,
    maxWidth: _column,
    build: (l) => DkLanguageSwitch(
      languages: [(code: 'ru', name: l), (code: 'kk', name: l)],
      selected: 'ru',
      onChanged: (_) {},
    ),
    part: null,
  ),
  (
    name: 'DkFilterChips (a chip)',
    role: 'chip',
    fit: _Fit.inline,
    maxWidth: double.infinity, // the row scrolls
    build: (l) => DkFilterChips<int>(
      options: [(value: 0, label: l), (value: 1, label: l)],
      selected: 0,
      onChanged: (_) {},
    ),
    part: () => find.byType(InkWell).first,
  ),
  (
    name: 'DkBadge',
    role: 'badge',
    fit: _Fit.inline,
    maxWidth: 120,
    build: (l) => Row(
      children: [
        SizedBox(
          width: 120,
          child: Row(
            children: [Flexible(child: DkBadge(l, short: '+1'))],
          ),
        ),
      ],
    ),
    part: () => find.byType(DkBadge),
  ),
  (
    name: 'DkStatusChip',
    role: 'status',
    fit: _Fit.inline,
    maxWidth: 140,
    build: (l) => Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 140,
        child: Row(
          children: [
            Flexible(
              child: DkStatusChip(kind: DkStatusKind.pending, label: l),
            ),
          ],
        ),
      ),
    ),
    part: () => find.byType(DkStatusChip),
  ),
  (
    name: 'DkTodayButton (in the header)',
    role: 'today',
    fit: _Fit.inline,
    maxWidth: _column,
    build: (l) => DkWordmark(
      title: 'Дневник смен',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: DkTodayButton(label: l, onPressed: () {}),
          ),
          DkIconButton(icon: DkIcons.menu, label: 'menu', onPressed: () {}),
        ],
      ),
    ),
    part: () => find.byType(DkTodayButton),
  ),
  (
    name: 'DkWordmark (header)',
    role: 'title',
    fit: _Fit.exact,
    maxWidth: _column,
    build: (l) => DkWordmark(
      title: l,
      caption: l,
      trailing: DkIconButton(
        icon: DkIcons.menu,
        label: 'menu',
        onPressed: () {},
      ),
    ),
    part: null,
  ),
  (
    name: 'DkModalAppBar',
    role: 'title',
    fit: _Fit.exact,
    maxWidth: _column,
    build: (l) =>
        DkModalAppBar(title: l, subtitle: l, closeLabel: 'x', onClose: () {}),
    part: null,
  ),
  (
    name: 'DkListRow (one line)',
    role: 'row',
    fit: _Fit.exact,
    maxWidth: _column,
    build: (l) => DkListGroup(
      children: [DkListRow(icon: DkIcons.user, title: l, onTap: () {})],
    ),
    part: null,
  ),
  (
    name: 'DkListRow (two lines, money trailing)',
    role: 'row',
    fit: _Fit.exact,
    maxWidth: _column,
    build: (l) => DkListGroup(
      children: [
        DkListRow(
          icon: DkIcons.user,
          title: l,
          subtitle: l,
          trailing: const DkMoneyText(200327, style: TextStyle(fontSize: 17)),
          onTap: () {},
        ),
      ],
    ),
    part: null,
  ),
  (
    name: 'DkDaySwitcher',
    role: 'title',
    fit: _Fit.exact,
    maxWidth: _column,
    build: (l) => DkDaySwitcher(
      title: l,
      subtitle: l,
      prevLabel: 'p',
      nextLabel: 'n',
      pickLabel: 'd',
      onPrev: () {},
      onPickDate: () {},
    ),
    part: null,
  ),
  (
    name: 'DkTextField (label + «Всё»)',
    role: 'field',
    fit: _Fit.exact,
    maxWidth: _column,
    build: (l) => _Field(label: l),
    part: null,
  ),
  (
    name: 'DkTimeField (+1 badge)',
    role: 'field',
    fit: _Fit.exact,
    maxWidth: 158,
    build: (l) => SizedBox(
      width: 158,
      child: DkTimeField(
        label: l,
        value: '00:20',
        emptyValueLabel: '-',
        trailing: DkBadge(_x3(l), short: '+1'),
        onTap: () {},
      ),
    ),
    part: null,
  ),
  (
    name: 'DkDialogView (each button)',
    role: 'button',
    fit: _Fit.exact,
    maxWidth: _column,
    build: (l) => SizedBox(
      height: 700,
      child: DkDialogView(
        icon: DkIcons.alert,
        title: 't',
        message: 'm',
        primaryLabel: l,
        onPrimary: () {},
        secondaryLabel: l,
        onSecondary: () {},
        popOnAction: false,
      ),
    ),
    part: () => find.byType(DkButton).last,
  ),
  (
    name: 'DkSnackbarView (action)',
    role: 'button',
    fit: _Fit.exact,
    maxWidth: _column,
    build: (l) => DkSnackbarView(
      message: 'Нет связи',
      tone: DkSnackTone.error,
      actionLabel: l,
      onAction: () {},
    ),
    part: null,
  ),
  (
    name: 'DkSummaryTile (payment, «· 38%»)',
    role: 'tile',
    fit: _Fit.exact,
    maxWidth: 150,
    build: (l) => SizedBox(
      width: 150,
      child: DkSummaryTile(
        label: l,
        hint: '38%',
        value: DkMoney.format(3300),
        icon: DkIcons.cash,
      ),
    ),
    part: null,
  ),
  (
    name: 'DkTripTile (meta and driver lines)',
    role: 'meta',
    fit: _Fit.exact,
    maxWidth: _column,
    build: (l) => DkTripTile(
      timeRange: '08:10 – 08:32',
      endsNextDay: true,
      meta: l,
      driver: l,
      amount: DkMoney.format(2400),
      commission: 'комиссия ${DkMoney.format(360)}',
      method: DkPaymentMethod.card,
      nextDayLabel: 'n',
    ),
    part: null,
  ),
  (
    name: 'DkWithdrawalTile (subtitle and chip)',
    role: 'status',
    fit: _Fit.exact,
    maxWidth: _column,
    build: (l) => DkWithdrawalTile(
      amount: 200327,
      prominent: true,
      subtitle: l,
      status: DkStatusChip(kind: DkStatusKind.pending, label: l),
    ),
    part: null,
  ),
];

void main() {
  setUpAll(loadKitFonts);

  for (final (lang, labels) in [('ru', _ru), ('kk', _kk)]) {
    for (final scale in [1.0, 1.15, dkMaxTextScale]) {
      for (final probe in _probes) {
        testWidgets('${probe.name} [$lang] ×$scale: same size with a 3× '
            'longer label', (tester) async {
          tester.view
            ..physicalSize = const Size(_screen, 780)
            ..devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          final pair = labels[probe.role]!;
          final sizes = <Size>[];
          for (final label in [pair.short, _x3(pair.long)]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: DkTheme.light(),
                home: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: _column,
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
            expect(tester.takeException(), isNull, reason: label);
            final part =
                probe.part?.call() ?? find.byKey(const ValueKey('probe'));
            sizes.add(tester.getSize(part));
            _expectOneLine(tester, label);
          }
          final (short, long) = (sizes.first, sizes.last);
          expect(long.height, short.height, reason: 'height: $short → $long');
          switch (probe.fit) {
            case _Fit.exact:
              expect(long.width, short.width, reason: 'width: $short → $long');
            case _Fit.inline:
              expect(long.width, lessThanOrEqualTo(probe.maxWidth + 0.5));
          }
        });
      }
    }
  }
}

/// Every text line under the probe is one line.
void _expectOneLine(WidgetTester tester, String label) {
  for (final paragraph
      in tester.allRenderObjects.whereType<RenderParagraph>().toSet()) {
    if (!paragraph.attached || !paragraph.hasSize) continue;
    final text = paragraph.text.toPlainText();
    // Icons are one private-use glyph.
    if (text.runes.length <= 1) continue;
    // A paragraph with a widget inside cannot be measured again; one line
    // is then the paragraph's own limit.
    var hasWidget = false;
    paragraph.text.visitChildren((span) => !(hasWidget = span is WidgetSpan));
    if (hasWidget) {
      expect(paragraph.maxLines, 1, reason: '«$text» may wrap ($label)');
      continue;
    }
    final painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
      maxLines: paragraph.maxLines,
      ellipsis: paragraph.overflow == TextOverflow.ellipsis ? '…' : null,
    )..layout(maxWidth: paragraph.size.width + 0.01);
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    expect(lines, lessThanOrEqualTo(1), reason: '«$text» wraps ($label)');
  }
}

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
