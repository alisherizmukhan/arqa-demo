import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/features/trips/presentation/screens/day_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Дневник смены',
      debugShowCheckedModeBanner: false,
      theme: DkTheme.light(),
      darkTheme: DkTheme.dark(),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const DayScreen(),
    );
  }
}
