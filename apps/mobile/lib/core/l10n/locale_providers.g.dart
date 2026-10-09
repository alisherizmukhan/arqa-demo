// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in `main` (and in tests).

@ProviderFor(localeStore)
final localeStoreProvider = LocaleStoreProvider._();

/// Overridden in `main` (and in tests).

final class LocaleStoreProvider
    extends $FunctionalProvider<LocaleStore, LocaleStore, LocaleStore>
    with $Provider<LocaleStore> {
  /// Overridden in `main` (and in tests).
  LocaleStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeStoreHash();

  @$internal
  @override
  $ProviderElement<LocaleStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocaleStore create(Ref ref) {
    return localeStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocaleStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocaleStore>(value),
    );
  }
}

String _$localeStoreHash() => r'2cc0924c26b4503827f599086e75e0d2307ff581';

/// The phone's languages, most preferred first.

@ProviderFor(deviceLocales)
final deviceLocalesProvider = DeviceLocalesProvider._();

/// The phone's languages, most preferred first.

final class DeviceLocalesProvider
    extends $FunctionalProvider<List<Locale>, List<Locale>, List<Locale>>
    with $Provider<List<Locale>> {
  /// The phone's languages, most preferred first.
  DeviceLocalesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceLocalesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceLocalesHash();

  @$internal
  @override
  $ProviderElement<List<Locale>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Locale> create(Ref ref) {
    return deviceLocales(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Locale> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Locale>>(value),
    );
  }
}

String _$deviceLocalesHash() => r'f107d8a8ee86e8592a70d7764cd33fc5c090e675';

/// The app's language: the saved choice; else the phone's language if it is
/// Russian or Kazakh; else Russian. Changing it applies at once.

@ProviderFor(AppLocale)
final appLocaleProvider = AppLocaleProvider._();

/// The app's language: the saved choice; else the phone's language if it is
/// Russian or Kazakh; else Russian. Changing it applies at once.
final class AppLocaleProvider extends $NotifierProvider<AppLocale, Locale> {
  /// The app's language: the saved choice; else the phone's language if it is
  /// Russian or Kazakh; else Russian. Changing it applies at once.
  AppLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLocaleHash();

  @$internal
  @override
  AppLocale create() => AppLocale();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$appLocaleHash() => r'ab73e5004ac82860573ed293adb01d7fd70148d7';

/// The app's language: the saved choice; else the phone's language if it is
/// Russian or Kazakh; else Russian. Changing it applies at once.

abstract class _$AppLocale extends $Notifier<Locale> {
  Locale build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale, Locale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale, Locale>,
              Locale,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
