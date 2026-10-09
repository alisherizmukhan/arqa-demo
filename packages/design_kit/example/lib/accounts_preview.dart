// Previews of the DESIGN.md §8 screens (login, menu, withdraw, admin), built
// only from kit components with Russian copy and static data. Stage 4: they are
// not wired to the app; the app builds its screens from the same components in
// stage 5. Copy marked «proposed» is not in §8.7 and waits for approval.

import 'package:design_kit/design_kit.dart';
import 'package:design_kit_example/ru.dart';
import 'package:flutter/material.dart';

/// One screen state.
typedef AccountsPreview = ({String id, String title, WidgetBuilder build});

final _today = DateTime(2026, 10, 9);
const List<({String code, String name})> _languages = [
  (code: 'ru', name: 'Русский'),
  (code: 'kk', name: 'Қазақша'),
];

/// Every state, in review order.
final List<AccountsPreview> accountsPreviews = [
  // §8.1 Login, §8.5 Session ended
  (id: '01_login', title: 'Вход', build: (_) => const _Login()),
  (
    id: '02_login_filled',
    title: 'Вход — заполнено',
    build: (_) => const _Login(login: 'user_1', password: 'password_1'),
  ),
  (
    id: '03_login_wrong_password',
    title: 'Вход — неверный пароль',
    build: (_) => const _Login(
      login: 'user_1',
      password: 'secret',
      error: 'Неверный логин или пароль',
    ),
  ),
  (
    id: '04_login_rate_limited',
    title: 'Вход — слишком много попыток',
    build: (_) => const _Login(
      login: 'user_1',
      password: 'secret',
      error: 'Слишком много попыток. Попробуйте через 15 минут.',
    ),
  ),
  (
    id: '05_login_loading',
    title: 'Вход — входим',
    build: (_) =>
        const _Login(login: 'user_1', password: 'password_1', loading: true),
  ),
  (
    id: '06_login_offline',
    title: 'Вход — нет связи',
    build: (_) => const _Login(
      login: 'user_1',
      password: 'password_1',
      snack: 'Нет связи. Проверьте интернет.',
    ),
  ),
  (
    id: '07_session_ended',
    title: 'Сессия завершена (§8.5)',
    build: (_) => const _Login(snack: 'Сессия завершена. Войдите снова.'),
  ),
  // §8.2 Day header
  (
    id: '08_day_header_menu',
    title: 'День — кнопка меню (§8.2)',
    build: (_) => const _DayHeader(),
  ),
  // §8.3 Menu
  (
    id: '09_menu_driver',
    title: 'Меню — водитель',
    build: (_) => const _Menu(driver: true),
  ),
  (
    id: '10_menu_admin',
    title: 'Меню — администратор',
    build: (_) => const _Menu(driver: false),
  ),
  (
    id: '11_menu_logout_dialog',
    title: 'Меню — выйти?',
    build: (_) => const _Menu(driver: true, logoutDialog: true),
  ),
  // §8.4 Withdraw
  (id: '12_withdraw', title: 'Вывод средств', build: (_) => const _Withdraw()),
  (
    id: '13_withdraw_loading',
    title: 'Вывод — загрузка',
    build: (_) => const _WithdrawLoading(),
  ),
  (
    id: '14_withdraw_empty_history',
    title: 'Вывод — заявок не было',
    build: (_) => const _Withdraw(history: false, withdrawn: 0),
  ),
  (
    id: '15_withdraw_nothing',
    title: 'Вывод — нечего выводить',
    build: (_) => const _Withdraw(
      card: 1000,
      commission: 1300,
      withdrawn: 0,
      history: false,
    ),
  ),
  (
    id: '16_withdraw_too_much',
    title: 'Вывод — больше доступного',
    build: (_) =>
        const _Withdraw(amount: 2000, error: 'Сумма больше доступной'),
  ),
  (
    id: '17_withdraw_zero',
    title: 'Вывод — ноль',
    build: (_) =>
        const _Withdraw(amount: 0, error: 'Сумма должна быть больше 0'),
  ),
  (
    id: '18_withdraw_sending',
    title: 'Вывод — отправляем',
    build: (_) => const _Withdraw(amount: 500, sending: true),
  ),
  (
    id: '19_withdraw_offline',
    title: 'Вывод — нет связи',
    build: (_) => const _Withdraw(amount: 500, offline: true),
  ),
  (
    id: '20_withdraw_created',
    title: 'Вывод — заявка создана',
    build: (_) => const _Withdraw(created: true),
  ),
  (
    id: '21_withdraw_conflict',
    title: 'Вывод — 409',
    build: (_) => const _Withdraw(amount: 400, conflict: true),
  ),
  // §8.6 Admin
  (
    id: '22_admin_trips_all',
    title: 'Админка — поездки, все',
    build: (_) => const _AdminTrips(),
  ),
  (
    id: '23_admin_trips_driver',
    title: 'Админка — поездки, Водитель 2',
    build: (_) => const _AdminTrips(driver: 2),
  ),
  (
    id: '24_admin_withdrawals_pending',
    title: 'Админка — выводы',
    build: (_) => const _AdminWithdrawals(),
  ),
  (
    id: '25_admin_withdrawals_all',
    title: 'Админка — выводы, все',
    build: (_) => const _AdminWithdrawals(all: true),
  ),
  (
    id: '26_admin_approving',
    title: 'Админка — выплачиваем',
    build: (_) => const _AdminWithdrawals(approving: true),
  ),
  (
    id: '27_admin_reject_dialog',
    title: 'Админка — отклонить',
    build: (_) => const _AdminWithdrawals(rejectDialog: true),
  ),
  (
    id: '28_admin_marked_paid',
    title: 'Админка — выплачено',
    build: (_) => const _AdminWithdrawals(markedPaid: true),
  ),
  (
    id: '29_admin_drivers',
    title: 'Админка — водители',
    build: (_) => const _AdminDrivers(),
  ),
  (
    id: '30_admin_driver_sheet',
    title: 'Админка — действия',
    build: (_) => const _AdminDrivers(sheet: true),
  ),
  (
    id: '31_admin_revoke_dialog',
    title: 'Админка — сбросить сессии?',
    build: (_) => const _AdminDrivers(revokeDialog: true),
  ),
  (
    id: '32_admin_loading',
    title: 'Админка — загрузка',
    build: (_) => const _AdminState(kind: 0),
  ),
  (
    id: '33_admin_empty',
    title: 'Админка — нет заявок',
    build: (_) => const _AdminState(kind: 1),
  ),
  (
    id: '34_admin_error',
    title: 'Админка — ошибка',
    build: (_) => const _AdminState(kind: 2),
  ),
];

