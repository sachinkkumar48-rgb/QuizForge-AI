/// P40 Learner Workflow UI Integration Test Suite.
///
/// Exercises the Flutter user interface for the adaptive practice flow:
/// Question presentation -> option selection -> answer submission -> feedback
/// -> next question navigation -> completion metrics & remedial suggestions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:quizforge_upsc/core/di/service_locator_init.dart';
import 'package:quizforge_upsc/pages/adaptive_practice_page.dart';
import 'package:titan_core/titan_core.dart';

void main() {
  group('P40 Learner Workflow UI Integration Tests', () {
    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService sessionRecoveryService;
    late AdaptiveLearningStateReconciliationPipeline reconciliationPipeline;
    late AdaptiveLearningJourneyOrchestrator orchestrator;
    late AdaptiveLearningJourneyController controller;
    late List<NormalizedQuestion> testCorpus;

    NormalizedQuestion makeQuestion({
      required String id,
      required String correctOption,
      String topic = 'Fundamental Rights',
      String difficulty = 'Medium',
    }) {
      return NormalizedQuestion(
        id: id,
        examId: 'upsc_prelims_gs1',
        year: 2024,
        paper: 'GS1',
        subject: 'Polity',
        topic: topic,
        normalizedText: 'UI Test Question Text for $id',
        originalText: 'Original Text for $id',
        options: [
          Option(
              key: 'A',
              text: 'First Option Text for $id',
              isCorrect: correctOption == 'A'),
          Option(
              key: 'B',
              text: 'Second Option Text for $id',
              isCorrect: correctOption == 'B'),
          Option(
              key: 'C',
              text: 'Third Option Text for $id',
              isCorrect: correctOption == 'C'),
          Option(
              key: 'D',
              text: 'Fourth Option Text for $id',
              isCorrect: correctOption == 'D'),
        ],
        officialAnswer: Answer(
          correctOptionKeys: [correctOption],
          officialAnswerSource: 'UPSC Answer Key',
        ),
        explanation: 'Official explanation for question $id',
        difficulty: difficulty,
        source: PyqSourceReference.official(
          examId: 'upsc_prelims_gs1',
          year: 2024,
          paper: 'GS1',
        ),
        objectiveIds: const ['lo_polity_fr_01'],
      );
    }

    setUp(() {
      TitanServiceLocator.instance.reset();

      authRepo = InMemoryAuthoritativeLearningStateRepository();
      checkpointRepo = InMemorySessionCheckpointRepository();
      authRecoveryService =
          AuthoritativeLearningStateRecoveryService(repository: authRepo);
      sessionRecoveryService = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: authRecoveryService,
      );
      reconciliationPipeline = AdaptiveLearningStateReconciliationPipeline(
        repository: authRepo,
        recoveryService: authRecoveryService,
        reconciler: const AdaptiveLearningStateReconciler(),
        proposer: const LearningStateUpdateProposer(),
        consolidator: const PracticeOutcomeConsolidator(),
      );
      orchestrator = AdaptiveLearningJourneyOrchestrator(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
        reconciliationPipeline: reconciliationPipeline,
      );
      controller =
          AdaptiveLearningJourneyController(orchestrator: orchestrator);

      setupServiceLocator();
      TitanServiceLocator.instance
          .registerLazySingleton<AuthoritativeLearningStateRepository>(
        () => authRepo,
        allowOverride: true,
      );
      TitanServiceLocator.instance
          .registerLazySingleton<SessionCheckpointRepository>(
        () => checkpointRepo,
        allowOverride: true,
      );
      TitanServiceLocator.instance
          .registerLazySingleton<AdaptiveLearningJourneyOrchestrator>(
        () => orchestrator,
        allowOverride: true,
      );

      testCorpus = [
        makeQuestion(id: 'ui_q_01', correctOption: 'A'),
        makeQuestion(id: 'ui_q_02', correctOption: 'B'),
      ];
    });

    testWidgets(
        '1. UI Question Presentation: displays stem, options, progress, and submit button',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptivePracticePage(
            controller: controller,
            corpus: testCorpus,
            questionCount: 2,
            targetTopic: 'Fundamental Rights',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Adaptive Drill: Fundamental Rights'),
          findsOneWidget);
      expect(find.textContaining('Question 1 of 2'), findsOneWidget);
      expect(find.textContaining('UI Test Question Text for ui_q_01'),
          findsOneWidget);
      expect(
          find.textContaining('First Option Text for ui_q_01'), findsOneWidget);
      expect(find.textContaining('Second Option Text for ui_q_01'),
          findsOneWidget);
      expect(
          find.widgetWithText(FilledButton, 'Submit Answer'), findsOneWidget);
    });

    testWidgets(
        '2. UI Answer Submission & Feedback: selecting option, submitting answer displays feedback',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptivePracticePage(
            controller: controller,
            corpus: testCorpus,
            questionCount: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Option A
      await tester.tap(find.textContaining('First Option Text for ui_q_01'));
      await tester.pumpAndSettle();

      // Tap Submit Answer
      await tester.tap(find.widgetWithText(FilledButton, 'Submit Answer'));
      await tester.pumpAndSettle();

      // Feedback card appears
      expect(find.textContaining('Correct! Well done.'), findsOneWidget);
      expect(find.textContaining('Official explanation for question ui_q_01'),
          findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Continue to Next Question'),
          findsOneWidget);
    });

    testWidgets('3. UI Next Question Progression: advancing to question 2',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptivePracticePage(
            controller: controller,
            corpus: testCorpus,
            questionCount: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Answer Q1
      await tester.tap(find.textContaining('First Option Text for ui_q_01'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Submit Answer'));
      await tester.pumpAndSettle();

      // Advance to Q2
      await tester
          .tap(find.widgetWithText(FilledButton, 'Continue to Next Question'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Question 2 of 2'), findsOneWidget);
      expect(find.textContaining('UI Test Question Text for ui_q_02'),
          findsOneWidget);
    });

    testWidgets(
        '4. UI Session Completion: finishing all questions displays completion metrics and actions',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptivePracticePage(
            controller: controller,
            corpus: testCorpus,
            questionCount: 2,
            targetTopic: 'Fundamental Rights',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Q1: Answer A (Correct)
      await tester.tap(find.textContaining('First Option Text for ui_q_01'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Submit Answer'));
      await tester.pumpAndSettle();
      await tester
          .tap(find.widgetWithText(FilledButton, 'Continue to Next Question'));
      await tester.pumpAndSettle();

      // Q2: Answer C (Incorrect, correct is B)
      await tester.tap(find.textContaining('Third Option Text for ui_q_02'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Submit Answer'));
      await tester.pumpAndSettle();

      // Completion screen
      expect(find.text('Adaptive Session Completed!'), findsOneWidget);
      expect(find.textContaining('Authoritative state updated to Revision'),
          findsOneWidget);
      expect(find.text('50%'), findsOneWidget); // 1 of 2 correct
      expect(find.text('Remedial Recommendation'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Dashboard'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Continue Learning'),
          findsOneWidget);
    });

    testWidgets(
        '5. UI Error Edge Case: empty corpus renders friendly retry view',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptivePracticePage(
            controller: controller,
            corpus: const [],
            questionCount: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to Start Session'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
    });
  });
}
