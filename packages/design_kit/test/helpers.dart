import 'package:design_kit/design_kit.dart';
import 'package:flutter/material.dart';

/// Wraps [child] in a MaterialApp with a kit theme, scrollable.
Widget wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? DkTheme.light(),
    home: Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [child]),
      ),
    ),
  );
}