// --- Building blocks -------------------------------------------------------

/// A phone screen: app bar / header, scrollable body, optional bottom bar and
/// an overlay (snackbar, dialog, sheet) on top.
class _Screen extends StatelessWidget {
  const new({required this.body, this.top, this.bottomBar, this.overlay});

  final Widget body;
  final Widget? top;
  final Widget? bottomBar;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) => Scaffold(
    // The overlay covers the whole screen, status bar included (as a route
    // pushed over the page does); the page itself stays inside the safe area.
    body: Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              ?top,
              Expanded(child: body),
              ?bottomBar,
            ],
          ),
        ),
        ?overlay,
      ],
    ),
  );
}

/// Scrim + dialog card, as `showDkDialog` draws it.
class _DialogOverlay extends StatelessWidget {
  const new({required this.dialog});

  final Widget dialog;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ColoredBox(color: context.dkColors.scrim, child: dialog),
  );
}

/// Scrim + bottom sheet, as `showModalBottomSheet` draws it.
class _SheetOverlay extends StatelessWidget {
  const new({required this.sheet});

  final Widget sheet;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ColoredBox(
      color: context.dkColors.scrim,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: context.dkColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(context.dkRadii.xl),
            ),
          ),
          child: sheet,
        ),
      ),
    ),
  );
}

