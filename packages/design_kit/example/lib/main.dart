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
          padding: EdgeInsets.all(spacing.s16),
          children: [
            const _Section(
              title: '«На руки» · Manrope + fallback ₸ / U+202F',
              child: HeroMoneySample(),
            ),
            const _Section(title: 'Цвета · DkColors', child: _Palette()),
            const _Section(
              title: 'Типографика · DkTypography',
              child: _TypeScale(),
            ),
            const _Section(
              title: 'Отступы · DkSpacing',
              child: _SpacingScale(),
            ),
            const _Section(
              title: 'Скругления и тени · DkRadii · DkElevation',
              child: _RadiiAndShadows(),
            ),
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
                spacing: spacing.s12,
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
                spacing: spacing.s16,
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
      padding: EdgeInsets.only(bottom: context.dkSpacing.s32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: context.dkText.label.copyWith(
              color: context.dkColors.textSecondary,
            ),
          ),
          SizedBox(height: context.dkSpacing.s12),
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
      padding: EdgeInsets.all(spacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.s24,
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
      spacing: context.dkSpacing.s16,
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
      spacing: spacing.s12,
      children: [
        DkSkeleton(height: spacing.s16, width: spacing.s48 * 2),
        DkSkeleton(height: spacing.s48, width: spacing.s48 * 4),
        DkSkeleton(height: spacing.s24),
        DkSkeleton(height: spacing.s24),
      ],
    );
  }
}

