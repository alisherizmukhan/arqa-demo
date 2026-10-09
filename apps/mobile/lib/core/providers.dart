import 'package:dio/dio.dart';
import 'package:driver_diary/core/config/app_config.dart';
import 'package:driver_diary/core/network/auth_interceptor.dart';
import 'package:driver_diary/core/network/dio_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Build-time configuration (`--dart-define`).
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => AppConfig.fromEnvironment();

/// The session token for requests and the "session ended" signal.
@Riverpod(keepAlive: true)
AuthGate authGate(Ref ref) {
  final gate = AuthGate();
  ref.onDispose(gate.dispose);
  return gate;
}

/// The HTTP client, shared by all features.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = createDio(
    ref.watch(appConfigProvider),
    ref.watch(authGateProvider),
  );
  ref.onDispose(dio.close);
  return dio;
}

/// The current time. Overridden in tests to pin "today".
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;