/// A snackbar at [bottom] (above the bottom bar, or the safe area).
class _SnackOverlay extends StatelessWidget {
  const new({required this.snack, required this.bottom});

  final Widget snack;
  final double bottom;

  @override
  Widget build(BuildContext context) => Positioned(
    left: context.dkSpacing.s16,
    right: context.dkSpacing.s16,
    bottom: bottom,
    child: Material(type: MaterialType.transparency, child: snack),
  );
}

/// Text controllers with initial texts, disposed with the widget.
class _Controllers extends StatefulWidget {
  const new({required this.texts, required this.builder});

  final List<String> texts;
  final Widget Function(
    BuildContext context,
    List<TextEditingController> controllers,
  )
  builder;

  @override
  State<_Controllers> createState() => _ControllersState();
}

class _ControllersState extends State<_Controllers> {
  late final List<TextEditingController> _controllers = [
    for (final text in widget.texts) TextEditingController(text: text),
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controllers);
}

String _money(int amount) => DkMoney.format(amount);

String _dateTime(DateTime moment) =>
    '${Ru.date(moment)}, ${DkFormat.clock(moment.hour, moment.minute)}';

const _shortMonths = [
  'янв.',
  'февр.',
  'мар.',
  'апр.',
  'мая',
  'июн.',
  'июл.',
  'авг.',
  'сент.',
  'окт.',
  'нояб.',
  'дек.',
];

/// Admin rows: «9 окт., 22:34», so «driver · date» fits one line.
String _shortDateTime(DateTime moment) =>
    '${moment.day} ${_shortMonths[moment.month - 1]}, '
    '${DkFormat.clock(moment.hour, moment.minute)}';

// --- §8.1 Login --------------------------------------------------------------

class _Login extends StatelessWidget {
  const new({
    this.login = '',
    this.password = '',
    this.error,
    this.loading = false,
    this.snack,
  });

  final String login;
  final String password;
  final String? error;
  final bool loading;
  final String? snack;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    final colors = context.dkColors;
    return _Controllers(
      texts: [login, password],
      builder: (context, c) => _Screen(
        body: ListView(
          padding: EdgeInsets.all(spacing.s16),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 200,
                child: DkLanguageSwitch(
                  languages: _languages,
                  selected: 'ru',
                  onChanged: (_) {},
                ),
              ),
            ),
            SizedBox(height: spacing.s64),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const DkWordmark(title: 'Дневник смен'),
                    SizedBox(height: spacing.s32),
                    Text(
                      'Вход',
                      style: context.dkText.titleL.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: spacing.s24),
                    DkTextField(
                      label: 'Логин',
                      controller: c[0],
                      enabled: !loading,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: spacing.s16),
                    DkPasswordField(
                      label: 'Пароль',
                      controller: c[1],
                      showLabel: 'Показать пароль',
                      hideLabel: 'Скрыть пароль',
                      enabled: !loading,
                      errorText: error,
                      textInputAction: TextInputAction.done,
                    ),
                    SizedBox(height: spacing.s24),
                    DkButton(
                      label: loading ? 'Входим…' : 'Войти',
                      expand: true,
                      isLoading: loading,
                      onPressed: login.isEmpty || password.isEmpty
                          ? null
                          : () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        overlay: switch (snack) {
          final message? => _SnackOverlay(
            bottom: MediaQuery.paddingOf(context).bottom + spacing.s16,
            snack: DkSnackbarView(message: message, tone: DkSnackTone.error),
          ),
          null => null,
        },
      ),
    );
  }
}

// --- §8.2 Day header ---------------------------------------------------------

