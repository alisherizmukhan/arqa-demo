import 'package:dio/dio.dart';
import 'package:driver_diary/core/config/app_config.dart';
import 'package:driver_diary/core/network/dio_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Build-time configuration (`--dart-define`).
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => AppConfig.fromEnvironment();

/// The HTTP client, shared by all features.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = createDio(ref.watch(appConfigProvider));
  ref.onDispose(dio.close);
  return dio;
}

/// The current time. Overridden in tests to pin "today".
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;
