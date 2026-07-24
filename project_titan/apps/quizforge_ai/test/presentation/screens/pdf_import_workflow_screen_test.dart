import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quizforge_ai/quizforge_ai.dart';
import 'package:quizforge_ai/src/presentation/screens/home_screen.dart';
import 'package:quizforge_ai/src/presentation/screens/import_pdf_screen.dart';
import 'package:quizforge_ai/src/presentation/screens/quiz_loading_screen.dart';
import 'package:titan_core/titan_core.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';

import '../../support/mock_backend.dart';

void main() {
  group('PDF Import Workflow Screen Tests', () {
    tearDown(() {
      TitanServiceLocator.instance.reset();
    });

    testWidgets(
        'Home displays import button, filename, and disabled Start Quiz',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.text('Import PDF'), findsOneWidget);
      expect(find.text('Selected PDF: No PDF selected'), findsOneWidget);

      final startButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start Quiz'),
      );
      expect(startButton.onPressed, isNull);
    });

    testWidgets('Import screen enables generation when a PDF is selected',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quizProvider.overrideWith(_ReadyToGenerateWorkflowNotifier.new),
          ],
          child: const MaterialApp(
            home: ImportPdfScreen(),
          ),
        ),
      );

      expect(find.text('polity.pdf'), findsOneWidget);

      final generateButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Generate Quiz'),
      );
      expect(generateButton.onPressed, isNotNull);
    });

    testWidgets('Loading screen displays progress and retry on friendly error',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quizProvider.overrideWith(_ErrorWorkflowNotifier.new),
          ],
          child: const MaterialApp(
            home: QuizLoadingScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('We could not prepare your quiz. Please try again.'),
          findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('Complete workflow navigates from loading to quiz screen',
        (tester) async {
      final coordinator = await buildMockCoordinator();
      TitanServiceLocator.instance.registerSingleton<ApplicationCoordinator>(
        coordinator,
        allowOverride: true,
      );

      final router = GoRouter(
        initialLocation: AppRoutes.quizLoadingPath,
        routes: [
          GoRoute(
            name: AppRoutes.quizLoading,
            path: AppRoutes.quizLoadingPath,
            builder: (context, state) => const QuizLoadingScreen(),
          ),
          GoRoute(
            name: AppRoutes.quiz,
            path: AppRoutes.quizPath,
            builder: (context, state) =>
                Text('Quiz ${state.pathParameters['id']}'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quizProvider.overrideWith(_SelectedPdfWorkflowNotifier.new),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Quiz session_'), findsOneWidget);
    });
  });
}

class _ReadyToGenerateWorkflowNotifier extends QuizAsyncNotifier {
  @override
  QuizWorkflowState build() {
    return const QuizWorkflowState(
      stage: QuizWorkflowStage.idle,
      selectedFilePath: 'C:/docs/polity.pdf',
      selectedFileName: 'polity.pdf',
    );
  }
}

class _SelectedPdfWorkflowNotifier extends QuizAsyncNotifier {
  @override
  QuizWorkflowState build() {
    return const QuizWorkflowState(
      stage: QuizWorkflowStage.idle,
      selectedFilePath: 'C:/docs/polity.pdf',
      selectedFileName: 'polity.pdf',
    );
  }
}

class _ErrorWorkflowNotifier extends QuizAsyncNotifier {
  @override
  QuizWorkflowState build() {
    return const QuizWorkflowState(
      stage: QuizWorkflowStage.error,
      selectedFilePath: 'C:/docs/polity.pdf',
      selectedFileName: 'polity.pdf',
      errorMessage: 'We could not prepare your quiz. Please try again.',
    );
  }

  @override
  Future<QuizSession?> createQuizFromPdf([String? filePath]) async {
    state = state.copyWith(
      stage: QuizWorkflowStage.error,
      errorMessage: 'We could not prepare your quiz. Please try again.',
    );
    return null;
  }
}