class _DayHeader extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return _Screen(
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: spacing.screenGutter),
        children: [
          DkWordmark(
            title: 'Дневник смен',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DkTodayButton(label: 'Сегодня', onPressed: () {}),
                DkIconButton(
                  icon: DkIcons.menu,
                  label: 'Меню',
                  onPressed: () {},
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.s8),
          RuDaySwitcher(
            date: DateTime(2026, 10),
            today: _today,
            onPrev: () {},
            onNext: () {},
            onPickDate: () {},
          ),
          SizedBox(height: spacing.s16),
          const DkSummaryCard(
            netLabel: 'На руки',
            revenueLabel: 'Выручка',
            commissionLabel: 'Комиссия',
            tripsLabel: 'Поездок',
            net: 3315,
            revenue: 3900,
            commission: 585,
            tripsCount: 2,
          ),
          SizedBox(height: spacing.s16),
          const DkPaymentCard(
            cashLabel: 'Наличные',
            cardLabel: 'Карта',
            cash: 1500,
            card: 2400,
          ),
        ],
      ),
    );
  }
}

// --- §8.3 Menu ---------------------------------------------------------------

class _Menu extends StatelessWidget {
  const new({required this.driver, this.logoutDialog = false});

  final bool driver;
  final bool logoutDialog;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    final colors = context.dkColors;
    return _Screen(
      top: DkModalAppBar(
        title: 'Меню',
        leadingIcon: DkIcons.previous,
        closeLabel: 'Назад',
        onClose: () {},
      ),
      body: ListView(
        padding: EdgeInsets.all(spacing.s16),
        children: [
          DkProfileCard(
            name: driver ? 'Водитель 1' : 'Администратор',
            caption: driver ? '@user_1 · Водитель' : '@admin · Администратор',
          ),
          SizedBox(height: spacing.s16),
          DkListGroup(
            children: [
              if (driver)
                DkListRow(
                  icon: DkIcons.wallet,
                  title: 'Вывод средств',
                  subtitle: 'Доступно ${_money(1815)}',
                  onTap: () {},
                ),
              const DkListRow(icon: DkIcons.languages, title: 'Язык'),
              DkListAttachment(
                child: DkLanguageSwitch(
                  languages: _languages,
                  selected: 'ru',
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.s16),
          DkListGroup(
            children: [
              DkListRow(
                icon: DkIcons.logOut,
                title: 'Выйти',
                destructive: true,
                onTap: () {},
              ),
            ],
          ),
          SizedBox(height: spacing.s24),
          Text(
            'Версия 0.2.0',
            textAlign: TextAlign.center,
            style: context.dkText.caption.copyWith(color: colors.textTertiary),
          ),
        ],
      ),
      overlay: logoutDialog
          ? _DialogOverlay(
              dialog: DkDialogView(
                icon: DkIcons.logOut,
                title: 'Выйти из аккаунта?',
                message:
                    'Чтобы снова увидеть поездки, нужно будет войти '
                    'по логину и паролю.',
                primaryLabel: 'Выйти',
                onPrimary: () {},
                secondaryLabel: 'Отмена',
                onSecondary: () {},
                popOnAction: false,
              ),
            )
          : null,
    );
  }
}

// --- §8.4 Withdraw -----------------------------------------------------------

class _Withdraw extends StatelessWidget {
  const new({
    this.card = 2400,
    this.commission = 585,
    this.withdrawn = 1000,
    this.history = true,
    this.amount,
    this.error,
    this.sending = false,
    this.offline = false,
    this.created = false,
    this.conflict = false,
  });

  final int card;
  final int commission;
  final int withdrawn;
  final bool history;
  final int? amount;
  final String? error;
  final bool sending;
  final bool offline;
  final bool created;
  final bool conflict;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    final colors = context.dkColors;
    final available = (created
        ? card - commission - withdrawn - 300
        : card - commission - withdrawn);
    final nothing = available <= 0;
    final controller = DkMoneyEditingController(amount: amount);
    final rows = <Widget>[
      if (created)
        DkWithdrawalTile(
          highlighted: true,
          amount: 300,
          subtitle: _dateTime(DateTime(2026, 10, 9, 14, 20)),
          status: const DkStatusChip(
            kind: DkStatusKind.pending,
            label: 'В обработке',
          ),
        ),
      DkWithdrawalTile(
        amount: 400,
        subtitle: _dateTime(DateTime(2026, 10, 8, 18, 5)),
        status: const DkStatusChip(
          kind: DkStatusKind.pending,
          label: 'В обработке',
        ),
      ),
      DkWithdrawalTile(
        amount: 500,
        subtitle: _dateTime(DateTime(2026, 10, 6, 9, 40)),
        note: 'Неверные реквизиты',
        status: const DkStatusChip(
          kind: DkStatusKind.rejected,
          label: 'Отклонено',
        ),
      ),
      DkWithdrawalTile(
        amount: 600,
        subtitle: _dateTime(DateTime(2026, 10, 5, 14, 20)),
        status: const DkStatusChip(kind: DkStatusKind.paid, label: 'Выплачено'),
      ),
    ];
    final barKey = GlobalKey();
    return _Screen(
      top: DkModalAppBar(
        title: 'Вывод средств',
        leadingIcon: DkIcons.previous,
        closeLabel: 'Назад',
        onClose: () {},
      ),
      body: ListView(
        padding: EdgeInsets.all(spacing.s16),
        children: [
          DkBalanceCard(
            label: 'Доступно к выводу',
            amount: available,
            tiles: [
              (label: 'Безнал', amount: card, deduction: false),
              (label: 'Комиссия', amount: commission, deduction: true),
              (
                label: 'Выведено',
                amount: created ? withdrawn + 300 : withdrawn,
                deduction: true,
              ),
            ],
          ),
          SizedBox(height: spacing.s8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.s4),
            child: Text(
              'Наличные остаются у вас, поэтому комиссия за них '
              'тоже списывается с безнала.',
              style: context.dkText.caption.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ),
          SizedBox(height: spacing.s16),
          if (nothing)
            const DkInfoRow(text: 'Сейчас нечего выводить.')
          else
            DkTextField.money(
              label: 'Сумма вывода',
              controller: controller,
              enabled: !sending,
              helper: 'Не больше ${_money(available)}',
              errorText: error,
              trailing: DkButton(
                label: 'Всё',
                variant: DkButtonVariant.text,
                onPressed: sending ? null : () {},
              ),
            ),
          SizedBox(height: spacing.s24),
          const DkListHeader(title: 'История'),
          SizedBox(height: spacing.s8),
          if (history)
            DkTripList(children: rows)
          else
            DkCard(
              child: Text(
                'Заявок на вывод пока не было.',
                style: context.dkText.bodyS.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
        ],
      ),
      bottomBar: DkBottomBar(
        key: barKey,
        child: DkButton(
          label: sending ? 'Отправляем…' : 'Вывести',
          expand: true,
          isLoading: sending,
          onPressed: nothing || error != null || (amount ?? 0) <= 0
              ? null
              : () {},
        ),
      ),
      overlay: switch ((offline, created, conflict)) {
        (true, _, _) => _SnackOverlay(
          bottom: MediaQuery.paddingOf(context).bottom + 100,
          snack: DkSnackbarView(
            message: 'Нет связи. Повторим запрос — деньги не уйдут дважды.',
            tone: DkSnackTone.error,
            actionLabel: 'Повторить',
            onAction: () {},
          ),
        ),
        (_, true, _) => _SnackOverlay(
          bottom: MediaQuery.paddingOf(context).bottom + 100,
          snack: const Align(
            alignment: Alignment.centerLeft,
            child: DkSnackbarView(
              message: 'Заявка на вывод создана',
              tone: DkSnackTone.success,
            ),
          ),
        ),
        (_, _, true) => _DialogOverlay(
          dialog: DkDialogView(
            icon: DkIcons.alert,
            title: 'Эта заявка уже отправлена с другой суммой',
            message:
                'История обновлена: там видна сохранённая заявка.', // proposed
            primaryLabel: 'Понятно',
            onPrimary: () {},
            popOnAction: false,
          ),
        ),
        _ => null,
      },
    );
  }
}

class _WithdrawLoading extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return _Screen(
      top: DkModalAppBar(
        title: 'Вывод средств',
        leadingIcon: DkIcons.previous,
        closeLabel: 'Назад',
        onClose: () {},
      ),
      body: ListView(
        padding: EdgeInsets.all(spacing.s16),
        children: [
          const DkSkeleton.summaryCard(),
          SizedBox(height: spacing.s24),
          const DkSkeleton.listHeader(),
          SizedBox(height: spacing.s8),
          const DkTripList(
            children: [
              DkSkeleton.tripTile(),
              DkSkeleton.tripTile(),
              DkSkeleton.tripTile(),
            ],
          ),
        ],
      ),
      bottomBar: const DkBottomBar(
        child: DkButton(label: 'Вывести', expand: true),
      ),
    );
  }
}

// --- §8.6 Admin --------------------------------------------------------------

enum _AdminTab { trips, withdrawals, drivers }

class _AdminScaffold extends StatelessWidget {
  const new({required this.tab, required this.children, this.overlay});

