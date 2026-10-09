import 'package:driver_diary/app.dart';
import 'package:driver_diary/core/l10n/locale_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read before the first frame, so it is drawn in the chosen language.
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        localeStoreProvider.overrideWithValue(PrefsLocaleStore(prefs)),
      ],
      // No automatic provider retries: dio already retries transient network
      // errors, and the UI offers an explicit "Повторить".
      retry: (retryCount, error) => null,
      child: const App(),
    ),
  );
}
