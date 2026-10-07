import 'package:design_kit/design_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  // `?theme=dark` and `?tab=tokens` (web) for screenshots.
  final query = Uri.base.queryParameters;
  runApp(
    App(
      initialThemeMode: query['theme'] == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light,
      initialTab: query['tab'] == 'tokens' ? 1 : 0,
    ),
  );
}

/// Showcase of every design kit component in every state, light and dark.
class App extends StatefulWidget {
  const new({
    this.initialThemeMode = ThemeMode.light,
    this.initialTab = 0,
    super.key,
  });

  final ThemeMode initialThemeMode;
  final int initialTab;

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
        initialTab: widget.initialTab,
        onToggleTheme: () => setState(() {
          _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
        }),
      ),
    );
  }
}

class ShowcasePage extends StatelessWidget {
  const new({
    required this.isDark,
    required this.onToggleTheme,
    this.initialTab = 0,
    super.key,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const DkWordmark(title: 'Дневник смен · Кит'),
          actions: [
            IconButton(
              tooltip: isDark ? 'Светлая тема' : 'Тёмная тема',
              onPressed: onToggleTheme,
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Компоненты'),
              Tab(text: 'Токены'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: EdgeInsets.all(spacing.screenGutter),
              children: const [
                _Section(title: 'DkButton', child: _ButtonMatrix()),
                _Section(title: 'DkFab', child: _FabDemo()),
                _Section(title: 'DkDaySwitcher', child: _DaySwitchers()),
                _Section(title: 'DkSegmentedControl', child: _Segments()),
                _Section(
                  title: 'DkSummaryCard · DkSummaryTile · DkSplitBar',
                  child: _Summary(),
                ),
                _Section(title: 'DkTripTile · DkTripList', child: _Trips()),
                _Section(title: 'DkSkeleton', child: _Skeletons()),
                _Section(title: 'DkTextField', child: _Fields()),
                _Section(title: 'DkTimeField · DkBadge', child: _TimeFields()),
                _Section(title: 'DkEmptyState', child: _Empty()),
                _Section(title: 'DkErrorState', child: _Error()),
                _Section(title: 'DkSnackbar', child: _Snackbars()),
                _Section(title: 'DkDialog', child: _Dialog()),
                _Section(
                  title: 'DkPickerSheet · DkOptionsSheet',
                  child: _Sheets(),
                ),
                _Section(
                  title: 'DkWordmark · DkModalAppBar · DkBottomBar',
                  child: _Chrome(),
                ),
              ],
            ),
            ListView(
              padding: EdgeInsets.all(spacing.screenGutter),
              children: const [
                _Section(
                  title: '«На руки» · Manrope + fallback ₸ / U+202F',
                  child: HeroMoneySample(),
                ),
                _Section(title: 'Цвета · DkColors', child: _Palette()),
                _Section(
                  title: 'Типографика · DkTypography',
                  child: _TypeScale(),
                ),
                _Section(title: 'Отступы · DkSpacing', child: _SpacingScale()),
                _Section(
                  title: 'Скругления и тени · DkRadii · DkElevation',
                  child: _RadiiAndShadows(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
            style: context.dkText.captionStrong.copyWith(
              color: context.dkColors.textTertiary,
            ),
          ),
          SizedBox(height: context.dkSpacing.s12),
          child,
        ],
      ),
    );
  }
}

/// A caption over a demo, e.g. «disabled».
class _Labeled extends StatelessWidget {
  const new(this.label, this.child);

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.dkSpacing.s6,
      children: [
        Text(
          label,
          style: context.dkText.caption.copyWith(
            color: context.dkColors.textTertiary,
          ),
        ),
        child,
      ],
    );
  }
}

class _ButtonMatrix extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing.s12,
      children: [
        for (final variant in DkButtonVariant.values)
          _Labeled(
            '${variant.name} · enabled / disabled / loading',
            Wrap(
              spacing: spacing.s8,
              runSpacing: spacing.s8,
              children: [
                DkButton(
                  label: variant == DkButtonVariant.primary
                      ? 'Сохранить'
                      : 'Повторить',
                  icon: variant == DkButtonVariant.primary
                      ? null
                      : DkIcons.retry,
                  variant: variant,
                  onPressed: () {},
                ),
                DkButton(
                  label: variant == DkButtonVariant.primary
                      ? 'Сохранить'
                      : 'Повторить',
                  icon: variant == DkButtonVariant.primary
                      ? null
                      : DkIcons.retry,
                  variant: variant,
                ),
                DkButton(
                  label: switch (variant) {
                    DkButtonVariant.primary => 'Сохраняем…',
                    DkButtonVariant.secondary => 'Загружаем…',
                    DkButtonVariant.text => 'Повторяем…',
                  },
                  variant: variant,
                  isLoading: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FabDemo extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: DkFab(label: 'Поездка', icon: DkIcons.add, onPressed: () {}),
  );
}

class _DaySwitchers extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final today = DateTime(2026, 10, 6);
    return Column(
      spacing: context.dkSpacing.s12,
      children: [
        DkDaySwitcher(
          // Explicit day for readability (it equals the default).
          // ignore: avoid_redundant_argument_values
          date: DateTime(2026, 10, 1),
          today: today,
          onPrev: () {},
          onNext: () {},
          onPickDate: () {},
        ),
        DkDaySwitcher(
          date: today,
          today: today,
          onPrev: () {},
          onNext: () {},
          onPickDate: () {},
        ),
      ],
    );
  }
}

class _Segments extends StatefulWidget {
  const new();

  @override
  State<_Segments> createState() => _SegmentsState();
}

class _SegmentsState extends State<_Segments> {
  DkPaymentMethod _method = DkPaymentMethod.cash;

  @override
  Widget build(BuildContext context) {
    final segments = [
      for (final m in DkPaymentMethod.values)
        DkSegment(value: m, label: m.label, icon: m.icon),
    ];
    return Column(
      spacing: context.dkSpacing.s12,
      children: [
        DkSegmentedControl<DkPaymentMethod>(
          label: 'Способ оплаты',
          segments: segments,
          selected: _method,
          onChanged: (value) => setState(() => _method = value),
        ),
        _Labeled(
          'disabled (сохранение)',
          DkSegmentedControl<DkPaymentMethod>(
            segments: segments,
            selected: DkPaymentMethod.card,
            onChanged: null,
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Column(
    spacing: context.dkSpacing.s16,
    children: const [
      DkSummaryCard(net: 3315, revenue: 3900, commission: 585, tripsCount: 2),
      DkPaymentCard(cash: 1500, card: 2400),
      DkPaymentCard(cash: 0, card: 0),
    ],
  );
}

class _Trips extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: context.dkSpacing.s8,
    children: [
      const DkListHeader(title: 'Поездки', trailing: '2 поездки · 55 мин'),
      DkTripList(
        children: [
          DkTripTile(
            timeRange: DkFormat.timeRange('08:10', '08:32'),
            endsNextDay: false,
            meta: '22 мин · Карта',
            amount: DkMoney.format(2400),
            commission: 'комиссия ${DkMoney.format(360)}',
            method: DkPaymentMethod.card,
          ),
          DkTripTile(
            timeRange: DkFormat.timeRange('23:50', '00:20'),
            endsNextDay: true,
            meta: '30 мин · Наличные',
            amount: DkMoney.format(3000),
            commission: 'комиссия ${DkMoney.format(450)}',
            method: DkPaymentMethod.cash,
            highlighted: true,
          ),
        ],
      ),
    ],
  );
}

class _Skeletons extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing.s16,
      children: [
        Row(
          spacing: spacing.s16,
          children: [
            DkSkeleton.line(
              width: spacing.s64 + spacing.s48,
              height: spacing.s12,
            ),
            DkSkeleton.line(width: spacing.s64, height: spacing.s20),
            DkSkeleton.box(size: context.dkSizes.iconTile),
          ],
        ),
        const DkSkeleton.summaryCard(),
        const DkSkeleton.paymentCard(),
        const DkSkeleton.listHeader(),
        const DkTripList(
          children: [DkSkeleton.tripTile(), DkSkeleton.tripTile()],
        ),
      ],
    );
  }
}

class _Fields extends StatefulWidget {
  const new();

  @override
  State<_Fields> createState() => _FieldsState();
}

class _FieldsState extends State<_Fields> {
  final _commission = DkMoneyEditingController(amount: 360);
  final _focused = DkMoneyEditingController(amount: 2400);
  final _error = DkMoneyEditingController(amount: 0);
  final _disabled = DkMoneyEditingController(amount: 2400);

  @override
  void dispose() {
    for (final c in [_commission, _focused, _error, _disabled]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    spacing: context.dkSpacing.s20,
    children: [
      DkTextField.money(
        label: 'Комиссия',
        controller: _commission,
        helper: 'На руки с поездки: ${DkMoney.format(2040)}',
      ),
      DkTextField.money(
        label: 'Сумма',
        controller: _focused,
        helper: 'Сколько заплатил пассажир',
        autofocus: true,
      ),
      DkTextField.money(
        label: 'Сумма',
        controller: _error,
        errorText: 'Сумма должна быть больше 0',
      ),
      DkTextField.money(
        label: 'Сумма',
        controller: _disabled,
        helper: 'Сколько заплатил пассажир',
        enabled: false,
      ),
    ],
  );
}

class _TimeFields extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing.s20,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: spacing.s12,
          children: [
            Expanded(
              child: DkTimeField(label: 'Начало', value: '23:50', onTap: () {}),
            ),
            Expanded(
              child: DkTimeField(
                label: 'Окончание',
                value: '00:20',
                onTap: () {},
                trailing: const DkBadge('+1 день'),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: spacing.s6,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: spacing.s12,
              children: [
                Expanded(
                  child: DkTimeField(
                    label: 'Начало',
                    value: '09:20',
                    onTap: () {},
                  ),
                ),
                Expanded(
                  child: DkTimeField(
                    label: 'Окончание',
                    value: '09:05',
                    onTap: () {},
                    invalid: true,
                  ),
                ),
              ],
            ),
            const DkFieldMessage(
              text: 'Окончание должно быть позже начала',
              isError: true,
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: spacing.s12,
          children: [
            Expanded(
              child: DkTimeField(
                label: 'Начало',
                value: '08:10',
                onTap: () {},
                enabled: false,
              ),
            ),
            Expanded(
              child: DkTimeField(label: 'Окончание', value: null, onTap: () {}),
            ),
          ],
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => DkCard(
    child: DkEmptyState(
      title: 'За этот день поездок нет',
      message:
          'Добавьте поездку — выручка, комиссия и сумма на руки '
          'посчитаются сами.',
      actionLabel: 'Добавить поездку',
      onAction: () {},
    ),
  );
}

class _Error extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Column(
    spacing: context.dkSpacing.s16,
    children: [
      DkCard(
        child: DkErrorState(
          title: 'Не удалось загрузить данные',
          message:
              'Проверьте интернет и попробуйте ещё раз. Сохранённые поездки '
              'никуда не пропадут.',
          onRetry: () {},
        ),
      ),
      DkCard(
        child: DkErrorState(
          title: 'Не удалось загрузить данные',
          onRetry: () {},
          isRetrying: true,
          retryLabel: 'Повторяем…',
        ),
      ),
    ],
  );
}

class _Snackbars extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: context.dkSpacing.s12,
    children: [
      const DkSnackbarView(
        message: 'Поездка добавлена',
        tone: DkSnackTone.success,
      ),
      DkSnackbarView(
        message: 'Нет связи. Повторим отправку — поездка не задвоится.',
        tone: DkSnackTone.error,
        actionLabel: 'Повторить',
        onAction: () {},
      ),
      DkButton(
        label: 'Показать снекбар',
        variant: DkButtonVariant.text,
        onPressed: () => showDkSnackbar(
          context,
          message: 'Поездка добавлена',
          tone: DkSnackTone.success,
        ),
      ),
    ],
  );
}

class _Dialog extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.dkColors.scrim,
      borderRadius: BorderRadius.circular(context.dkRadii.xl),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: context.dkSpacing.s24),
      child: DkDialogView(
        icon: DkIcons.alert,
        title: 'Эта поездка уже сохранена с другими данными',
        message: 'Обновите день, чтобы увидеть сохранённую версию.',
        primaryLabel: 'Оставить сохранённую',
        onPrimary: () {},
        secondaryLabel: 'Сохранить как новую поездку',
        onSecondary: () {},
        popOnAction: false,
      ),
    ),
  );
}

