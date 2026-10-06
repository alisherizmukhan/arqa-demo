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

/// The day the user is looking at. Starts at today; never goes past today.

@ProviderFor(SelectedDay)
final selectedDayProvider = SelectedDayProvider._();

/// The day the user is looking at. Starts at today; never goes past today.
final class SelectedDayProvider
    extends $NotifierProvider<SelectedDay, CalendarDay> {
  /// The day the user is looking at. Starts at today; never goes past today.
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

String _$selectedDayHash() => r'a8e40a697829ed7cf7fd4e72f9f37095561a0063';

/// The day the user is looking at. Starts at today; never goes past today.

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

/// Trips of the selected day, ordered by start.

@ProviderFor(dayTrips)
final dayTripsProvider = DayTripsProvider._();

/// Trips of the selected day, ordered by start.

final class DayTripsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Trip>>,
          List<Trip>,
          FutureOr<List<Trip>>
        >
    with $FutureModifier<List<Trip>>, $FutureProvider<List<Trip>> {
  /// Trips of the selected day, ordered by start.
  DayTripsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dayTripsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dayTripsHash();

  @$internal
  @override
  $FutureProviderElement<List<Trip>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Trip>> create(Ref ref) {
    return dayTrips(ref);
  }
}

String _$dayTripsHash() => r'5cd24dd24453ae5809571d647261dd27775708cd';

/// Summary of the selected day, computed from the same trips the list shows,
/// so the card and the list can never disagree.

@ProviderFor(daySummary)
final daySummaryProvider = DaySummaryProvider._();

/// Summary of the selected day, computed from the same trips the list shows,
/// so the card and the list can never disagree.

final class DaySummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailySummary>,
          DailySummary,
          FutureOr<DailySummary>
        >
    with $FutureModifier<DailySummary>, $FutureProvider<DailySummary> {
  /// Summary of the selected day, computed from the same trips the list shows,
  /// so the card and the list can never disagree.
  DaySummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'daySummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$daySummaryHash();

  @$internal
  @override
  $FutureProviderElement<DailySummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DailySummary> create(Ref ref) {
    return daySummary(ref);
  }
}

String _$daySummaryHash() => r'41207b0e48f5bf3e13ce711b6cf9590df6c1f514';

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
