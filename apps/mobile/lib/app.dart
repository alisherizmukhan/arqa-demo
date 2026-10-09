import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/core/l10n/locale_providers.dart';
import 'package:driver_diary/features/auth/presentation/screens/app_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const new({
    this.home = const AppRoot(),
    this.themeMode = ThemeMode.light,
    super.key,
  });

  /// The first screen: [AppRoot] (login or the role's home; tests may open
  /// another one).
  final Widget home;

  /// Light by default, whatever the phone's setting (the dark theme stays
  /// available: tests and screenshots pass [ThemeMode.system]).
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: DkTheme.light(),
      darkTheme: DkTheme.dark(),
      themeMode: themeMode,
      locale: ref.watch(appLocaleProvider),
      supportedLocales: appLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Amounts are spoken in the active language («3 315 тенге»).
      builder: (context, child) => DkMoneySemantics(
        label: context.l10n.moneySpoken,
        child: child ?? const SizedBox.shrink(),
      ),
      home: home,
    );
  }
}
