import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/quizforge_ai.dart';

import '../support/mock_backend.dart';

void main() {
  group('ApplicationCoordinator PDF Import Workflow Tests', () {
    test('reports progress states and returns a ready session', () async {
      final coordinator = await buildMockCoordinator();
      final stages = <QuizWorkflowStage>[];

      final session = await coordinator.importPdf(
        filePath: 'C:/docs/polity.pdf',
        onStageChanged: stages.add,
      );

      expect(session.sessionId, isNotEmpty);
      expect(
        stages,
        containsAllInOrder([
          QuizWorkflowStage.importingPdf,
          QuizWorkflowStage.extractingText,
          QuizWorkflowStage.creatingChunks,
          QuizWorkflowStage.generatingQuiz,
          QuizWorkflowStage.creatingSession,
          QuizWorkflowStage.ready,
        ]),
      );
    });
  });
}