  final _AdminTab tab;
  final List<Widget> children;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return _Screen(
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          spacing.screenGutter,
          0,
          spacing.screenGutter,
          spacing.s24,
        ),
        children: [
          DkWordmark(
            title: 'Дневник смен',
            caption: 'Администратор',
            trailing: DkIconButton(
              icon: DkIcons.menu,
              label: 'Меню',
              onPressed: () {},
            ),
          ),
          SizedBox(height: spacing.s8),
          DkSegmentedControl<_AdminTab>(
            segments: const [
              DkSegment(value: _AdminTab.trips, label: 'Поездки'),
              DkSegment(value: _AdminTab.withdrawals, label: 'Выводы'),
              DkSegment(value: _AdminTab.drivers, label: 'Водители'),
            ],
            selected: tab,
            onChanged: (_) {},
          ),
          SizedBox(height: spacing.s8),
          ...children,
        ],
      ),
      overlay: overlay,
    );
  }
}

const List<({int value, String label})> _driverChips = [
  (value: 0, label: 'Все водители'),
  (value: 1, label: 'Водитель 1'),
  (value: 2, label: 'Водитель 2'),
];

class _AdminTrips extends StatelessWidget {
  const new({this.driver = 0});

  final int driver;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    final trips = [
      ('08:10 – 08:32', '22 мин · Карта', 2400, 360, DkPaymentMethod.card, 1),
      (
        '09:05 – 09:20',
        '15 мин · Наличные',
        1500,
        225,
        DkPaymentMethod.cash,
        1,
      ),
      ('10:00 – 10:40', '40 мин · Карта', 3000, 450, DkPaymentMethod.card, 2),
      (
        '12:15 – 12:35',
        '20 мин · Наличные',
        1800,
        270,
        DkPaymentMethod.cash,
        2,
      ),
    ].where((t) => driver == 0 || t.$6 == driver).toList();
    final (net, revenue, commission, cash, card) = switch (driver) {
      1 => (3315, 3900, 585, 1500, 2400),
      2 => (4080, 4800, 720, 1800, 3000),
      _ => (7395, 8700, 1305, 3300, 5400),
    };
    return _AdminScaffold(
      tab: _AdminTab.trips,
      children: [
        DkFilterChips<int>(
          options: _driverChips,
          selected: driver,
          onChanged: (_) {},
        ),
        SizedBox(height: spacing.s8),
        RuDaySwitcher(
          date: DateTime(2026, 10),
          today: _today,
          onPrev: () {},
          onNext: () {},
          onPickDate: () {},
        ),
        SizedBox(height: spacing.s16),
        DkSummaryCard(
          netLabel: 'На руки',
          revenueLabel: 'Выручка',
          commissionLabel: 'Комиссия',
          tripsLabel: 'Поездок',
          net: net,
          revenue: revenue,
          commission: commission,
          tripsCount: trips.length,
        ),
        SizedBox(height: spacing.s16),
        DkPaymentCard(
          cashLabel: 'Наличные',
          cardLabel: 'Карта',
          cash: cash,
          card: card,
        ),
        SizedBox(height: spacing.s16),
        DkListHeader(
          title: 'Поездки',
          trailing:
              '${trips.length} поездки · ${driver == 0
                  ? '1 ч 37 мин'
                  : driver == 1
                  ? '37 мин'
                  : '1 ч'}',
        ),
        SizedBox(height: spacing.s8),
        DkTripList(
          children: [
            for (final t in trips)
              DkTripTile(
                nextDayLabel: 'следующий день',
                timeRange: t.$1,
                endsNextDay: false,
                meta: t.$2,
                driver: driver == 0 ? 'Водитель ${t.$6}' : null,
                amount: _money(t.$3),
                commission: 'комиссия ${_money(t.$4)}',
                method: t.$5,
              ),
          ],
        ),
      ],
    );
  }
}

