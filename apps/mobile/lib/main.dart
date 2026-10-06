import 'package:driver_diary/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      // No automatic provider retries: dio already retries transient network
      // errors, and the UI offers an explicit "Повторить".
      retry: (retryCount, error) => null,
      child: const App(),
    ),
  );
}
