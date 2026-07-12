import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'home_screen.dart';
import 'background_service.dart';
import 'overlay_entry.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundService.init();
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jarvis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF05070D),
        primaryColor: const Color(0xFF00E5FF),
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF0B0F1A),
        ),
      ),
      home: WithForegroundTask(child: const HomeScreen()),
    );
  }
}
