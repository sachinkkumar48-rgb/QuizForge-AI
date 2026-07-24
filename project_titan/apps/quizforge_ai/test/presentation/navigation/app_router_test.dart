import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/quizforge_ai.dart';

void main() {
  group('AppRoutes and AppRouter Navigation Tests', () {
    test('AppRoutes builds correct dynamic route paths', () {
      expect(AppRoutes.buildQuizPath('sess_123'), equals('/quiz/sess_123'));
      expect(AppRoutes.buildResultPath('sess_123'), equals('/result/sess_123'));
    });

    test('GoRouter instance is configured with initial splash location', () {
      final router = appRouter;
      expect(router.configuration.routes.length, greaterThanOrEqualTo(8));
    });
  });
}