class _AdminWithdrawals extends StatelessWidget {
  const new({
    this.all = false,
    this.approving = false,
    this.rejectDialog = false,
    this.markedPaid = false,
  });

  final bool all;
  final bool approving;
  final bool rejectDialog;
  final bool markedPaid;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    Widget pending(
      String driver,
      int amount,
      DateTime at, {
      bool busy = false,
    }) => DkWithdrawalTile(
      prominent: true,
      amount: amount,
      subtitle: '$driver · ${_shortDateTime(at)}',
      status: const DkStatusChip(
        kind: DkStatusKind.pending,
        label: 'В обработке',
      ),
      actions: DkDecisionButtons(
        rejectLabel: 'Отклонить',
        approveLabel: 'Выплатить',
        approving: busy,
        onReject: () {},
        onApprove: () {},
      ),
    );
    final rows = <Widget>[
      if (!markedPaid)
        pending(
          'Водитель 2',
          1000,
          DateTime(2026, 10, 9, 22, 34),
          busy: approving,
        ),
      pending('Водитель 1', 500, DateTime(2026, 10, 9, 12, 10)),
      if (all || markedPaid)
        DkWithdrawalTile(
          prominent: true,
          amount: 1000,
          subtitle:
              'Водитель 2 · ${_shortDateTime(DateTime(2026, 10, 9, 22, 34))}',
          status: const DkStatusChip(
            kind: DkStatusKind.paid,
            label: 'Выплачено',
          ),
        ),
      if (all)
        DkWithdrawalTile(
          prominent: true,
          amount: 800,
          subtitle: 'Водитель 1 · ${_shortDateTime(DateTime(2026, 10, 7, 16))}',
          status: const DkStatusChip(
            kind: DkStatusKind.rejected,
            label: 'Отклонено',
          ),
        ),
    ];
    return _Controllers(
      texts: const [''],
      builder: (context, c) => _AdminScaffold(
        tab: _AdminTab.withdrawals,
        overlay: switch ((rejectDialog, markedPaid)) {
          (true, _) => _DialogOverlay(
            dialog: DkDialogView(
              icon: DkIcons.rejected,
              // proposed: §8.7 has no title for this dialog
              title: 'Отклонить заявку на ${_money(1000)}?',
              message: 'Водитель 2 увидит причину в истории выводов.',
              content: DkTextField(label: 'Причина', controller: c[0]),
              primaryLabel: 'Отклонить',
              primaryEnabled: false,
              onPrimary: () {},
              secondaryLabel: 'Отмена',
              onSecondary: () {},
              popOnAction: false,
            ),
          ),
          (_, true) => _SnackOverlay(
            bottom: MediaQuery.paddingOf(context).bottom + spacing.s16,
            snack: const Align(
              alignment: Alignment.centerLeft,
              child: DkSnackbarView(
                message: 'Отмечено как выплачено',
                tone: DkSnackTone.success,
              ),
            ),
          ),
          _ => null,
        },
        children: [
          DkFilterChips<bool>(
            options: const [
              (value: false, label: 'В обработке'),
              (value: true, label: 'Все'),
            ],
            selected: all,
            onChanged: (_) {},
          ),
          SizedBox(height: spacing.s8),
          DkTripList(children: rows),
        ],
      ),
    );
  }
}

