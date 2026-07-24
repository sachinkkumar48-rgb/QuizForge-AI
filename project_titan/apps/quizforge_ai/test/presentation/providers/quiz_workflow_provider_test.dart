import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/quizforge_ai.dart';
import 'package:titan_core/titan_core.dart';

import '../../support/mock_backend.dart';

void main() {
  group('QuizWorkflow Provider State Tests', () {
    tearDown(() {
      TitanServiceLocator.instance.reset();
    });

    test('moves to error when no PDF has been selected', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final session =
          await container.read(quizProvider.notifier).createQuizFromPdf();

      expect(session, isNull);
      expect(container.read(quizProvider).stage, QuizWorkflowStage.error);
      expect(
          container.read(quizProvider).errorMessage, contains('Select a PDF'));
    });

    test('creates a quiz session through ApplicationCoordinator', () async {
      final coordinator = await buildMockCoordinator();
      TitanServiceLocator.instance.registerSingleton<ApplicationCoordinator>(
        coordinator,
        allowOverride: true,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final session = await container
          .read(quizProvider.notifier)
          .createQuizFromPdf('C:/docs/polity.pdf');

      expect(session, isNotNull);
      expect(container.read(quizProvider).stage, QuizWorkflowStage.ready);
      expect(container.read(quizProvider).canStartQuiz, isTrue);
    });
  });
}
