import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/quizforge_ai.dart';

void main() {
  group('ThemeProvider Presentation State Tests', () {
    test('Defaults to system theme mode and updates on toggle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeProvider), equals(ThemeMode.system));

      container.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeProvider), equals(ThemeMode.dark));

      container.read(themeProvider.notifier).toggleTheme();
      expect(container.read(themeProvider), equals(ThemeMode.light));
    });
  });
}
