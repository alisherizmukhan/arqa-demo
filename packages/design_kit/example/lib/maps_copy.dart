// Texts of the DESIGN.md §9 previews in Russian and Kazakh. The kit has no
// texts; the app will get these from its ARB files in stage 3 (Kazakh is a
// machine translation, «needs native review» in docs/L10N.md). Copy marked
// «proposed» in DESIGN.md §9.7 waits for approval.

/// Every text the map screens need, in one language.
class MapsCopy {
  /// Creates a language's copy.
  const new({
    required this.code,
    required this.from,
    required this.to,
    required this.pickOnMap,
    required this.pickThisPlace,
    required this.resolving,
    required this.notFound,
    required this.searchAddress,
    required this.distance,
    required this.perMinute,
    required this.perKm,
    required this.dayMap,
    required this.straightInfo,
    required this.rebuild,
    required this.startOfTrip,
    required this.endOfTrip,
    required this.errIncomplete,
    required this.errOutside,
    required this.errSame,
    required this.offlineMap,
    required this.clear,
    required this.tripTitle,
    required this.metres,
    required this.kilometres,
    required this.minutes,
    required this.hoursMinutes,
    required this.routes,
    required this.close,
    required this.back,
    required this.trips,
    required this.tripsCount,
    required this.cash,
    required this.card,
    required this.commissionLine,
    required this.formTitle,
    required this.start,
    required this.end,
    required this.amount,
    required this.commission,
    required this.payment,
    required this.save,
    required this.nextDay,
    required this.retry,
    required this.loadFailed,
    required this.loadFailedMessage,
    required this.date,
    required this.dateShort,
    required this.weekday,
    required this.today,
    required this.prevDay,
    required this.nextDayLabel,
    required this.pickDate,
    required this.allDrivers,
    required this.driver1,
    required this.driver2,
    required this.sort,
    required this.wordmark,
    required this.adminCaption,
    required this.tabTrips,
    required this.tabWithdrawals,
    required this.tabDrivers,
    required this.netLabel,
    required this.revenueLabel,
    required this.tripsLabel,
    required this.menu,
  });

  /// `ru` / `kk`.
  final String code;

  /// «Откуда».
  final String from;

  /// «Куда».
  final String to;

  /// «Выбрать на карте».
  final String pickOnMap;

  /// «Выбрать это место».
  final String pickThisPlace;

  /// «Определяем адрес…».
  final String resolving;

  /// «Адрес не найден».
  final String notFound;

  /// «Поиск адреса».
  final String searchAddress;

  /// «Расстояние».
  final String distance;

  /// «За минуту» (proposed, approved).
  final String perMinute;

  /// «За км».
  final String perKm;

  /// «Карта дня».
  final String dayMap;

  /// «Маршрут построен по прямой — сервис карт был недоступен».
  final String straightInfo;

  /// «Построить заново».
  final String rebuild;

  /// «Начало поездки».
  final String startOfTrip;

  /// «Конец поездки».
  final String endOfTrip;

  /// «Укажите и начало, и конец поездки».
  final String errIncomplete;

  /// «Точка вне Алматы».
  final String errOutside;

  /// «Начало и конец совпадают».
  final String errSame;

  /// «Нет связи — карта не загрузилась».
  final String offlineMap;

  /// «Очистить» (proposed).
  final String clear;

  /// «Поездка» (proposed: the details title).
  final String tripTitle;

  /// «м».
  final String metres;

  /// «км».
  final String kilometres;

  /// `22 мин`.
  final String Function(int minutes) minutes;

  /// `1 ч 5 мин`.
  final String Function(int hours, int minutes) hoursMinutes;

  /// `2 маршрута` (proposed: the day-map legend).
  final String Function(int count) routes;

  /// «Закрыть».
  final String close;

  /// «Назад».
  final String back;

  /// «Поездки».
  final String trips;

  /// `2 поездки`.
  final String Function(int count) tripsCount;

  /// «Наличные».
  final String cash;

  /// «Карта».
  final String card;

  /// `комиссия 360 ₸`.
  final String Function(String amount) commissionLine;

