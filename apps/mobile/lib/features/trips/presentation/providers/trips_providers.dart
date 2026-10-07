import 'dart:async';

import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/providers.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:driver_diary/features/trips/data/datasources/trips_remote_data_source.dart';
import 'package:driver_diary/features/trips/data/repositories/trips_repository_impl.dart';
import 'package:driver_diary/features/trips/domain/entities/daily_summary.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/repositories/trips_repository.dart';
import 'package:driver_diary/features/trips/domain/usecases/create_trip.dart';
import 'package:driver_diary/features/trips/domain/usecases/get_day_trips.dart';
import 'package:driver_diary/features/trips/presentation/error_messages.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trips_providers.g.dart';

@Riverpod(keepAlive: true)
TripsRepository tripsRepository(Ref ref) =>
    TripsRepositoryImpl(TripsRemoteDataSource(ref.watch(dioProvider)));

@Riverpod(keepAlive: true)
DriverZone driverZone(Ref ref) => ref.watch(appConfigProvider).driverZone;

/// Today in the driver's zone (not the phone's).
@riverpod
CalendarDay today(Ref ref) =>
    ref.watch(driverZoneProvider).dayOf(ref.watch(clockProvider)());

/// The day the user is looking at. Starts at today; never goes past today.
@Riverpod(keepAlive: true)
class SelectedDay extends _$SelectedDay {
  @override
  CalendarDay build() => _today;

  CalendarDay get _today =>
      ref.read(driverZoneProvider).dayOf(ref.read(clockProvider)());

  void previous() => state = state.addDays(-1);

  void next() {
    if (state.isBefore(_today)) state = state.addDays(1);
  }

  void today() => state = _today;

  void select(CalendarDay day) => state = day.isAfter(_today) ? _today : day;
}

/// How long a viewed day stays cached after the screen leaves it: going
/// back to it within this time shows it at once (no skeleton).
const dayCacheTtl = Duration(minutes: 5);

/// Trips of [day], ordered by start. Cached for [dayCacheTtl] after its last
/// listener goes; a failed load is not cached.
@riverpod
Future<List<Trip>> dayTrips(Ref ref, CalendarDay day) async {
  final link = ref.keepAlive();
  final timer = Timer(dayCacheTtl, link.close);
  ref.onDispose(timer.cancel);
  final zone = ref.watch(driverZoneProvider);
  final result = await GetDayTrips(ref.watch(tripsRepositoryProvider))(
    day,
    zone,
  );
  switch (result) {
    case Ok(:final value):
      return value;
    case Err(:final failure):
      link.close();
      throw failure;
  }
}

/// Summary of [day], computed from the same trips the list shows, so the
/// card and the list can never disagree.
@riverpod
Future<DailySummary> daySummary(Ref ref, CalendarDay day) async {
  final zone = ref.watch(driverZoneProvider);
  final trips = await ref.watch(dayTripsProvider(day).future);
  return calculateDailySummary(day, trips, zone);
}

/// The id of a just-added trip, highlighted in the list for ~2 s
/// (DESIGN.md §5.5); null otherwise.
@Riverpod(keepAlive: true)
class HighlightedTrip extends _$HighlightedTrip {
  Timer? _timer;

  @override
  String? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void flash(String id) {
    _timer?.cancel();
    state = id;
    _timer = Timer(DkMotion.highlight, () => state = null);
  }
}

/// Saving a new trip. Lives as long as the add-trip screen.
@riverpod
class AddTripController extends _$AddTripController {
  /// The last attempt whose outcome is unknown (network/server error): the
  /// request may have reached the server, so a retry must reuse its id.
  Trip? _unconfirmed;

  @override
  FutureOr<Trip?> build() => null;

  /// Saves [draft]. If [draft] has the same payload as an unconfirmed
  /// previous attempt, that attempt's id is reused, so the server returns the
  /// stored trip (200) instead of creating a duplicate.
  ///
  /// [quietly] (automatic resends) keeps the state out of loading, so the
  /// form stays editable.
  Future<Result<Trip>> save(Trip draft, {bool quietly = false}) async {
    final previous = _unconfirmed;
    final trip = previous != null && previous.hasSamePayload(draft)
        ? draft.withId(previous.id)
        : draft;

    if (!quietly) state = const AsyncLoading();
    final result = await CreateTrip(ref.read(tripsRepositoryProvider))(
      trip,
      ref.read(driverZoneProvider),
    );
    if (!ref.mounted) return result;

    switch (result) {
      case Ok(:final value):
        _unconfirmed = null;
        ref.invalidate(dayTripsProvider);
        state = AsyncData(value);
      case Err(:final failure):
        // Only a transient failure leaves the outcome unknown.
        _unconfirmed = isTransient(failure) ? trip : null;
        state = AsyncError(failure, StackTrace.current);
    }
    return result;
  }
}
