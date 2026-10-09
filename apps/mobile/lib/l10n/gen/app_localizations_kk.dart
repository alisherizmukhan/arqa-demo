// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appTitle => 'Ауысым күнделігі';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageKk => 'Қазақша';

  @override
  String get retry => 'Қайталау';

  @override
  String get loading => 'Жүктелуде';

  @override
  String get close => 'Жабу';

  @override
  String get back => 'Артқа';

  @override
  String get cancel => 'Бас тарту';

  @override
  String get ok => 'Түсінікті';

  @override
  String get today => 'Бүгін';

  @override
  String get yesterday => 'Кеше';

  @override
  String get menu => 'Мәзір';

  @override
  String moneySpoken(String amount) {
    return '$amount теңге';
  }

  @override
  String get errorGeneric => 'Бірдеңе дұрыс болмады. Қайталап көріңіз.';

  @override
  String get errorServerUnavailable =>
      'Сервер уақытша қолжетімсіз. Сәл кейінірек көріңіз.';

  @override
  String get errorForbidden => 'Бұл әрекетке құқығыңыз жеткіліксіз.';

  @override
  String get loadFailedTitle => 'Жүктеу мүмкін болмады';

  @override
  String get loadFailedMessage => 'Интернетті тексеріп, қайталап көріңіз.';

  @override
  String get tripsTitle => 'Сапарлар';

  @override
  String get sortTitle => 'Сұрыптау';

  @override
  String sortButton(String order) {
    return 'Сұрыптау: $order';
  }

  @override
  String get orderTimeAscending => 'Алдымен ертеректері';

  @override
  String get orderTimeDescending => 'Алдымен кештері';

  @override
  String get orderAmountDescending => 'Алдымен қымбаттары';

  @override
  String get orderAmountAscending => 'Алдымен арзандары';

  @override
  String get addTripFab => 'Сапар';

  @override
  String get emptyTitle => 'Бұл күні сапар жоқ';

  @override
  String get emptyMessage =>
      'Сапар қосыңыз — түсім, комиссия және қолға тиетін сома өзі есептеледі.';

  @override
  String get emptyAction => 'Сапар қосу';

  @override
  String get errorTitle => 'Деректерді жүктеу мүмкін болмады';

  @override
  String get errorMessage =>
      'Интернетті тексеріп, қайталап көріңіз. Сақталған сапарлар жоғалмайды.';

  @override
  String get saved => 'Сапар қосылды';

  @override
  String get pickDateHelp => 'Күнді таңдаңыз';

  @override
  String get prevDay => 'Алдыңғы күн';

  @override
  String get nextDay => 'Келесі күн';

  @override
  String pickDate(String date) {
    return 'Күнді таңдау, $date';
  }

  @override
  String get summaryNet => 'Қолға';

  @override
  String get summaryRevenue => 'Түсім';

  @override
  String get summaryCommission => 'Комиссия';

  @override
  String get summaryTrips => 'Сапар саны';

  @override
  String get cash => 'Қолма-қол';

  @override
  String get card => 'Карта';

  @override
  String tripsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сапар',
      one: '$count сапар',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String durationHours(int hours) {
    return '$hours сағ';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours сағ $minutes мин';
  }

  @override
  String commissionLine(String amount) {
    return 'комиссия $amount';
  }

  @override
  String get nextDayLabel => 'келесі күн';

  @override
  String get formTitle => 'Жаңа сапар';

  @override
  String get start => 'Басталуы';

  @override
  String get end => 'Аяқталуы';

  @override
  String get amount => 'Сома';

  @override
  String get commission => 'Комиссия';

  @override
  String get payment => 'Төлем тәсілі';

  @override
  String get amountHelper => 'Жолаушы қанша төледі';

  @override
  String get nextDayBadge => '+1 күн';

  @override
  String get save => 'Сақтау';

  @override
  String get saving => 'Сақталуда…';

  @override
  String get startPickerHelp => 'Сапардың басталуы';

  @override
  String get endPickerHelp => 'Сапардың аяқталуы';

  @override
  String get pickerDone => 'Дайын';

  @override
  String get timeNotPicked => 'таңдалмаған';

  @override
  String durationHelper(String duration) {
    return 'Ұзақтығы: $duration';
  }

  @override
  String netHelper(String amount) {
    return 'Сапардан қолға: $amount';
  }

  @override
  String midnightHelper(String endDay, String duration, String startDay) {
    return 'Аяқталуы $endDay · $duration. Сапар басталған күнге — $startDay жазылады.';
  }

  @override
  String get errEndBeforeStart => 'Аяқталуы басталуынан кейін болуы керек';

  @override
  String get errAmount => 'Сома 0-ден көп болуы керек';

  @override
  String get errCommissionGtAmount => 'Комиссия сомадан көп бола алмайды';

  @override
  String get errCommissionNegative => 'Комиссия теріс бола алмайды';

  @override
  String get errRequired => 'Өрісті толтырыңыз';

  @override
  String get errNotInteger => 'Теңгенің бүтін санын енгізіңіз';

  @override
  String get errAmountTooLarge => 'Сома тым үлкен';

  @override
  String get errDateOutOfRange => 'Күні рұқсат етілген ауқымнан тыс';

  @override
  String get errInvalidTime => 'Сапар уақыты қате';

  @override
  String get errInvalidPayment => 'Төлем тәсілін таңдаңыз';

  @override
  String get errTripGeneric => 'Сапар деректерін тексеріңіз';

  @override
  String get tripOffline =>
      'Байланыс жоқ. Қайта жібереміз — сапар екі рет жазылмайды.';

  @override
  String get conflictTitle => 'Бұл сапар басқа деректермен сақталып қойған';

  @override
  String get conflictMessage =>
      'Сақталған нұсқасын көру үшін күнді жаңартыңыз.';

  @override
  String get conflictKeep => 'Сақталғанын қалдыру';

  @override
  String get conflictNew => 'Жаңа сапар ретінде сақтау';

  @override
  String get discardTitle => 'Сақтамай жабу керек пе?';

  @override
  String get discardMessage => 'Енгізілген сапар деректері сақталмайды.';

  @override
  String get discardKeep => 'Енгізуді жалғастыру';

  @override
  String get discardLeave => 'Жабу';

  @override
  String get login => 'Логин';

  @override
  String get password => 'Құпиясөз';

  @override
  String get loginTitle => 'Жүйеге кіру';

  @override
  String get signIn => 'Кіру';

  @override
  String get signingIn => 'Кіріп жатырмыз…';

  @override
  String get showPassword => 'Құпиясөзді көрсету';

  @override
  String get hidePassword => 'Құпиясөзді жасыру';

  @override
  String get errInvalidCredentials => 'Логин немесе құпиясөз қате';

  @override
  String get errRateLimited =>
      'Әрекет тым көп. 15 минуттан кейін қайталап көріңіз.';

  @override
  String get loginOffline => 'Байланыс жоқ. Интернетті тексеріңіз.';

  @override
  String get errAccountBlocked => 'Аккаунт бұғатталған. Паркке хабарласыңыз.';

  @override
  String get sessionEnded => 'Сессия аяқталды. Қайта кіріңіз.';

  @override
  String get roleDriver => 'Жүргізуші';

  @override
  String get roleAdmin => 'Әкімші';

  @override
  String profileCaption(String login, String role) {
    return '@$login · $role';
  }

  @override
  String get withdraw => 'Қаражат шығару';

  @override
  String available(String amount) {
    return 'Қолжетімді: $amount';
  }

  @override
  String get language => 'Тіл';

  @override
  String get logout => 'Шығу';

  @override
  String get logoutTitle => 'Аккаунттан шығу керек пе?';

  @override
  String get logoutMessage =>
      'Сапарларды қайта көру үшін логин мен құпиясөз арқылы кіру керек болады.';

  @override
  String appVersion(String version) {
    return 'Нұсқа $version';
  }

  @override
  String get availableToWithdraw => 'Шығаруға қолжетімді';

  @override
  String get cardTotal => 'Қолма-қолсыз';

  @override
  String get withdrawn => 'Шығарылды';

  @override
  String get cashNote =>
      'Қолма-қол ақша сізде қалады, сондықтан оның комиссиясы да қолма-қолсыз төлемнен ұсталады.';

  @override
  String get withdrawAmount => 'Шығару сомасы';

  @override
  String maxHint(String amount) {
    return 'Ең көбі $amount';
  }

  @override
  String get all => 'Барлығы';

  @override
  String get history => 'Тарих';

  @override
  String get noWithdrawals => 'Шығару өтінімдері әлі болған жоқ.';

  @override
  String get nothingToWithdraw => 'Қазір шығаратын ештеңе жоқ.';

  @override
  String get errInsufficient => 'Сома қолжетімдіден көп';

  @override
  String get withdrawButton => 'Шығару';

  @override
  String get sending => 'Жіберілуде…';

  @override
  String get withdrawOffline =>
      'Байланыс жоқ. Сұрауды қайталаймыз — ақша екі рет кетпейді.';

  @override
  String get withdrawCreated => 'Шығару өтінімі жасалды';

  @override
  String get withdrawConflict => 'Бұл өтінім басқа сомамен жіберіліп қойған';

  @override
  String get withdrawConflictMessage =>
      'Тарих жаңартылды: сақталған өтінім сонда көрінеді.';

  @override
  String dateTime(String date, String time) {
    return '$date, $time';
  }

  @override
  String get statusPending => 'Өңделуде';

  @override
  String get statusPaid => 'Төленді';

  @override
  String get statusRejected => 'Қабылданбады';

  @override
  String get admin => 'Әкімші панелі';

  @override
  String get tabTrips => 'Сапарлар';

  @override
  String get tabWithdrawals => 'Шығарулар';

  @override
  String get tabDrivers => 'Жүргізушілер';

  @override
  String get allDrivers => 'Барлық жүргізушілер';

  @override
  String get filterAll => 'Барлығы';

  @override
  String get approve => 'Төлеу';

  @override
  String get reject => 'Қабылдамау';

  @override
  String get rejectReason => 'Себебі';

  @override
  String rejectTitle(String amount) {
    return '$amount өтінімін қабылдамау керек пе?';
  }

  @override
  String rejectMessage(String driver) {
    return '$driver себебін шығару тарихынан көреді.';
  }

  @override
  String get markedPaid => 'Төленді деп белгіленді';

  @override
  String get rejected => 'Өтінім қабылданбады';

  @override
  String get block => 'Бұғаттау';

  @override
  String get unblock => 'Бұғаттан шығару';

  @override
  String get revokeSessions => 'Барлық сессияны тоқтату';

  @override
  String get revokeSessionsTitle => 'Барлық сессияны тоқтату керек пе?';

  @override
  String get revokeSessionsMessage => 'Жүргізуші барлық құрылғыдан шығады';

  @override
  String get revokeConfirm => 'Тоқтату';

  @override
  String get adminEmptyTitle => 'Өтінім жоқ';

  @override
  String get adminEmptyMessage => 'Жаңа шығару өтінімдері осында көрінеді.';

  @override
  String driverRow(String driver, String date) {
    return '$driver · $date';
  }

  @override
  String blockedCaption(String login) {
    return '@$login · бұғатталған';
  }

  @override
  String get blockedDone => 'Жүргізуші бұғатталды';

  @override
  String get unblockedDone => 'Жүргізуші бұғаттан шығарылды';

  @override
  String get sessionsRevoked => 'Сессиялар тоқтатылды';

  @override
  String get errAlreadyDecided => 'Өтінім өңделіп қойған — тізім жаңартылды.';

  @override
  String get errDemoProtected =>
      'Демо-аккаунт қорғалған: оны бұғаттауға немесе сессияларын тоқтатуға болмайды.';
}
