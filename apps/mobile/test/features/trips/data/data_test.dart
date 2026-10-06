import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/network/retry_interceptor.dart';
import 'package:driver_diary/features/trips/data/datasources/trips_remote_data_source.dart';
import 'package:driver_diary/features/trips/data/repositories/trips_repository_impl.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

typedef Handler = ResponseBody Function(RequestOptions options);

/// Serves canned responses in order and records every request.
class FakeAdapter implements HttpClientAdapter {
  new(this.handlers);

  final List<Handler> handlers;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final index = requests.length - 1;
    return handlers[index < handlers.length ? index : handlers.length - 1](
      options,
    );
  }

  @override
  void close({bool force = false}) {}
}

Handler json(Object body, {int status = 200}) =>
    (_) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Handler connectionError() =>
    (options) => throw DioException.connectionError(
      requestOptions: options,
      reason: 'offline',
    );

const Map<String, Object> t1Json = {
  'id': 't1',
  'start': '2026-10-01T08:10:00+05:00',
  'end': '2026-10-01T08:32:00+05:00',
  'amount': 2400,
  'payment': 'card',
  'commission': 360,
  'net': 2040,
};

(TripsRepositoryImpl, FakeAdapter) build(List<Handler> handlers) {
  final adapter = FakeAdapter(handlers);
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.add(
    RetryInterceptor(dio, delays: const [Duration.zero, Duration.zero]),
  );
  return (TripsRepositoryImpl(TripsRemoteDataSource(dio)), adapter);
}

void main() {
  group('tripsForDay', () {
    test('sends date and tz, parses trips into UTC instants', () async {
      final (repo, adapter) = build([
        json({
          'date': '2026-10-01',
          'tz': '+05:00',
          'trips': [t1Json],
        }),
      ]);

      final result = await repo.tripsForDay(referenceDay, kz);

      expect((result as Ok<List<Trip>>).value, [t1]);
      expect(adapter.requests.single.path, '/trips');
      expect(adapter.requests.single.queryParameters, {
        'date': '2026-10-01',
        'tz': '+05:00',
      });
    });

    test('a network failure is retried, then succeeds', () async {
      final (repo, adapter) = build([
        connectionError(),
        connectionError(),
        json({
          'date': '2026-10-01',
          'tz': '+05:00',
          'trips': [t1Json],
        }),
      ]);

      expect(await repo.tripsForDay(referenceDay, kz), isA<Ok<List<Trip>>>());
      expect(adapter.requests, hasLength(3));
    });

    test('gives up after the retries with a NetworkFailure', () async {
      final (repo, adapter) = build([connectionError()]);

      final result = await repo.tripsForDay(referenceDay, kz);

      expect((result as Err).failure, isA<NetworkFailure>());
      expect(adapter.requests, hasLength(3));
    });

    test('503 is retried, then reported as a ServerFailure', () async {
      final (repo, adapter) = build([
        json({'detail': 'unavailable'}, status: 503),
      ]);

      final result = await repo.tripsForDay(referenceDay, kz);

      expect((result as Err).failure, isA<ServerFailure>());
      expect(adapter.requests, hasLength(3));
    });

    test('an unknown payment method is an unexpected failure', () async {
      final (repo, _) = build([
        json({
          'date': '2026-10-01',
          'tz': '+05:00',
          'trips': [
            {...t1Json, 'payment': 'crypto'},
          ],
        }),
      ]);

      final result = await repo.tripsForDay(referenceDay, kz);

      expect((result as Err).failure, isA<UnexpectedFailure>());
    });

    test('a response of the wrong shape is an unexpected failure', () async {
      final (repo, _) = build([
        json({'date': '2026-10-01'}),
      ]);

      final result = await repo.tripsForDay(referenceDay, kz);

      expect((result as Err).failure, isA<UnexpectedFailure>());
    });
  });

  group('createTrip', () {
    test('posts the trip with the driver offset', () async {
      final (repo, adapter) = build([json(t1Json, status: 201)]);

      final result = await repo.createTrip(t1, kz);

      expect((result as Ok<Trip>).value, t1);
      expect(adapter.requests.single.data, {
        'id': 't1',
        'start': '2026-10-01T08:10:00+05:00',
        'end': '2026-10-01T08:32:00+05:00',
        'amount': 2400,
        'payment': 'card',
        'commission': 360,
      });
    });

    test('200 (already stored) is a success too', () async {
      final (repo, _) = build([json(t1Json)]);

      expect(await repo.createTrip(t1, kz), isA<Ok<Trip>>());
    });

    test('a network failure is reported at once (no dio retries)', () async {
      // The form retries on its own schedule with the same id.
      final (repo, adapter) = build([connectionError(), json(t1Json)]);

      final result = await repo.createTrip(t1, kz);

      expect((result as Err).failure, isA<NetworkFailure>());
      expect(adapter.requests, hasLength(1));
    });

    test('422 maps to a ValidationFailure with code and field', () async {
      final (repo, adapter) = build([
        json({
          'error': {
            'code': 'commission_exceeds_amount',
            'message': 'commission must not exceed amount',
            'field': 'commission',
          },
        }, status: 422),
      ]);

      final result = await repo.createTrip(t1, kz);

      expect(
        (result as Err).failure,
        isA<ValidationFailure>()
            .having((f) => f.code, 'code', 'commission_exceeds_amount')
            .having((f) => f.field, 'field', 'commission'),
      );
      expect(adapter.requests, hasLength(1), reason: '4xx is not retried');
    });

    test('409 maps to a ConflictFailure', () async {
      final (repo, _) = build([
        json({
          'error': {
            'code': 'trip_conflict',
            'message': "trip 't1' already exists with a different payload",
            'field': 'id',
          },
        }, status: 409),
      ]);

      expect(
        (await repo.createTrip(t1, kz) as Err).failure,
        isA<ConflictFailure>(),
      );
    });

    test('503 is reported at once as a ServerFailure', () async {
      final (repo, adapter) = build([
        json({'detail': 'unavailable'}, status: 503),
      ]);

      final result = await repo.createTrip(t1, kz);

      expect(
        (result as Err).failure,
        isA<ServerFailure>().having((f) => f.statusCode, 'status', 503),
      );
      expect(adapter.requests, hasLength(1));
    });
  });
}
