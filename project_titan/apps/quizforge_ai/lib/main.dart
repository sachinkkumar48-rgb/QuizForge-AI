import 'package:flutter/material.dart';
import 'package:titan_core/titan_core.dart';
import 'quizforge_ai.dart';

Future<void> main() async {
  final locator = TitanServiceLocator.instance;
  locator.reset();
  final bootstrap = QuizForgeAppBootstrap();
  await bootstrap.initialize();
  runApp(const QuizForgeApp());
}