class _AdminDrivers extends StatelessWidget {
  const new({this.sheet = false, this.revokeDialog = false});

  final bool sheet;
  final bool revokeDialog;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    Widget balance(int amount) => DkGroupedText(
      _money(amount),
      style: context.dkText.moneyM.copyWith(color: colors.textPrimary),
    );
    return _AdminScaffold(
      tab: _AdminTab.drivers,
      overlay: switch ((sheet, revokeDialog)) {
        (true, _) => _SheetOverlay(
          sheet: DkActionSheet(
            title: 'Водитель 2',
            subtitle: '@user_2',
            popOnAction: false,
            actions: [
              (
                icon: DkIcons.block,
                label: 'Заблокировать',
                destructive: true,
                onTap: () {},
              ),
              (
                icon: DkIcons.signOutEverywhere,
                label: 'Сбросить все сессии',
                destructive: false,
                onTap: () {},
              ),
            ],
          ),
        ),
        (_, true) => _DialogOverlay(
          dialog: DkDialogView(
            icon: DkIcons.signOutEverywhere,
            title: 'Сбросить все сессии?', // proposed title
            message: 'Водитель выйдет на всех устройствах',
            primaryLabel: 'Сбросить',
            onPrimary: () {},
            secondaryLabel: 'Отмена',
            onSecondary: () {},
            popOnAction: false,
          ),
        ),
        _ => null,
      },
      children: [
        DkListGroup(
          children: [
            DkListRow(
              icon: DkIcons.user,
              title: 'Водитель 1',
              subtitle: '@user_1',
              trailing: balance(200327),
              onTap: () {},
            ),
            DkListRow(
              icon: DkIcons.user,
              title: 'Водитель 2',
              subtitle: '@user_2',
              trailing: balance(2280),
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminState extends StatelessWidget {
  const new({required this.kind});

  /// 0 loading, 1 empty, 2 error.
  final int kind;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return _AdminScaffold(
      tab: kind == 0 ? _AdminTab.trips : _AdminTab.withdrawals,
      children: switch (kind) {
        0 => [
          const DkSkeleton.summaryCard(),
          SizedBox(height: spacing.s16),
          const DkSkeleton.paymentCard(),
          SizedBox(height: spacing.s16),
          const DkTripList(
            children: [DkSkeleton.tripTile(), DkSkeleton.tripTile()],
          ),
        ],
        1 => [
          DkFilterChips<bool>(
            options: const [
              (value: false, label: 'В обработке'),
              (value: true, label: 'Все'),
            ],
            selected: false,
            onChanged: (_) {},
          ),
          SizedBox(height: spacing.s64),
          // proposed copy
          const DkEmptyState(
            title: 'Заявок нет',
            message: 'Новые заявки на вывод появятся здесь.',
          ),
        ],
        _ => [
          SizedBox(height: spacing.s64),
          DkErrorState(
            retryLabel: 'Повторить',
            title: 'Не удалось загрузить',
            message: 'Проверьте интернет и попробуйте ещё раз.',
            onRetry: () {},
          ),
        ],
      },
    );
  }
}

/// The «Аккаунты» tab of the showcase: every preview, tap to open full screen.
class AccountsPreviewList extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(context.dkSpacing.screenGutter),
    children: [
      DkListGroup(
        children: [
          for (final preview in accountsPreviews)
            DkListRow(
              title: preview.title,
              subtitle: preview.id,
              onTap: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: preview.build)),
            ),
        ],
      ),
    ],
  );
}
