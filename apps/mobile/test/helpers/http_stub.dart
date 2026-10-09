import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Answers every request with [status], [body] and [headers]; records the
/// request headers. While [hold] is set, answers wait for it.
class StubAdapter implements HttpClientAdapter {
  new(this.status);

  int status;
  Map<String, Object?> body = const {};
  Map<String, List<String>> headers = const {};
  final List<Map<String, dynamic>> requestHeaders = [];
  Completer<void>? hold;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestHeaders.add(Map.of(options.headers));
    await hold?.future;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// The API's error body.
Map<String, Object?> apiError(String code, String message) => {
  'error': {'code': code, 'message': message, 'field': null},
};
