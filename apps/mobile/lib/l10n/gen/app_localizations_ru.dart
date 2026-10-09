// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Дневник смен';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageKk => 'Қазақша';

  @override
  String get retry => 'Повторить';

  @override
  String get loading => 'Загрузка';

  @override
  String get close => 'Закрыть';

  @override
  String get back => 'Назад';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'Понятно';

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String get menu => 'Меню';

  @override
  String moneySpoken(String amount) {
    return '$amount тенге';
  }

  @override
  String get errorGeneric => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get errorServerUnavailable =>
      'Сервер временно недоступен. Попробуйте чуть позже.';

  @override
  String get errorForbidden => 'Недостаточно прав для этого действия.';

  @override
  String get loadFailedTitle => 'Не удалось загрузить';

  @override
  String get loadFailedMessage => 'Проверьте интернет и попробуйте ещё раз.';

  @override
  String get tripsTitle => 'Поездки';

  @override
  String get sortTitle => 'Сортировка';

  @override
  String sortButton(String order) {
    return 'Сортировка: $order';
  }

  @override
  String get orderTimeAscending => 'Сначала ранние';

  @override
  String get orderTimeDescending => 'Сначала поздние';

  @override
  String get orderAmountDescending => 'Сначала дорогие';

  @override
  String get orderAmountAscending => 'Сначала дешёвые';

  @override
  String get addTripFab => 'Поездка';

  @override
  String get emptyTitle => 'За этот день поездок нет';

  @override
  String get emptyMessage =>
      'Добавьте поездку — выручка, комиссия и сумма на руки посчитаются сами.';

  @override
  String get emptyAction => 'Добавить поездку';

  @override
  String get errorTitle => 'Не удалось загрузить данные';

  @override
  String get errorMessage =>
      'Проверьте интернет и попробуйте ещё раз. Сохранённые поездки никуда не пропадут.';

  @override
  String get saved => 'Поездка добавлена';

  @override
  String get pickDateHelp => 'Выберите день';

  @override
  String get prevDay => 'Предыдущий день';

  @override
  String get nextDay => 'Следующий день';

  @override
  String pickDate(String date) {
    return 'Выбрать дату, $date';
  }

  @override
  String get summaryNet => 'На руки';

  @override
  String get summaryRevenue => 'Выручка';

  @override
  String get summaryCommission => 'Комиссия';

  @override
  String get summaryTrips => 'Поездок';

  @override
  String get cash => 'Наличные';

  @override
  String get card => 'Карта';

  @override
  String tripsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count поездки',
      many: '$count поездок',
      few: '$count поездки',
      one: '$count поездка',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String durationHours(int hours) {
    return '$hours ч';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String commissionLine(String amount) {
    return 'комиссия $amount';
  }

  @override
  String get nextDayLabel => 'следующий день';

  @override
  String get formTitle => 'Новая поездка';

  @override
  String get start => 'Начало';

  @override
  String get end => 'Окончание';

  @override
  String get amount => 'Сумма';

  @override
  String get commission => 'Комиссия';

  @override
  String get payment => 'Способ оплаты';

  @override
  String get amountHelper => 'Сколько заплатил пассажир';

  @override
  String get nextDayBadge => '+1 день';

  @override
  String get save => 'Сохранить';

  @override
  String get saving => 'Сохраняем…';

  @override
  String get startPickerHelp => 'Начало поездки';

  @override
  String get endPickerHelp => 'Окончание поездки';

  @override
  String get pickerDone => 'Готово';

  @override
  String get timeNotPicked => 'не выбрано';

  @override
  String durationHelper(String duration) {
    return 'Длительность: $duration';
  }

  @override
  String netHelper(String amount) {
    return 'На руки с поездки: $amount';
  }

  @override
  String midnightHelper(String endDay, String duration, String startDay) {
    return 'Окончание $endDay · $duration. Поездка попадёт в $startDay — день начала.';
  }

  @override
  String get errEndBeforeStart => 'Окончание должно быть позже начала';

  @override
  String get errAmount => 'Сумма должна быть больше 0';

  @override
  String get errCommissionGtAmount => 'Комиссия не может быть больше суммы';

  @override
  String get errCommissionNegative => 'Комиссия не может быть отрицательной';

  @override
  String get errRequired => 'Заполните поле';

  @override
  String get errNotInteger => 'Введите целое число тенге';

  @override
  String get errAmountTooLarge => 'Слишком большая сумма';

  @override
  String get errDateOutOfRange => 'Дата вне допустимого диапазона';

  @override
  String get errInvalidTime => 'Неверное время поездки';

  @override
  String get errInvalidPayment => 'Выберите способ оплаты';

  @override
  String get errTripGeneric => 'Проверьте данные поездки';

  @override
  String get tripOffline =>
      'Нет связи. Повторим отправку — поездка не задвоится.';

  @override
  String get conflictTitle => 'Эта поездка уже сохранена с другими данными';

  @override
  String get conflictMessage =>
      'Обновите день, чтобы увидеть сохранённую версию.';

  @override
  String get conflictKeep => 'Оставить сохранённую';

  @override
  String get conflictNew => 'Сохранить как новую поездку';

  @override
  String get discardTitle => 'Закрыть без сохранения?';

  @override
  String get discardMessage => 'Введённые данные поездки не сохранятся.';

  @override
  String get discardKeep => 'Продолжить ввод';

  @override
  String get discardLeave => 'Закрыть';

  @override
  String get login => 'Логин';

  @override
  String get password => 'Пароль';

  @override
  String get loginTitle => 'Вход';

  @override
  String get signIn => 'Войти';

  @override
  String get signingIn => 'Входим…';

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get hidePassword => 'Скрыть пароль';

  @override
  String get errInvalidCredentials => 'Неверный логин или пароль';

  @override
  String get errRateLimited =>
      'Слишком много попыток. Попробуйте через 15 минут.';

  @override
  String get loginOffline => 'Нет связи. Проверьте интернет.';

  @override
  String get errAccountBlocked => 'Аккаунт заблокирован. Обратитесь в парк.';

  @override
  String get sessionEnded => 'Сессия завершена. Войдите снова.';

  @override
  String get roleDriver => 'Водитель';

  @override
  String get roleAdmin => 'Администратор';

  @override
  String profileCaption(String login, String role) {
    return '@$login · $role';
  }

  @override
  String get withdraw => 'Вывод средств';

  @override
  String available(String amount) {
    return 'Доступно $amount';
  }

  @override
  String get language => 'Язык';

  @override
  String get logout => 'Выйти';

  @override
  String get logoutTitle => 'Выйти из аккаунта?';

  @override
  String get logoutMessage =>
      'Чтобы снова увидеть поездки, нужно будет войти по логину и паролю.';

  @override
  String appVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get availableToWithdraw => 'Доступно к выводу';

  @override
  String get cardTotal => 'Безнал';

  @override
  String get withdrawn => 'Выведено';

  @override
  String get cashNote =>
      'Наличные остаются у вас, поэтому комиссия за них тоже списывается с безнала.';

  @override
  String get withdrawAmount => 'Сумма вывода';

  @override
  String maxHint(String amount) {
    return 'Не больше $amount';
  }

  @override
  String get all => 'Всё';

  @override
  String get history => 'История';

  @override
  String get noWithdrawals => 'Заявок на вывод пока не было.';

  @override
  String get nothingToWithdraw => 'Сейчас нечего выводить.';

  @override
  String get errInsufficient => 'Сумма больше доступной';

  @override
  String get withdrawButton => 'Вывести';

  @override
  String get sending => 'Отправляем…';

  @override
  String get withdrawOffline =>
      'Нет связи. Повторим запрос — деньги не уйдут дважды.';

  @override
  String get withdrawCreated => 'Заявка на вывод создана';

  @override
  String get withdrawConflict => 'Эта заявка уже отправлена с другой суммой';

  @override
  String get withdrawConflictMessage =>
      'История обновлена: там видна сохранённая заявка.';

  @override
  String dateTime(String date, String time) {
    return '$date, $time';
  }

  @override
  String get statusPending => 'В обработке';

  @override
  String get statusPaid => 'Выплачено';

  @override
  String get statusRejected => 'Отклонено';

  @override
  String get admin => 'Админка';

  @override
  String get tabTrips => 'Поездки';

  @override
  String get tabWithdrawals => 'Выводы';

  @override
  String get tabDrivers => 'Водители';

  @override
  String get allDrivers => 'Все водители';

  @override
  String get filterAll => 'Все';

  @override
  String get approve => 'Выплатить';

  @override
  String get reject => 'Отклонить';

  @override
  String get rejectReason => 'Причина';

  @override
  String rejectTitle(String amount) {
    return 'Отклонить заявку на $amount?';
  }

  @override
  String rejectMessage(String driver) {
    return '$driver увидит причину в истории выводов.';
  }

  @override
  String get markedPaid => 'Отмечено как выплачено';

  @override
  String get rejected => 'Заявка отклонена';

  @override
  String get block => 'Заблокировать';

  @override
  String get unblock => 'Разблокировать';

  @override
  String get revokeSessions => 'Сбросить все сессии';

  @override
  String get revokeSessionsTitle => 'Сбросить все сессии?';

  @override
  String get revokeSessionsMessage => 'Водитель выйдет на всех устройствах';

  @override
  String get revokeConfirm => 'Сбросить';

  @override
  String get adminEmptyTitle => 'Заявок нет';

  @override
  String get adminEmptyMessage => 'Новые заявки на вывод появятся здесь.';

  @override
  String driverRow(String driver, String date) {
    return '$driver · $date';
  }

  @override
  String blockedCaption(String login) {
    return '@$login · заблокирован';
  }

  @override
  String get blockedDone => 'Водитель заблокирован';

  @override
  String get unblockedDone => 'Водитель разблокирован';

  @override
  String get sessionsRevoked => 'Сессии сброшены';

  @override
  String get errAlreadyDecided => 'Заявку уже обработали — список обновлён.';

  @override
  String get errDemoProtected =>
      'Демо-аккаунт защищён: его нельзя заблокировать или сбросить его сессии.';
}
