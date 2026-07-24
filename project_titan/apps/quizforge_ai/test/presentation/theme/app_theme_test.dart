import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/quizforge_ai.dart';

void main() {
  group('AppTheme Presentation Tests', () {
    test('Light theme configures Material 3 and light color scheme', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.primary, equals(AppColors.primaryLight));
    });

    test('Dark theme configures Material 3 and dark color scheme', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.colorScheme.primary, equals(AppColors.primaryDark));
    });
  });
}
