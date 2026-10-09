import 'dart:async';

import 'package:dio/dio.dart';
import 'package:driver_diary/core/config/app_config.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/network/auth_interceptor.dart';
import 'package:driver_diary/core/network/dio_client.dart';
import 'package:driver_diary/core/network/failure_mapper.dart';
import 'package:driver_diary/core/time/driver_zone.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/http_stub.dart';

void main() {
  late AuthGate gate;
  late Dio dio;
  late StubAdapter adapter;
  late List<void> expired;
  late StreamSubscription<void> subscription;

  setUp(() {
    gate = AuthGate();
    dio = createDio(
      const AppConfig(apiUrl: 'http://api', driverZone: DriverZone.kazakhstan),
      gate,
    );
    adapter = StubAdapter(200);
    dio.httpClientAdapter = adapter;
    expired = [];
    subscription = gate.expired.listen(expired.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await gate.dispose();
  });

  test('sends the bearer token, and nothing when signed out', () async {
    await dio.get<void>('/a');
    gate.token = 'secret-token';
    await dio.get<void>('/b');

    expect(adapter.requestHeaders[0].containsKey('Authorization'), isFalse);
    expect(adapter.requestHeaders[1]['Authorization'], 'Bearer secret-token');
  });

  test('a 401 for the token in use ends the session', () async {
    gate.token = 'secret-token';
    adapter.status = 401;

    await expectLater(dio.get<void>('/trips'), throwsA(isA<DioException>()));

    expect(expired, hasLength(1));
  });

  test('no signal for a quiet request (logout) or a stale token', () async {
    gate.token = 'old';
    adapter
      ..status = 401
      ..hold = Completer<void>();
    final late = dio.get<void>('/trips');
    await pumpEventQueue();
    expect(adapter.requestHeaders.single['Authorization'], 'Bearer old');
    gate.token = 'new'; // signed in again while the request was in flight
    adapter.hold!.complete();
    adapter.hold = null;
    await expectLater(late, throwsA(isA<DioException>()));
    await expectLater(
      dio.post<void>(
        '/auth/logout',
        options: Options(extra: {...AuthInterceptor.quiet}),
      ),
      throwsA(isA<DioException>()),
    );

    expect(expired, isEmpty);
  });

  test(
    'a 401 without a token (wrong password at login) is no signal',
    () async {
      adapter
        ..status = 401
        ..body = {
          'error': {
            'code': 'invalid_credentials',
            'message': 'invalid login or password',
            'field': null,
          },
        };

      final error = await dio
          .post<void>('/auth/login')
          .then<DioException?>(
            (_) => null,
            onError: (Object e) => e as DioException,
          );

      expect(expired, isEmpty);
      expect(
        failureFromDio(error!),
        isA<UnauthorizedFailure>().having(
          (f) => f.code,
          'code',
          'invalid_credentials',
        ),
      );
    },
  );

  test('statuses map to failures by error code', () {
    Failure map(int status, String code) => failureFromDio(
      DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: status,
          data: {
            'error': {'code': code, 'message': 'm', 'field': null},
          },
        ),
      ),
    );

    expect(map(403, 'account_disabled'), isA<ForbiddenFailure>());
    expect(map(429, 'rate_limited'), isA<RateLimitedFailure>());
    expect(
      map(409, 'withdrawal_conflict'),
      isA<ConflictFailure>().having(
        (f) => f.code,
        'code',
        'withdrawal_conflict',
      ),
    );
    expect(
      map(422, 'insufficient_funds'),
      isA<ValidationFailure>().having(
        (f) => f.code,
        'code',
        'insufficient_funds',
      ),
    );
  });
}
