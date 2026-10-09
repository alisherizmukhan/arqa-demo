import 'dart:ui';

import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_providers.g.dart';

/// Where the chosen language is kept.
abstract interface class LocaleStore {
  /// `ru` / `kk`, or null when the user has not chosen yet.
  String? read();

  Future<void> write(String code);
}

/// shared_preferences, loaded before the app starts (so the first frame is
/// already in the chosen language).
final class PrefsLocaleStore implements LocaleStore {
  const new(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'language';

  @override
  String? read() => _prefs.getString(_key);

  @override
  Future<void> write(String code) => _prefs.setString(_key, code);
}

/// Overridden in `main` (and in tests).
@Riverpod(keepAlive: true)
LocaleStore localeStore(Ref ref) =>
    throw UnimplementedError('localeStoreProvider is overridden in main');

/// The phone's languages, most preferred first.
@Riverpod(keepAlive: true)
List<Locale> deviceLocales(Ref ref) => PlatformDispatcher.instance.locales;

/// The app's language: the saved choice; else the phone's language if it is
/// Russian or Kazakh; else Russian. Changing it applies at once.
@Riverpod(keepAlive: true)
class AppLocale extends _$AppLocale {
  @override
  Locale build() {
    final codes = {for (final l in appLocales) l.languageCode};
    final saved = ref.watch(localeStoreProvider).read();
    if (saved != null && codes.contains(saved)) return Locale(saved);
    for (final device in ref.watch(deviceLocalesProvider)) {
      if (codes.contains(device.languageCode)) {
        return Locale(device.languageCode);
      }
    }
    return appLocales.first;
  }

  Future<void> select(String code) async {
    state = Locale(code);
    await ref.read(localeStoreProvider).write(code);
  }
}
