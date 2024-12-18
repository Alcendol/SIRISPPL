import 'package:flutter/material.dart';
import 'package:siris/login_page.dart';
import 'package:logging/logging.dart';
import 'package:siris/route/routers.dart';

void main() {
  _initializeLogging();
  runApp(MyApp());
}

void _initializeLogging() {
  Logger.root.level = Level.ALL; // Tampilkan semua level log
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIRIS Login',
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: Routers.generateRoute
    );
  }
}
