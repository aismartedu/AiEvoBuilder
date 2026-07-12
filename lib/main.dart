import 'package:flutter/material.dart';
import 'widgets/auth_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AiEvoBuilderApp());
}

class AiEvoBuilderApp extends StatelessWidget {
  const AiEvoBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Evo Builder',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E), foregroundColor: Colors.white),
      ),
      home: const AuthWrapper(),
    );
  }
}