  /// «Новая поездка».
  final String formTitle;

  /// «Начало».
  final String start;

  /// «Окончание».
  final String end;

  /// «Сумма».
  final String amount;

  /// «Комиссия».
  final String commission;

  /// «Способ оплаты».
  final String payment;

  /// «Сохранить».
  final String save;

  /// Spoken «+1».
  final String nextDay;

  /// «Повторить».
  final String retry;

  /// «Не удалось загрузить».
  final String loadFailed;

  /// The error-state message.
  final String loadFailedMessage;

  /// `1 октября 2026`.
  final String date;

  /// `1 октября`.
  final String dateShort;

  /// `Четверг`.
  final String weekday;

  /// «Сегодня».
  final String today;

  /// «Предыдущий день».
  final String prevDay;

  /// «Следующий день».
  final String nextDayLabel;

  /// «Выбрать дату».
  final String pickDate;

  /// «Все водители».
  final String allDrivers;

  /// «Водитель 1».
  final String driver1;

  /// «Водитель 2».
  final String driver2;

  /// «Сортировка: сначала ранние».
  final String sort;

  /// «Дневник смен».
  final String wordmark;

  /// «Администратор».
  final String adminCaption;

  /// «Поездки» (admin tab).
  final String tabTrips;

  /// «Выводы».
  final String tabWithdrawals;

  /// «Водители».
  final String tabDrivers;

  /// «На руки».
  final String netLabel;

  /// «Выручка».
  final String revenueLabel;

  /// «Поездок».
  final String tripsLabel;

  /// «Меню».
  final String menu;

  /// `22 мин` or `1 ч 5 мин`.
  String duration(Duration d) {
    final m = d.inMinutes;
    return m < 60 ? minutes(m) : hoursMinutes(m ~/ 60, m % 60);
  }
}

String _ruPlural(int n, String one, String few, String many) {
  final mod100 = n % 100;
  final mod10 = n % 10;
  if (mod100 >= 11 && mod100 <= 14) return '$n $many';
  if (mod10 == 1) return '$n $one';
  if (mod10 >= 2 && mod10 <= 4) return '$n $few';
  return '$n $many';
}

/// Russian.
final MapsCopy ruCopy = MapsCopy(
  code: 'ru',
  from: 'Откуда',
  to: 'Куда',
  pickOnMap: 'Выбрать на карте',
  pickThisPlace: 'Выбрать это место',
  resolving: 'Определяем адрес…',
  notFound: 'Адрес не найден',
  searchAddress: 'Поиск адреса',
  distance: 'Расстояние',
  perMinute: 'За минуту',
  perKm: 'За км',
  dayMap: 'Карта дня',
  straightInfo: 'Маршрут построен по прямой — сервис карт был недоступен',
  rebuild: 'Построить заново',
  startOfTrip: 'Начало поездки',
  endOfTrip: 'Конец поездки',
  errIncomplete: 'Укажите и начало, и конец поездки',
  errOutside: 'Точка вне Алматы',
  errSame: 'Начало и конец совпадают',
  offlineMap: 'Нет связи — карта не загрузилась',
  clear: 'Очистить',
  tripTitle: 'Поездка',
  metres: 'м',
  kilometres: 'км',
  minutes: (m) => '$m мин',
  hoursMinutes: (h, m) => m == 0 ? '$h ч' : '$h ч $m мин',
  routes: (n) => _ruPlural(n, 'маршрут', 'маршрута', 'маршрутов'),
  close: 'Закрыть',
  back: 'Назад',
  trips: 'Поездки',
  tripsCount: (n) => _ruPlural(n, 'поездка', 'поездки', 'поездок'),
  cash: 'Наличные',
  card: 'Карта',
  commissionLine: (a) => 'комиссия $a',
  formTitle: 'Новая поездка',
  start: 'Начало',
  end: 'Окончание',
  amount: 'Сумма',
  commission: 'Комиссия',
  payment: 'Способ оплаты',
  save: 'Сохранить',
  nextDay: 'следующий день',
  retry: 'Повторить',
  loadFailed: 'Не удалось загрузить',
  loadFailedMessage:
      'Проверьте интернет и попробуйте ещё раз. Сохранённые поездки никуда '
      'не пропадут.',
  date: '1 октября 2026',
  dateShort: '1 октября',
  weekday: 'Четверг',
  today: 'Сегодня',
  prevDay: 'Предыдущий день',
  nextDayLabel: 'Следующий день',
  pickDate: 'Выбрать дату',
  allDrivers: 'Все водители',
  driver1: 'Водитель 1',
  driver2: 'Водитель 2',
  sort: 'Сортировка: сначала ранние',
  wordmark: 'Дневник смен',
  adminCaption: 'Администратор',
  tabTrips: 'Поездки',
  tabWithdrawals: 'Выводы',
  tabDrivers: 'Водители',
  netLabel: 'На руки',
  revenueLabel: 'Выручка',
  tripsLabel: 'Поездок',
  menu: 'Меню',
);

