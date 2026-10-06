import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Дневник смены',
      home: Scaffold(body: Center(child: Text('Дневник смены'))),
    );
  }
}
