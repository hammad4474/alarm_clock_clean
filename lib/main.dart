import 'package:alarm_clock_clean/views/home_screen.dart';
import 'package:alarm_clock_clean/services/alarm_service.dart';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await AlarmService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarm Clock',
      theme: ThemeData(
        fontFamily: 'DS-Digital',
        textTheme: const TextTheme(
          // Define text styles for different text types
          displayLarge: TextStyle(fontFamily: 'DS-Digital'),
          displayMedium: TextStyle(fontFamily: 'DS-Digital'),
          displaySmall: TextStyle(fontFamily: 'DS-Digital'),
          headlineLarge: TextStyle(fontFamily: 'DS-Digital'),
          headlineMedium: TextStyle(fontFamily: 'DS-Digital'),
          headlineSmall: TextStyle(fontFamily: 'DS-Digital'),
          titleLarge: TextStyle(fontFamily: 'DS-Digital'),
          titleMedium: TextStyle(fontFamily: 'DS-Digital'),
          titleSmall: TextStyle(fontFamily: 'DS-Digital'),
          bodyLarge: TextStyle(fontFamily: 'DS-Digital'),
          bodyMedium: TextStyle(fontFamily: 'DS-Digital'),
          bodySmall: TextStyle(fontFamily: 'DS-Digital'),
          labelLarge: TextStyle(fontFamily: 'DS-Digital'),
          labelMedium: TextStyle(fontFamily: 'DS-Digital'),
          labelSmall: TextStyle(fontFamily: 'DS-Digital'),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
