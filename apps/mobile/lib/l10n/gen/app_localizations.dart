import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Дневник смен'**
  String get appTitle;

  /// Always in its own language, never translated.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRu;

  /// Always in its own language, never translated.
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get languageKk;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка'**
  String get loading;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get ok;

  /// No description provided for @today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get yesterday;

  /// No description provided for @menu.
  ///
  /// In ru, this message translates to:
  /// **'Меню'**
  String get menu;

  /// Screen reader text of an amount.
  ///
  /// In ru, this message translates to:
  /// **'{amount} тенге'**
  String moneySpoken(String amount);

  /// No description provided for @errorGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так. Попробуйте ещё раз.'**
  String get errorGeneric;

  /// No description provided for @errorServerUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Сервер временно недоступен. Попробуйте чуть позже.'**
  String get errorServerUnavailable;

  /// No description provided for @errorForbidden.
  ///
  /// In ru, this message translates to:
  /// **'Недостаточно прав для этого действия.'**
  String get errorForbidden;

  /// No description provided for @loadFailedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить'**
  String get loadFailedTitle;

  /// No description provided for @loadFailedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте интернет и попробуйте ещё раз.'**
  String get loadFailedMessage;

  /// No description provided for @tripsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Поездки'**
  String get tripsTitle;

  /// No description provided for @sortTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка'**
  String get sortTitle;

  /// No description provided for @sortButton.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка: {order}'**
  String sortButton(String order);

  /// No description provided for @orderTimeAscending.
  ///
  /// In ru, this message translates to:
  /// **'Сначала ранние'**
  String get orderTimeAscending;

  /// No description provided for @orderTimeDescending.
  ///
  /// In ru, this message translates to:
  /// **'Сначала поздние'**
  String get orderTimeDescending;

  /// No description provided for @orderAmountDescending.
  ///
  /// In ru, this message translates to:
  /// **'Сначала дорогие'**
  String get orderAmountDescending;

  /// No description provided for @orderAmountAscending.
  ///
  /// In ru, this message translates to:
  /// **'Сначала дешёвые'**
  String get orderAmountAscending;

  /// No description provided for @addTripFab.
  ///
  /// In ru, this message translates to:
  /// **'Поездка'**
  String get addTripFab;

  /// No description provided for @emptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'За этот день поездок нет'**
  String get emptyTitle;

  /// No description provided for @emptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте поездку — выручка, комиссия и сумма на руки посчитаются сами.'**
  String get emptyMessage;

  /// No description provided for @emptyAction.
  ///
  /// In ru, this message translates to:
  /// **'Добавить поездку'**
  String get emptyAction;

  /// No description provided for @errorTitle.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить данные'**
  String get errorTitle;

  /// No description provided for @errorMessage.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте интернет и попробуйте ещё раз. Сохранённые поездки никуда не пропадут.'**
  String get errorMessage;

  /// No description provided for @saved.
  ///
  /// In ru, this message translates to:
  /// **'Поездка добавлена'**
  String get saved;

  /// No description provided for @pickDateHelp.
  ///
  /// In ru, this message translates to:
  /// **'Выберите день'**
  String get pickDateHelp;

  /// No description provided for @prevDay.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущий день'**
  String get prevDay;

  /// No description provided for @nextDay.
  ///
  /// In ru, this message translates to:
  /// **'Следующий день'**
  String get nextDay;

  /// No description provided for @pickDate.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать дату, {date}'**
  String pickDate(String date);

  /// No description provided for @summaryNet.
  ///
  /// In ru, this message translates to:
  /// **'На руки'**
  String get summaryNet;

  /// No description provided for @summaryRevenue.
  ///
  /// In ru, this message translates to:
  /// **'Выручка'**
  String get summaryRevenue;

  /// No description provided for @summaryCommission.
  ///
  /// In ru, this message translates to:
  /// **'Комиссия'**
  String get summaryCommission;

  /// No description provided for @summaryTrips.
  ///
  /// In ru, this message translates to:
  /// **'Поездок'**
  String get summaryTrips;

  /// No description provided for @cash.
  ///
  /// In ru, this message translates to:
  /// **'Наличные'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get card;

  /// No description provided for @tripsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} поездка} few{{count} поездки} many{{count} поездок} other{{count} поездки}}'**
  String tripsCount(int count);

  /// No description provided for @durationMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{minutes} мин'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч'**
  String durationHours(int hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч {minutes} мин'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @commissionLine.
  ///
  /// In ru, this message translates to:
  /// **'комиссия {amount}'**
  String commissionLine(String amount);

  /// No description provided for @nextDayLabel.
  ///
  /// In ru, this message translates to:
  /// **'следующий день'**
  String get nextDayLabel;

  /// No description provided for @formTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новая поездка'**
  String get formTitle;

  /// No description provided for @start.
  ///
  /// In ru, this message translates to:
  /// **'Начало'**
  String get start;

  /// No description provided for @end.
  ///
  /// In ru, this message translates to:
  /// **'Окончание'**
  String get end;

  /// No description provided for @amount.
  ///
  /// In ru, this message translates to:
  /// **'Сумма'**
  String get amount;

  /// No description provided for @commission.
  ///
  /// In ru, this message translates to:
  /// **'Комиссия'**
  String get commission;

  /// No description provided for @payment.
  ///
  /// In ru, this message translates to:
  /// **'Способ оплаты'**
  String get payment;

  /// No description provided for @amountHelper.
  ///
  /// In ru, this message translates to:
  /// **'Сколько заплатил пассажир'**
  String get amountHelper;

  /// No description provided for @nextDayBadge.
  ///
  /// In ru, this message translates to:
  /// **'+1 день'**
  String get nextDayBadge;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняем…'**
  String get saving;

  /// No description provided for @startPickerHelp.
  ///
  /// In ru, this message translates to:
  /// **'Начало поездки'**
  String get startPickerHelp;

  /// No description provided for @endPickerHelp.
  ///
  /// In ru, this message translates to:
  /// **'Окончание поездки'**
  String get endPickerHelp;

  /// No description provided for @pickerDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get pickerDone;

  /// No description provided for @timeNotPicked.
  ///
  /// In ru, this message translates to:
  /// **'не выбрано'**
  String get timeNotPicked;

  /// No description provided for @durationHelper.
  ///
  /// In ru, this message translates to:
  /// **'Длительность: {duration}'**
  String durationHelper(String duration);

  /// No description provided for @netHelper.
  ///
  /// In ru, this message translates to:
  /// **'На руки с поездки: {amount}'**
  String netHelper(String amount);

  /// No description provided for @midnightHelper.
  ///
  /// In ru, this message translates to:
  /// **'Окончание {endDay} · {duration}. Поездка попадёт в {startDay} — день начала.'**
  String midnightHelper(String endDay, String duration, String startDay);

  /// No description provided for @errEndBeforeStart.
  ///
  /// In ru, this message translates to:
  /// **'Окончание должно быть позже начала'**
  String get errEndBeforeStart;

  /// No description provided for @errAmount.
  ///
  /// In ru, this message translates to:
  /// **'Сумма должна быть больше 0'**
  String get errAmount;

  /// No description provided for @errCommissionGtAmount.
  ///
  /// In ru, this message translates to:
  /// **'Комиссия не может быть больше суммы'**
  String get errCommissionGtAmount;

  /// No description provided for @errCommissionNegative.
  ///
  /// In ru, this message translates to:
  /// **'Комиссия не может быть отрицательной'**
  String get errCommissionNegative;

  /// No description provided for @errRequired.
  ///
  /// In ru, this message translates to:
  /// **'Заполните поле'**
  String get errRequired;

  /// No description provided for @errNotInteger.
  ///
  /// In ru, this message translates to:
  /// **'Введите целое число тенге'**
  String get errNotInteger;

  /// No description provided for @errAmountTooLarge.
  ///
  /// In ru, this message translates to:
  /// **'Слишком большая сумма'**
  String get errAmountTooLarge;

  /// No description provided for @errDateOutOfRange.
  ///
  /// In ru, this message translates to:
  /// **'Дата вне допустимого диапазона'**
  String get errDateOutOfRange;

  /// No description provided for @errInvalidTime.
  ///
  /// In ru, this message translates to:
  /// **'Неверное время поездки'**
  String get errInvalidTime;

  /// No description provided for @errInvalidPayment.
  ///
  /// In ru, this message translates to:
  /// **'Выберите способ оплаты'**
  String get errInvalidPayment;

  /// No description provided for @errTripGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте данные поездки'**
  String get errTripGeneric;

  /// No description provided for @tripOffline.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи. Повторим отправку — поездка не задвоится.'**
  String get tripOffline;

  /// No description provided for @conflictTitle.
  ///
  /// In ru, this message translates to:
  /// **'Эта поездка уже сохранена с другими данными'**
  String get conflictTitle;

  /// No description provided for @conflictMessage.
  ///
  /// In ru, this message translates to:
  /// **'Обновите день, чтобы увидеть сохранённую версию.'**
  String get conflictMessage;

  /// No description provided for @conflictKeep.
  ///
  /// In ru, this message translates to:
  /// **'Оставить сохранённую'**
  String get conflictKeep;

  /// No description provided for @conflictNew.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить как новую поездку'**
  String get conflictNew;

  /// No description provided for @discardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть без сохранения?'**
  String get discardTitle;

  /// No description provided for @discardMessage.
  ///
  /// In ru, this message translates to:
  /// **'Введённые данные поездки не сохранятся.'**
  String get discardMessage;

  /// No description provided for @discardKeep.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить ввод'**
  String get discardKeep;

  /// No description provided for @discardLeave.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get discardLeave;

  /// No description provided for @login.
  ///
  /// In ru, this message translates to:
  /// **'Логин'**
  String get login;

  /// No description provided for @password.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get password;

  /// No description provided for @loginTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get loginTitle;

  /// No description provided for @signIn.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In ru, this message translates to:
  /// **'Входим…'**
  String get signingIn;

  /// No description provided for @showPassword.
  ///
  /// In ru, this message translates to:
  /// **'Показать пароль'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть пароль'**
  String get hidePassword;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In ru, this message translates to:
  /// **'Неверный логин или пароль'**
  String get errInvalidCredentials;

  /// No description provided for @errRateLimited.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много попыток. Попробуйте через 15 минут.'**
  String get errRateLimited;

  /// No description provided for @loginOffline.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи. Проверьте интернет.'**
  String get loginOffline;

  /// No description provided for @errAccountBlocked.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт заблокирован. Обратитесь в парк.'**
  String get errAccountBlocked;

  /// No description provided for @sessionEnded.
  ///
  /// In ru, this message translates to:
  /// **'Сессия завершена. Войдите снова.'**
  String get sessionEnded;

  /// No description provided for @roleDriver.
  ///
  /// In ru, this message translates to:
  /// **'Водитель'**
  String get roleDriver;

  /// No description provided for @roleAdmin.
  ///
  /// In ru, this message translates to:
  /// **'Администратор'**
  String get roleAdmin;

  /// No description provided for @profileCaption.
  ///
  /// In ru, this message translates to:
  /// **'@{login} · {role}'**
  String profileCaption(String login, String role);

  /// No description provided for @withdraw.
  ///
  /// In ru, this message translates to:
  /// **'Вывод средств'**
  String get withdraw;

  /// No description provided for @available.
  ///
  /// In ru, this message translates to:
  /// **'Доступно {amount}'**
  String available(String amount);

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get logout;

  /// No description provided for @logoutTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта?'**
  String get logoutTitle;

  /// No description provided for @logoutMessage.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы снова увидеть поездки, нужно будет войти по логину и паролю.'**
  String get logoutMessage;

  /// No description provided for @appVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия {version}'**
  String appVersion(String version);

  /// No description provided for @availableToWithdraw.
  ///
  /// In ru, this message translates to:
  /// **'Доступно к выводу'**
  String get availableToWithdraw;

  /// No description provided for @cardTotal.
  ///
  /// In ru, this message translates to:
  /// **'Безнал'**
  String get cardTotal;

  /// No description provided for @withdrawn.
  ///
  /// In ru, this message translates to:
  /// **'Выведено'**
  String get withdrawn;

  /// No description provided for @cashNote.
  ///
  /// In ru, this message translates to:
  /// **'Наличные остаются у вас, поэтому комиссия за них тоже списывается с безнала.'**
  String get cashNote;

  /// No description provided for @withdrawAmount.
  ///
  /// In ru, this message translates to:
  /// **'Сумма вывода'**
  String get withdrawAmount;

  /// No description provided for @maxHint.
  ///
  /// In ru, this message translates to:
  /// **'Не больше {amount}'**
  String maxHint(String amount);

  /// No description provided for @all.
  ///
  /// In ru, this message translates to:
  /// **'Всё'**
  String get all;

  /// No description provided for @history.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get history;

  /// No description provided for @noWithdrawals.
  ///
  /// In ru, this message translates to:
  /// **'Заявок на вывод пока не было.'**
  String get noWithdrawals;

  /// No description provided for @nothingToWithdraw.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас нечего выводить.'**
  String get nothingToWithdraw;

  /// No description provided for @errInsufficient.
  ///
  /// In ru, this message translates to:
  /// **'Сумма больше доступной'**
  String get errInsufficient;

  /// No description provided for @withdrawButton.
  ///
  /// In ru, this message translates to:
  /// **'Вывести'**
  String get withdrawButton;

  /// No description provided for @sending.
  ///
  /// In ru, this message translates to:
  /// **'Отправляем…'**
  String get sending;

  /// No description provided for @withdrawOffline.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи. Повторим запрос — деньги не уйдут дважды.'**
  String get withdrawOffline;

  /// No description provided for @withdrawCreated.
  ///
  /// In ru, this message translates to:
  /// **'Заявка на вывод создана'**
  String get withdrawCreated;

  /// No description provided for @withdrawConflict.
  ///
  /// In ru, this message translates to:
  /// **'Эта заявка уже отправлена с другой суммой'**
  String get withdrawConflict;

  /// No description provided for @withdrawConflictMessage.
  ///
  /// In ru, this message translates to:
  /// **'История обновлена: там видна сохранённая заявка.'**
  String get withdrawConflictMessage;

  /// No description provided for @dateTime.
  ///
  /// In ru, this message translates to:
  /// **'{date}, {time}'**
  String dateTime(String date, String time);

  /// No description provided for @statusPending.
  ///
  /// In ru, this message translates to:
  /// **'В обработке'**
  String get statusPending;

  /// No description provided for @statusPaid.
  ///
  /// In ru, this message translates to:
  /// **'Выплачено'**
  String get statusPaid;

  /// No description provided for @statusRejected.
  ///
  /// In ru, this message translates to:
  /// **'Отклонено'**
  String get statusRejected;

  /// No description provided for @admin.
  ///
  /// In ru, this message translates to:
  /// **'Админка'**
  String get admin;

  /// No description provided for @tabTrips.
  ///
  /// In ru, this message translates to:
  /// **'Поездки'**
  String get tabTrips;

  /// No description provided for @tabWithdrawals.
  ///
  /// In ru, this message translates to:
  /// **'Выводы'**
  String get tabWithdrawals;

  /// No description provided for @tabDrivers.
  ///
  /// In ru, this message translates to:
  /// **'Водители'**
  String get tabDrivers;

  /// No description provided for @allDrivers.
  ///
  /// In ru, this message translates to:
  /// **'Все водители'**
  String get allDrivers;

  /// No description provided for @filterAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get filterAll;

  /// No description provided for @approve.
  ///
  /// In ru, this message translates to:
  /// **'Выплатить'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get reject;

  /// No description provided for @rejectReason.
  ///
  /// In ru, this message translates to:
  /// **'Причина'**
  String get rejectReason;

  /// No description provided for @rejectTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить заявку на {amount}?'**
  String rejectTitle(String amount);

  /// No description provided for @rejectMessage.
  ///
  /// In ru, this message translates to:
  /// **'{driver} увидит причину в истории выводов.'**
  String rejectMessage(String driver);

  /// No description provided for @markedPaid.
  ///
  /// In ru, this message translates to:
  /// **'Отмечено как выплачено'**
  String get markedPaid;

  /// No description provided for @rejected.
  ///
  /// In ru, this message translates to:
  /// **'Заявка отклонена'**
  String get rejected;

  /// No description provided for @block.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировать'**
  String get unblock;

  /// No description provided for @revokeSessions.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить все сессии'**
  String get revokeSessions;

  /// No description provided for @revokeSessionsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить все сессии?'**
  String get revokeSessionsTitle;

  /// No description provided for @revokeSessionsMessage.
  ///
  /// In ru, this message translates to:
  /// **'Водитель выйдет на всех устройствах'**
  String get revokeSessionsMessage;

  /// No description provided for @revokeConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get revokeConfirm;

  /// No description provided for @adminEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заявок нет'**
  String get adminEmptyTitle;

  /// No description provided for @adminEmptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'Новые заявки на вывод появятся здесь.'**
  String get adminEmptyMessage;

  /// No description provided for @driverRow.
  ///
  /// In ru, this message translates to:
  /// **'{driver} · {date}'**
  String driverRow(String driver, String date);

  /// No description provided for @blockedCaption.
  ///
  /// In ru, this message translates to:
  /// **'@{login} · заблокирован'**
  String blockedCaption(String login);

  /// No description provided for @blockedDone.
  ///
  /// In ru, this message translates to:
  /// **'Водитель заблокирован'**
  String get blockedDone;

  /// No description provided for @unblockedDone.
  ///
  /// In ru, this message translates to:
  /// **'Водитель разблокирован'**
  String get unblockedDone;

  /// No description provided for @sessionsRevoked.
  ///
  /// In ru, this message translates to:
  /// **'Сессии сброшены'**
  String get sessionsRevoked;

  /// No description provided for @errAlreadyDecided.
  ///
  /// In ru, this message translates to:
  /// **'Заявку уже обработали — список обновлён.'**
  String get errAlreadyDecided;

  /// No description provided for @errDemoProtected.
  ///
  /// In ru, this message translates to:
  /// **'Демо-аккаунт защищён: его нельзя заблокировать или сбросить его сессии.'**
  String get errDemoProtected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
