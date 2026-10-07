import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/strings_ru.dart';
import 'package:driver_diary/features/trips/presentation/screens/day_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatelessWidget {
  const new({
    this.home = const DayScreen(),
    this.themeMode = ThemeMode.light,
    super.key,
  });

  /// The first screen (the Day screen; tests may open another one).
  final Widget home;

  /// Light by default, whatever the phone's setting (the dark theme stays
  /// available: tests and screenshots pass [ThemeMode.system]).
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appTitle,
      debugShowCheckedModeBanner: false,
      theme: DkTheme.light(),
      darkTheme: DkTheme.dark(),
      themeMode: themeMode,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    );
  }
}