class _Sheets extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final sheet = BoxDecoration(
      color: context.dkColors.surface,
      borderRadius: BorderRadius.circular(context.dkRadii.xl),
      boxShadow: context.dkElevation.e1,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.dkSpacing.s16,
      children: [
        DecoratedBox(
          decoration: sheet,
          child: DkPickerSheet(
            title: 'Начало поездки',
            doneLabel: 'Готово',
            initial: DateTime(2000, 1, 1, 8, 10),
            picker: (value, onChanged) => CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              initialDateTime: value,
              onDateTimeChanged: onChanged,
            ),
          ),
        ),
        DecoratedBox(
          decoration: sheet,
          child: const DkOptionsSheet<int>(
            title: 'Сортировка',
            options: [
              (value: 0, label: 'Сначала ранние'),
              (value: 1, label: 'Сначала поздние'),
              (value: 2, label: 'Сначала дорогие'),
              (value: 3, label: 'Сначала дешёвые'),
            ],
            selected: 0,
          ),
        ),
      ],
    );
  }
}

class _Chrome extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => DkCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.dkSpacing.s16),
          child: const DkWordmark(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.dkSpacing.s16),
          child: DkWordmark(trailing: DkTodayButton(onPressed: () {})),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.dkSpacing.s16),
          child: DkListHeader(
            title: 'Поездки',
            trailing: '15 поездок · 6 ч 20 мин',
            action: DkIconButton(
              icon: DkIcons.sort,
              label: 'Сортировка: сначала ранние',
              onPressed: () {},
            ),
          ),
        ),
        DkModalAppBar(
          title: 'Новая поездка',
          subtitle: '1 октября 2026',
          onClose: () {},
        ),
        DkBottomBar(
          child: DkButton(label: 'Сохранить', expand: true, onPressed: () {}),
        ),
      ],
    ),
  );
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