/// Kazakh (machine translation, needs native review).
final MapsCopy kkCopy = MapsCopy(
  code: 'kk',
  from: 'Қайдан',
  to: 'Қайда',
  pickOnMap: 'Картадан таңдау',
  pickThisPlace: 'Осы жерді таңдау',
  resolving: 'Мекенжайды анықтаймыз…',
  notFound: 'Мекенжай табылмады',
  searchAddress: 'Мекенжай іздеу',
  distance: 'Қашықтық',
  perMinute: 'Минутына',
  perKm: '1 км үшін',
  dayMap: 'Күн картасы',
  straightInfo:
      'Бағыт түзу сызықпен салынды — карта қызметі қолжетімсіз '
      'болды',
  rebuild: 'Қайта салу',
  startOfTrip: 'Сапардың басы',
  endOfTrip: 'Сапардың соңы',
  errIncomplete: 'Сапардың басын да, соңын да көрсетіңіз',
  errOutside: 'Нүкте Алматыдан тыс',
  errSame: 'Басы мен соңы бірдей',
  offlineMap: 'Байланыс жоқ — карта жүктелмеді',
  clear: 'Тазалау',
  tripTitle: 'Сапар',
  metres: 'м',
  kilometres: 'км',
  minutes: (m) => '$m мин',
  hoursMinutes: (h, m) => m == 0 ? '$h сағ' : '$h сағ $m мин',
  routes: (n) => '$n бағыт',
  close: 'Жабу',
  back: 'Артқа',
  trips: 'Сапарлар',
  tripsCount: (n) => '$n сапар',
  cash: 'Қолма-қол',
  card: 'Карта',
  commissionLine: (a) => 'комиссия $a',
  formTitle: 'Жаңа сапар',
  start: 'Басталуы',
  end: 'Аяқталуы',
  amount: 'Сома',
  commission: 'Комиссия',
  payment: 'Төлем тәсілі',
  save: 'Сақтау',
  nextDay: 'келесі күн',
  retry: 'Қайталау',
  loadFailed: 'Жүктеу мүмкін болмады',
  loadFailedMessage:
      'Интернетті тексеріп, қайталап көріңіз. Сақталған сапарлар жоғалмайды.',
  date: '2026 ж. 1 қазан',
  dateShort: '1 қазан',
  weekday: 'Бейсенбі',
  today: 'Бүгін',
  prevDay: 'Алдыңғы күн',
  nextDayLabel: 'Келесі күн',
  pickDate: 'Күнді таңдау',
  allDrivers: 'Барлық жүргізушілер',
  driver1: 'Жүргізуші 1',
  driver2: 'Жүргізуші 2',
  sort: 'Сұрыптау: алдымен ертеректері',
  wordmark: 'Ауысым күнделігі',
  adminCaption: 'Әкімші',
  tabTrips: 'Сапарлар',
  tabWithdrawals: 'Шығару',
  tabDrivers: 'Жүргізуші',
  netLabel: 'Қолға',
  revenueLabel: 'Түсім',
  tripsLabel: 'Сапар саны',
  menu: 'Мәзір',
);
