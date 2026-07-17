import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/pages/home_page.dart';
import 'package:quizforge_upsc/pages/history_page.dart';
import 'package:quizforge_upsc/pages/library_page.dart';
import 'package:quizforge_upsc/repositories/quiz_history_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_session_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_source_repository.dart';
import 'package:quizforge_upsc/models/quiz_attempt.dart';
import 'package:quizforge_upsc/models/quiz_source.dart';
import 'package:quizforge_upsc/models/quiz_session.dart';

class FakeQuizSourceRepository implements QuizSourceRepository {
  @override
  Future<void> saveSource(QuizSource source) async {}
  @override
  Future<List<QuizSource>> getSources() async => [];
  @override
  Future<void> updateSource(QuizSource source) async {}
  @override
  Future<void> deleteSource(String id) async {}
  @override
  Future<void> toggleFavorite(String id) async {}
}

class FakeQuizHistoryRepository implements QuizHistoryRepository {
  @override
  Future<void> saveAttempt(QuizAttempt attempt) async {}
  @override
  Future<List<QuizAttempt>> getAttempts() async => [];
  @override
  Future<void> deleteAttempt(String id) async {}
  @override
  Future<void> clearHistory() async {}
}

class FakeQuizSessionRepository implements QuizSessionRepository {
  @override
  Future<void> saveSession(QuizSession session) async {}
  @override
  Future<QuizSession?> loadSession() async => null;
  @override
  Future<void> deleteSession() async {}
  @override
  Future<bool> hasActiveSession() async => false;
}

void main() {
  setUp(() {
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1280, 800);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;

    QuizSourceRepository.instance = FakeQuizSourceRepository();
    QuizHistoryRepository.instance = FakeQuizHistoryRepository();
    QuizSessionRepository.instance = FakeQuizSessionRepository();
  });

  tearDown(() {
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('HomePage renders correctly and has PDF Library button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );

    await tester.pump();
    expect(find.text('QuizForge AI'), findsOneWidget);
    expect(find.text('PDF Library'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Choose from PDF Library'), findsOneWidget);

    // Settle all checks and microtasks
    await tester.pumpAndSettle();
  });

  testWidgets('LibraryPage renders with empty state info',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LibraryPage(),
      ),
    );

    expect(find.text('PDF Library'), findsOneWidget);
    await tester.pump();
    expect(find.text('Your PDF library is empty.'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('HistoryPage renders with empty state info',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HistoryPage(),
      ),
    );

    expect(find.text('Quiz History'), findsOneWidget);
    await tester.pump();
    expect(find.text('No quiz history yet.'), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
