import 'package:design_kit/design_kit.dart';

/// All UI text (DESIGN.md §6, plus the §5 helpers). Russian only.
abstract final class S {
  static const appTitle = 'Дневник смен';

  // Day.
  static const tripsTitle = 'Поездки';
  static const addTripFab = 'Поездка';
  static const emptyTitle = 'За этот день поездок нет';
  static const emptyMessage =
      'Добавьте поездку — выручка, комиссия и сумма на руки посчитаются сами.';
  static const emptyAction = 'Добавить поездку';
  static const errorTitle = 'Не удалось загрузить данные';
  static const errorMessage =
      'Проверьте интернет и попробуйте ещё раз. '
      'Сохранённые поездки никуда не пропадут.';
  static const retry = 'Повторить';
  static const saved = 'Поездка добавлена';
  static const pickDateHelp = 'Выберите день';
  static const loading = 'Загрузка';

  /// `2 поездки · 37 мин`.
  static String tripsHeader(int count, Duration total) =>
      '${DkFormat.trips(count)} · ${DkFormat.duration(total)}';

  /// `22 мин · Карта`.
  static String tripMeta(Duration duration, String payment) =>
      '${DkFormat.duration(duration)} · $payment';

  /// `комиссия 360 ₸`.
  static String commissionLine(int amount) =>
      'комиссия ${DkMoney.format(amount)}';

  // Add trip.
  static const formTitle = 'Новая поездка';
  static const start = 'Начало';
  static const end = 'Окончание';
  static const amount = 'Сумма';
  static const commission = 'Комиссия';
  static const payment = 'Способ оплаты';
  static const amountHelper = 'Сколько заплатил пассажир';
  static const nextDayBadge = '+1 день';
  static const save = 'Сохранить';
  static const saving = 'Сохраняем…';
  static const close = 'Закрыть';
  static const startPickerHelp = 'Начало поездки';
  static const endPickerHelp = 'Окончание поездки';

  /// `Длительность: 22 мин`.
  static String durationHelper(Duration duration) =>
      'Длительность: ${DkFormat.duration(duration)}';

  /// `На руки с поездки: 2 040 ₸`.
  static String netHelper(int amount) =>
      'На руки с поездки: ${DkMoney.format(amount)}';

  /// §5.10: `Окончание 1 октября · 30 мин. Поездка попадёт в 30 сентября —
  /// день начала.`
  static String midnightHelper({
    required DateTime endDay,
    required DateTime startDay,
    required Duration duration,
  }) =>
      'Окончание ${DkFormat.dayMonth(endDay)} · '
      '${DkFormat.duration(duration)}. '
      'Поездка попадёт в ${DkFormat.dayMonth(startDay)} — день начала.';

  // Validation (§5.7).
  static const errEndBeforeStart = 'Окончание должно быть позже начала';
  static const errAmount = 'Сумма должна быть больше 0';
  static const errCommissionGtAmount = 'Комиссия не может быть больше суммы';
  static const errCommissionNegative = 'Комиссия не может быть отрицательной';
  static const errRequired = 'Заполните поле';

  // Sending (§5.9, §5.11).
  static const offline = 'Нет связи. Повторим отправку — поездка не задвоится.';
  static const conflictTitle = 'Эта поездка уже сохранена с другими данными';
  static const conflictMessage =
      'Обновите день, чтобы увидеть сохранённую версию.';
  static const conflictKeep = 'Оставить сохранённую';
  static const conflictNew = 'Сохранить как новую поездку';

  // Closing with unsaved input (§5.6 asks for a confirmation but gives no
  // copy; proposed in stage R5, see DECISIONS.md).
  static const discardTitle = 'Закрыть без сохранения?';
  static const discardMessage = 'Введённые данные поездки не сохранятся.';
  static const discardKeep = 'Продолжить ввод';
  static const discardLeave = 'Закрыть';
}
