import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:quizforge_upsc/models/quiz_analytics.dart';
import 'package:quizforge_upsc/models/quiz_attempt.dart';
import 'package:quizforge_upsc/models/quiz_model.dart';
import 'package:quizforge_upsc/repositories/quiz_history_repository.dart';

void main() {
  late Directory tempDir;
  late QuizHistoryRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('quiz_history_test_');
    Hive.init(tempDir.path);
    repository = QuizHistoryRepository();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  QuizAttempt createMockAttempt({
    required String id,
    required String sourceName,
    required DateTime completedAt,
    required double accuracy,
  }) {
    return QuizAttempt(
      id: id,
      completedAt: completedAt,
      sourceName: sourceName,
      analytics: QuizAnalytics(
        score: (accuracy / 10).round(),
        totalQuestions: 10,
        attempted: 10,
        skipped: 0,
        incorrect: 10 - (accuracy / 10).round(),
        accuracy: accuracy,
        performanceLevel: accuracy >= 80
            ? PerformanceLevel.excellent
            : accuracy >= 60
                ? PerformanceLevel.good
                : accuracy >= 40
                    ? PerformanceLevel.average
                    : PerformanceLevel.needsImprovement,
        timeSpent: const Duration(minutes: 5),
        remainingTime: const Duration(minutes: 5),
        totalDuration: const Duration(minutes: 10),
        statusCounts: const {
          QuestionStatus.answered: 10,
        },
      ),
    );
  }

  test('Save and Load attempts', () async {
    final attempt1 = createMockAttempt(
      id: '1',
      sourceName: 'Test 1',
      completedAt: DateTime(2026, 1, 1),
      accuracy: 80.0,
    );
    final attempt2 = createMockAttempt(
      id: '2',
      sourceName: 'Test 2',
      completedAt: DateTime(2026, 1, 2),
      accuracy: 60.0,
    );

    await repository.saveAttempt(attempt1);
    await repository.saveAttempt(attempt2);

    final attempts = await repository.getAttempts();
    expect(attempts.length, 2);

    expect(attempts[0].id, '2');
    expect(attempts[1].id, '1');
  });

  test('Delete attempt', () async {
    final attempt1 = createMockAttempt(
      id: '1',
      sourceName: 'Test 1',
      completedAt: DateTime(2026, 1, 1),
      accuracy: 80.0,
    );
    final attempt2 = createMockAttempt(
      id: '2',
      sourceName: 'Test 2',
      completedAt: DateTime(2026, 1, 2),
      accuracy: 60.0,
    );

    await repository.saveAttempt(attempt1);
    await repository.saveAttempt(attempt2);

    await repository.deleteAttempt('1');

    final attempts = await repository.getAttempts();
    expect(attempts.length, 1);
    expect(attempts[0].id, '2');
  });

  test('Clear history', () async {
    final attempt1 = createMockAttempt(
      id: '1',
      sourceName: 'Test 1',
      completedAt: DateTime(2026, 1, 1),
      accuracy: 80.0,
    );

    await repository.saveAttempt(attempt1);
    await repository.clearHistory();

    final attempts = await repository.getAttempts();
    expect(attempts.isEmpty, true);
  });

  group('Sorting & Searching Logic', () {
    late List<QuizAttempt> testList;

    setUp(() {
      testList = [
        createMockAttempt(
            id: '1',
            sourceName: 'History PDF',
            completedAt: DateTime(2026, 1, 1),
            accuracy: 50.0),
        createMockAttempt(
            id: '2',
            sourceName: 'Geography PDF',
            completedAt: DateTime(2026, 1, 5),
            accuracy: 90.0),
        createMockAttempt(
            id: '3',
            sourceName: 'Polity Test',
            completedAt: DateTime(2026, 1, 3),
            accuracy: 70.0),
      ];
    });

    test('Search filtering by name', () {
      final searchPolity = testList
          .where(
              (attempt) => attempt.sourceName.toLowerCase().contains('polity'))
          .toList();
      expect(searchPolity.length, 1);
      expect(searchPolity[0].id, '3');

      final searchPdf = testList
          .where((attempt) => attempt.sourceName.toLowerCase().contains('pdf'))
          .toList();
      expect(searchPdf.length, 2);
      expect(searchPdf.any((e) => e.id == '1'), true);
      expect(searchPdf.any((e) => e.id == '2'), true);
    });

    test('Sorting by newest first', () {
      final list = List<QuizAttempt>.from(testList);
      list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      expect(list[0].id, '2');
      expect(list[1].id, '3');
      expect(list[2].id, '1');
    });

    test('Sorting by oldest first', () {
      final list = List<QuizAttempt>.from(testList);
      list.sort((a, b) => a.completedAt.compareTo(b.completedAt));
      expect(list[0].id, '1');
      expect(list[1].id, '3');
      expect(list[2].id, '2');
    });

    test('Sorting by highest accuracy first', () {
      final list = List<QuizAttempt>.from(testList);
      list.sort((a, b) => b.analytics.accuracy.compareTo(a.analytics.accuracy));
      expect(list[0].id, '2');
      expect(list[1].id, '3');
      expect(list[2].id, '1');
    });

    test('Sorting by lowest accuracy first', () {
      final list = List<QuizAttempt>.from(testList);
      list.sort((a, b) => a.analytics.accuracy.compareTo(b.analytics.accuracy));
      expect(list[0].id, '1');
      expect(list[1].id, '3');
      expect(list[2].id, '2');
    });
  });
}
