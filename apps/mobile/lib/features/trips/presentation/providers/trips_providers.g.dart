// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trips_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tripsRepository)
final tripsRepositoryProvider = TripsRepositoryProvider._();

final class TripsRepositoryProvider
    extends
        $FunctionalProvider<TripsRepository, TripsRepository, TripsRepository>
    with $Provider<TripsRepository> {
  TripsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TripsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TripsRepository create(Ref ref) {
    return tripsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripsRepository>(value),
    );
  }
}

String _$tripsRepositoryHash() => r'03f9e91a7f457b30fd5d0525da5dfdcc89c1a72f';

@ProviderFor(driverZone)
final driverZoneProvider = DriverZoneProvider._();

final class DriverZoneProvider
    extends $FunctionalProvider<DriverZone, DriverZone, DriverZone>
    with $Provider<DriverZone> {
  DriverZoneProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'driverZoneProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$driverZoneHash();

  @$internal
  @override
  $ProviderElement<DriverZone> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DriverZone create(Ref ref) {
    return driverZone(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DriverZone value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DriverZone>(value),
    );
  }
}

String _$driverZoneHash() => r'f5309e3d8565a65ded115ec42ad2e0d071d10c9b';

/// Today in the driver's zone (not the phone's).

@ProviderFor(today)
final todayProvider = TodayProvider._();

/// Today in the driver's zone (not the phone's).

final class TodayProvider
    extends $FunctionalProvider<CalendarDay, CalendarDay, CalendarDay>
    with $Provider<CalendarDay> {
  /// Today in the driver's zone (not the phone's).
  TodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayHash();

  @$internal
  @override
  $ProviderElement<CalendarDay> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CalendarDay create(Ref ref) {
    return today(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarDay value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarDay>(value),
    );
  }
}

String _$todayHash() => r'a5c87d0bd63cf8c7ae3e8bf0ae12302aed711772';

/// The day the user is looking at. Starts at today (again for each new
/// session); never goes past today.

@ProviderFor(SelectedDay)
final selectedDayProvider = SelectedDayProvider._();

/// The day the user is looking at. Starts at today (again for each new
/// session); never goes past today.
final class SelectedDayProvider
    extends $NotifierProvider<SelectedDay, CalendarDay> {
  /// The day the user is looking at. Starts at today (again for each new
  /// session); never goes past today.
  SelectedDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedDayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedDayHash();

  @$internal
  @override
  SelectedDay create() => SelectedDay();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarDay value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarDay>(value),
    );
  }
}

String _$selectedDayHash() => r'65c1e5f9035666e5697da0487e1765caa9a3fcde';

/// The day the user is looking at. Starts at today (again for each new
/// session); never goes past today.

