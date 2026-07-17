import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'themes/app_theme.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable debug printing in release builds
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(const QuizForgeApp());
}

class QuizForgeApp extends StatelessWidget {
  const QuizForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuizForge AI',
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}