class _Palette extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    const light = DkColors.light;
    const dark = DkColors.dark;
    final rows = <(String, Color, Color)>[
      ('bg', light.bg, dark.bg),
      ('surface', light.surface, dark.surface),
      ('surfaceMuted', light.surfaceMuted, dark.surfaceMuted),
      ('segmentTrack', light.segmentTrack, dark.segmentTrack),
      ('segmentThumb', light.segmentThumb, dark.segmentThumb),
      ('border', light.border, dark.border),
      ('divider', light.divider, dark.divider),
      ('textPrimary', light.textPrimary, dark.textPrimary),
      ('textSecondary', light.textSecondary, dark.textSecondary),
      ('textTertiary', light.textTertiary, dark.textTertiary),
      ('textDisabled', light.textDisabled, dark.textDisabled),
      ('iconDisabled', light.iconDisabled, dark.iconDisabled),
      ('accent', light.accent, dark.accent),
      ('onAccent', light.onAccent, dark.onAccent),
      ('accentSoft', light.accentSoft, dark.accentSoft),
      ('success', light.success, dark.success),
      ('successSoft', light.successSoft, dark.successSoft),
      ('error', light.error, dark.error),
      ('errorSoft', light.errorSoft, dark.errorSoft),
      ('inverseSurface', light.inverseSurface, dark.inverseSurface),
      ('onInverse', light.onInverse, dark.onInverse),
      ('inverseAccent', light.inverseAccent, dark.inverseAccent),
      ('inverseError', light.inverseError, dark.inverseError),
      ('inverseSuccess', light.inverseSuccess, dark.inverseSuccess),
      ('skeleton', light.skeleton, dark.skeleton),
      ('splitNeutral', light.splitNeutral, dark.splitNeutral),
      ('disabledFill', light.disabledFill, dark.disabledFill),
      ('scrim', light.scrim, dark.scrim),
    ];
    return DkCard(
      child: Column(
        spacing: context.dkSpacing.s8,
        children: [
          const _TableHeader(['Токен', 'Светлая', 'Тёмная']),
          for (final (name, l, d) in rows)
            Row(
              children: [
                Expanded(child: _Mono(name)),
                Expanded(child: _Swatch(color: l)),
                Expanded(child: _Swatch(color: d)),
              ],
            ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const new(this.titles);

  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final title in titles)
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: context.dkText.captionStrong.copyWith(
                color: context.dkColors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}

class _Mono extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.dkText.captionStrong.copyWith(
        color: context.dkColors.textPrimary,
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const new({required this.color});

  final Color color;

  static String hex(Color c) {
    final argb = c.toARGB32();
    final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final alpha = (argb >>> 24).toRadixString(16).padLeft(2, '0');
    final suffix = alpha == 'ff' ? '' : alpha;
    return '#$rgb$suffix'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.dkSizes;
    return Row(
      spacing: context.dkSpacing.s8,
      children: [
        Container(
          width: sizes.iconAction,
          height: sizes.iconAction,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(context.dkRadii.xs),
            border: Border.all(
              color: context.dkColors.divider,
              width: sizes.fieldBorder,
            ),
          ),
        ),
        Flexible(
          child: Text(
            hex(color),
            style: context.dkText.caption.copyWith(
              color: context.dkColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeScale extends StatelessWidget {
  const new();

  static const _specs = {
    'moneyHero': '44/48 · w800 · −2%',
    'moneyHeroSuffix': '32/48 · w700 · −2%',
    'titleL': '22/28 · w800 · −1%',
    'moneyL': '22/28 · w700',
    'wordmark': '20/28 · w800 · −2%',
    'titleDialog': '20/28 · w800 · −1%',
    'fieldTime': '18/24 · w700',
    'titleM': '17/24 · w700',
    'moneyM': '17/24 · w700',
    'bodyStrong': '16/24 · w700',
    'body': '16/24 · w500',
    'bodyMd': '15/22 · w500',
    'bodyS': '14/20 · w500',
    'label': '14/20 · w600',
    'captionStrong': '13/16 · w600',
    'caption': '13/16 · w500',
    'badge': '12/24 · w700',
    'superscript': '11/14 · w800',
  };

  static const _samples = {
    'moneyHero': '3 315',
    'moneyHeroSuffix': '₸',
    'titleL': 'За этот день поездок нет',
    'moneyL': '2 400 ₸',
    'wordmark': 'Дневник смен',
    'titleDialog': 'Эта поездка уже сохранена',
    'fieldTime': '08:10',
    'titleM': '1 октября 2026',
    'moneyM': '3 900 ₸',
    'bodyStrong': '08:10 – 08:32 · Сохранить',
    'body': 'Проверьте интернет и попробуйте ещё раз.',
    'bodyMd': 'Первая отправка дошла до сервера',
    'bodyS': '22 мин · Карта',
    'label': 'Сумма',
    'captionStrong': 'Выручка · Сумма должна быть больше 0',
    'caption': 'комиссия 360 ₸',
    'badge': '+1 день',
    'superscript': '+1',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    return DkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: context.dkSpacing.s16,
        children: [
          for (final MapEntry(key: name, value: style)
              in context.dkText.all.entries)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: context.dkSpacing.s4,
              children: [
                Wrap(
                  spacing: context.dkSpacing.s8,
                  children: [
                    _Mono(name),
                    Text(
                      '${_specs[name]} · tnum',
                      style: context.dkText.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
                Text(
                  _samples[name]!,
                  style: style.copyWith(
                    color: name == 'moneyHero' || name == 'superscript'
                        ? colors.accent
                        : colors.textPrimary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The «На руки» hero: number and `₸` as separate spans joined by U+202F.
/// `₸` and U+202F come from the bundled IBM Plex Sans fallback.
class HeroMoneySample extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.dkText;
    final accent = context.dkColors.accent;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '3 315 ',
            style: text.moneyHero.copyWith(color: accent),
          ),
          TextSpan(
            text: '₸',
            style: text.moneyHeroSuffix.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class _SpacingScale extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final s = context.dkSpacing;
    final steps = {
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
    return DkCard(
      child: Column(
        spacing: s.s8,
        children: [
          for (final MapEntry(key: name, :value) in steps.entries)
            Row(
              spacing: s.s12,
              children: [
                SizedBox(
                  width: s.s64 + s.s32,
                  child: _Mono('$name · ${value.toInt()}'),
                ),
                Container(
                  width: value,
                  height: s.s12,
                  decoration: BoxDecoration(
                    color: context.dkColors.accent,
                    borderRadius: BorderRadius.circular(context.dkRadii.xs),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RadiiAndShadows extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final r = context.dkRadii;
    final e = context.dkElevation;
    final s = context.dkSpacing;
    final colors = context.dkColors;
    final radii = {
      'xs · 4': r.xs,
      'sm · 8': r.sm,
      'segment · 10': r.segment,
      'md · 12': r.md,
      'segmentTrack · 14': r.segmentTrack,
      'lg · 16': r.lg,
      'xl · 24': r.xl,
      'pill': r.pill,
    };
    final shadows = {
      'e1': e.e1,
      'e1Hero': e.e1Hero,
      'e2Fab': e.e2Fab,
      'e3': e.e3,
      'thumb': e.thumb,
    };
    Widget box(String label, BoxDecoration decoration) => Column(
      spacing: s.s6,
      children: [
        Container(width: s.s64, height: s.s48, decoration: decoration),
        _Mono(label),
      ],
    );
    return DkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: s.s20,
        children: [
          Wrap(
            spacing: s.s16,
            runSpacing: s.s16,
            children: [
              for (final MapEntry(key: label, value: radius) in radii.entries)
                box(
                  label,
                  BoxDecoration(
                    color: colors.accentSoft,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: colors.accent,
                      width: context.dkSizes.fieldBorderFocused,
                    ),
                  ),
                ),
            ],
          ),
          Wrap(
            spacing: s.s16,
            runSpacing: s.s16,
            children: [
              for (final MapEntry(key: label, value: shadow) in shadows.entries)
                box(
                  label,
                  BoxDecoration(
                    color: label == 'e2Fab' ? colors.accent : colors.surface,
                    borderRadius: BorderRadius.circular(r.lg),
                    boxShadow: shadow,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
