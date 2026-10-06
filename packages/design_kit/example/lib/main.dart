import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';

void main() {
  // `?theme=dark` (web) opens the dark theme, e.g. for screenshots.
  final dark = Uri.base.queryParameters['theme'] == 'dark';
  runApp(App(initialThemeMode: dark ? ThemeMode.dark : ThemeMode.light));
}

/// Showcase of every design kit component, in light and dark.
class App extends StatefulWidget {
  const new({this.initialThemeMode = ThemeMode.light, super.key});

  final ThemeMode initialThemeMode;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late ThemeMode _mode = widget.initialThemeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Design kit',
      debugShowCheckedModeBanner: false,
      theme: DkTheme.light(),
      darkTheme: DkTheme.dark(),
      themeMode: _mode,
      home: ShowcasePage(
        isDark: _mode == ThemeMode.dark,
        onToggleTheme: () => setState(() {
          _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
        }),
      ),
    );
  }
}

class ShowcasePage extends StatefulWidget {
  const new({required this.isDark, required this.onToggleTheme, super.key});

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> {
  DkPaymentKind _payment = DkPaymentKind.card;
  bool _loading = false;
  int _dayOffset = 0;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design kit'),
        actions: [
          IconButton(
            tooltip: widget.isDark ? 'Светлая тема' : 'Тёмная тема',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(spacing.md),
          children: [
            const _Section(title: 'Цвета', child: _Palette()),
            const _Section(title: 'Типографика', child: _TypeScale()),
            _Section(
              title: 'DkDaySwitcher',
              child: DkDaySwitcher(
                label: _dayLabel(_dayOffset),
                onPrevious: () => setState(() => _dayOffset--),
                onNext: _dayOffset < 0
                    ? () => setState(() => _dayOffset++)
                    : null,
                onPick: () {},
              ),
            ),
            const _Section(title: 'DkSummaryTile · DkCard', child: _Summary()),
            const _Section(title: 'DkTripTile', child: _Trips()),
            _Section(
              title: 'DkButton',
              child: Column(
                spacing: spacing.sm,
                children: [
                  DkButton(
                    label: 'Добавить поездку',
                    icon: Icons.add,
                    onPressed: () {},
                  ),
                  DkButton(
                    label: _loading ? 'Сохраняем' : 'Сохранить (нажми)',
                    isLoading: _loading,
                    onPressed: () async {
                      setState(() => _loading = true);
                      await Future<void>.delayed(const Duration(seconds: 2));
                      if (mounted) setState(() => _loading = false);
                    },
                  ),
                  DkButton(
                    label: 'Отмена',
                    variant: DkButtonVariant.secondary,
                    onPressed: () {},
                  ),
                  DkButton(
                    label: 'Подробнее',
                    variant: DkButtonVariant.text,
                    onPressed: () {},
                  ),
                  const DkButton(label: 'Недоступно', onPressed: null),
                ],
              ),
            ),
            _Section(
              title: 'DkTextField · DkSegmentedControl',
              child: Column(
                spacing: spacing.md,
                children: [
                  const DkTextField(
                    label: 'Начало',
                    hint: '08:10',
                    prefixIcon: Icons.schedule,
                    readOnly: true,
                  ),
                  const DkTextField(
                    label: 'Сумма',
                    hint: '2400',
                    suffixText: '₸',
                    helperText: 'Целое число тенге',
                    keyboardType: TextInputType.number,
                  ),
                  const DkTextField(
                    label: 'Комиссия',
                    suffixText: '₸',
                    errorText: 'Комиссия не может быть больше суммы',
                    keyboardType: TextInputType.number,
                  ),
                  DkSegmentedControl<DkPaymentKind>(
                    label: 'Оплата',
                    segments: [
                      for (final kind in DkPaymentKind.values)
                        DkSegment(
                          value: kind,
                          label: kind.label,
                          icon: kind.icon,
                        ),
                    ],
                    selected: _payment,
                    onChanged: (value) => setState(() => _payment = value),
                  ),
                ],
              ),
            ),
            const _Section(
              title: 'DkSkeleton',
              child: DkCard(child: _SkeletonCard()),
            ),
            _Section(
              title: 'DkEmptyState',
              child: DkCard(
                child: DkEmptyState(
                  title: 'Поездок нет',
                  message: 'За этот день ещё нет поездок.',
                  actionLabel: 'Добавить поездку',
                  onAction: () {},
                ),
              ),
            ),
            _Section(
              title: 'DkErrorState',
              child: DkCard(
                child: DkErrorState(
                  message: 'Проверьте интернет и попробуйте ещё раз.',
                  onRetry: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _dayLabel(int offset) => switch (offset) {
    0 => 'Сегодня, 1 октября',
    -1 => 'Вчера, 30 сентября',
    _ => '${offset.abs()} дн. назад',
  };
}

class _Section extends StatelessWidget {
  const new({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.dkSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: context.dkText.label.copyWith(
              color: context.dkColors.textSecondary,
            ),
          ),
          SizedBox(height: context.dkSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return DkCard(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.lg,
        children: const [
          DkSummaryTile.money(
            label: 'Чистыми',
            amount: 3315,
            icon: Icons.account_balance_wallet_outlined,
            tone: DkTone.positive,
            emphasis: DkSummaryEmphasis.hero,
          ),
          _TileRow(
            left: DkSummaryTile.money(label: 'Выручка', amount: 3900),
            right: DkSummaryTile.money(
              label: 'Комиссия',
              amount: 585,
              isDeduction: true,
            ),
          ),
          _TileRow(
            left: DkSummaryTile.money(
              label: 'Наличные',
              amount: 1500,
              icon: Icons.payments_outlined,
              tone: DkTone.cash,
            ),
            right: DkSummaryTile.money(
              label: 'Карта',
              amount: 2400,
              icon: Icons.credit_card,
              tone: DkTone.card,
            ),
          ),
          DkSummaryTile.count(
            label: 'Поездок',
            count: 2,
            icon: Icons.local_taxi_outlined,
          ),
        ],
      ),
    );
  }
}

class _TileRow extends StatelessWidget {
  const new({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.dkSpacing.md,
      children: [
        Expanded(child: left),
        Expanded(child: right),
      ],
    );
  }
}

class _Trips extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return DkCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          DkTripTile(
            timeRange: '08:10 – 08:32',
            amount: 2400,
            payment: DkPaymentKind.card,
            details: 'комиссия ${DkMoney.format(360)}',
            onTap: () {},
          ),
          const Divider(),
          DkTripTile(
            timeRange: '09:05 – 09:20',
            amount: 1500,
            payment: DkPaymentKind.cash,
            details: 'комиссия ${DkMoney.format(225)}',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: spacing.sm,
      children: [
        DkSkeleton(height: spacing.md, width: spacing.xxl * 2),
        DkSkeleton(height: spacing.xxl, width: spacing.xxl * 4),
        DkSkeleton(height: spacing.lg),
        DkSkeleton(height: spacing.lg),
      ],
    );
  }
}

class _Palette extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.dkColors;
    final swatches = {
      'background': c.background,
      'surface': c.surface,
      'surfaceMuted': c.surfaceMuted,
      'textPrimary': c.textPrimary,
      'textSecondary': c.textSecondary,
      'primary': c.primary,
      'positive': c.positive,
      'cash': c.cash,
      'card': c.card,
      'error': c.error,
      'outline': c.outline,
      'border': c.border,
    };
    return Wrap(
      spacing: context.dkSpacing.xs,
      runSpacing: context.dkSpacing.xs,
      children: [
        for (final MapEntry(key: name, value: color) in swatches.entries)
          _Swatch(name: name, color: color),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const new({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sizes = context.dkSizes;
    return SizedBox(
      width: sizes.controlHeight * 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: sizes.minTouchTarget,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(context.dkRadii.sm),
              border: Border.all(
                color: context.dkColors.border,
                width: sizes.borderWidth,
              ),
            ),
          ),
          SizedBox(height: context.dkSpacing.xxs),
          Text(
            name,
            style: context.dkText.label.copyWith(
              color: context.dkColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeScale extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final t = context.dkText;
    final color = context.dkColors.textPrimary;
    final samples = [
      ('moneyHero 44', t.moneyHero, DkMoney.format(3315)),
      ('moneyLarge 26', t.moneyLarge, DkMoney.format(3900)),
      ('moneyMedium 20', t.moneyMedium, DkMoney.format(2400)),
      ('title 20', t.title, 'Дневник смены'),
      ('titleSmall 17', t.titleSmall, 'Поездки за день'),
      ('body 16', t.body, 'Чистыми за смену после комиссии'),
      ('label 14', t.label, 'Начало · Конец · Сумма'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.dkSpacing.xs,
      children: [
        for (final (name, style, sample) in samples)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: t.label.copyWith(color: context.dkColors.textSecondary),
              ),
              Text(sample, style: style.copyWith(color: color)),
            ],
          ),
      ],
    );
  }
}