abstract class _$SelectedDay extends $Notifier<CalendarDay> {
  CalendarDay build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CalendarDay, CalendarDay>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarDay, CalendarDay>,
              CalendarDay,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Trips of [day], ordered by start: the driver's own, or (admin) all
/// drivers' or one driver's ([driverId]). Cached for [dayCacheTtl] after its
/// last listener goes, and only for the session that loaded it; a failed load
/// is not cached.

@ProviderFor(dayTrips)
final dayTripsProvider = DayTripsFamily._();

/// Trips of [day], ordered by start: the driver's own, or (admin) all
/// drivers' or one driver's ([driverId]). Cached for [dayCacheTtl] after its
/// last listener goes, and only for the session that loaded it; a failed load
/// is not cached.

final class DayTripsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Trip>>,
          List<Trip>,
          FutureOr<List<Trip>>
        >
    with $FutureModifier<List<Trip>>, $FutureProvider<List<Trip>> {
  /// Trips of [day], ordered by start: the driver's own, or (admin) all
  /// drivers' or one driver's ([driverId]). Cached for [dayCacheTtl] after its
  /// last listener goes, and only for the session that loaded it; a failed load
  /// is not cached.
  DayTripsProvider._({
    required DayTripsFamily super.from,
    required (CalendarDay, {String? driverId}) super.argument,
  }) : super(
         retry: null,
         name: r'dayTripsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dayTripsHash();

  @override
  String toString() {
    return r'dayTripsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Trip>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Trip>> create(Ref ref) {
    final argument = this.argument as (CalendarDay, {String? driverId});
    return dayTrips(ref, argument.$1, driverId: argument.driverId);
  }

  @override
  bool operator ==(Object other) {
    return other is DayTripsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dayTripsHash() => r'df849ddda57037589360118737309848163d8375';

/// Trips of [day], ordered by start: the driver's own, or (admin) all
/// drivers' or one driver's ([driverId]). Cached for [dayCacheTtl] after its
/// last listener goes, and only for the session that loaded it; a failed load
/// is not cached.

final class DayTripsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Trip>>,
          (CalendarDay, {String? driverId})
        > {
  DayTripsFamily._()
    : super(
        retry: null,
        name: r'dayTripsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Trips of [day], ordered by start: the driver's own, or (admin) all
  /// drivers' or one driver's ([driverId]). Cached for [dayCacheTtl] after its
  /// last listener goes, and only for the session that loaded it; a failed load
  /// is not cached.

  DayTripsProvider call(CalendarDay day, {String? driverId}) =>
      DayTripsProvider._(argument: (day, driverId: driverId), from: this);

  @override
  String toString() => r'dayTripsProvider';
}

/// Summary of [day], computed from the same trips the list shows, so the
/// card and the list can never disagree.

@ProviderFor(daySummary)
final daySummaryProvider = DaySummaryFamily._();

/// Summary of [day], computed from the same trips the list shows, so the
/// card and the list can never disagree.

final class DaySummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailySummary>,
          DailySummary,
          FutureOr<DailySummary>
        >
    with $FutureModifier<DailySummary>, $FutureProvider<DailySummary> {
  /// Summary of [day], computed from the same trips the list shows, so the
  /// card and the list can never disagree.
  DaySummaryProvider._({
    required DaySummaryFamily super.from,
    required (CalendarDay, {String? driverId}) super.argument,
  }) : super(
         retry: null,
         name: r'daySummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$daySummaryHash();

  @override
  String toString() {
    return r'daySummaryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<DailySummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DailySummary> create(Ref ref) {
    final argument = this.argument as (CalendarDay, {String? driverId});
    return daySummary(ref, argument.$1, driverId: argument.driverId);
  }

  @override
  bool operator ==(Object other) {
    return other is DaySummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$daySummaryHash() => r'856c21e98169c424d2c96a3964434e7cf6d9c6cc';

/// Summary of [day], computed from the same trips the list shows, so the
/// card and the list can never disagree.

final class DaySummaryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<DailySummary>,
          (CalendarDay, {String? driverId})
        > {
  DaySummaryFamily._()
    : super(
        retry: null,
        name: r'daySummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Summary of [day], computed from the same trips the list shows, so the
  /// card and the list can never disagree.

  DaySummaryProvider call(CalendarDay day, {String? driverId}) =>
      DaySummaryProvider._(argument: (day, driverId: driverId), from: this);

  @override
  String toString() => r'daySummaryProvider';
}

/// The order of the Day screen's trips; the same for every day while the
/// app runs. Starts with [TripOrder.timeAscending].

@ProviderFor(TripOrderSetting)
final tripOrderSettingProvider = TripOrderSettingProvider._();

/// The order of the Day screen's trips; the same for every day while the
/// app runs. Starts with [TripOrder.timeAscending].
final class TripOrderSettingProvider
    extends $NotifierProvider<TripOrderSetting, TripOrder> {
  /// The order of the Day screen's trips; the same for every day while the
  /// app runs. Starts with [TripOrder.timeAscending].
  TripOrderSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripOrderSettingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripOrderSettingHash();

  @$internal
  @override
  TripOrderSetting create() => TripOrderSetting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripOrder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripOrder>(value),
    );
  }
}

String _$tripOrderSettingHash() => r'ad7da188388bcadbe7e93d5921b5900ec2d8874b';

/// The order of the Day screen's trips; the same for every day while the
/// app runs. Starts with [TripOrder.timeAscending].

abstract class _$TripOrderSetting extends $Notifier<TripOrder> {
  TripOrder build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TripOrder, TripOrder>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TripOrder, TripOrder>,
              TripOrder,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The id of a just-added trip, highlighted in the list for ~2 s
/// (DESIGN.md §5.5); null otherwise.

@ProviderFor(HighlightedTrip)
final highlightedTripProvider = HighlightedTripProvider._();

/// The id of a just-added trip, highlighted in the list for ~2 s
/// (DESIGN.md §5.5); null otherwise.
final class HighlightedTripProvider
    extends $NotifierProvider<HighlightedTrip, String?> {
  /// The id of a just-added trip, highlighted in the list for ~2 s
  /// (DESIGN.md §5.5); null otherwise.
  HighlightedTripProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'highlightedTripProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$highlightedTripHash();

  @$internal
  @override
  HighlightedTrip create() => HighlightedTrip();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$highlightedTripHash() => r'1177423e3de87601e20baeed2f3452f1207c2df7';

/// The id of a just-added trip, highlighted in the list for ~2 s
/// (DESIGN.md §5.5); null otherwise.

abstract class _$HighlightedTrip extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Saving a new trip. Lives as long as the add-trip screen.

@ProviderFor(AddTripController)
final addTripControllerProvider = AddTripControllerProvider._();

/// Saving a new trip. Lives as long as the add-trip screen.
final class AddTripControllerProvider
    extends $AsyncNotifierProvider<AddTripController, Trip?> {
  /// Saving a new trip. Lives as long as the add-trip screen.
  AddTripControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addTripControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addTripControllerHash();

  @$internal
  @override
  AddTripController create() => AddTripController();
}

String _$addTripControllerHash() => r'2af5345718e445293869d36f9d985e65bce9677c';

/// Saving a new trip. Lives as long as the add-trip screen.

abstract class _$AddTripController extends $AsyncNotifier<Trip?> {
  FutureOr<Trip?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Trip?>, Trip?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Trip?>, Trip?>,
              AsyncValue<Trip?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
