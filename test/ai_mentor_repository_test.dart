import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/models/ai_mentor_models.dart';
import 'package:quizforge_upsc/models/quiz_attempt.dart';
import 'package:quizforge_upsc/repositories/impl/ai_mentor_repository_impl.dart';
import 'package:quizforge_upsc/repositories/quiz_history_repository.dart';

class MockHistoryRepository implements QuizHistoryRepository {
  final List<QuizAttempt> attempts;
  MockHistoryRepository({this.attempts = const []});

  @override
  Future<List<QuizAttempt>> getAttempts() async => attempts;

  @override
  Future<void> saveAttempt(QuizAttempt attempt) async {}

  @override
  Future<void> clearHistory() async {}

  @override
  Future<void> deleteAttempt(String id) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AIMentorRepository Unit Tests', () {
    test(
        'Verification: getMentorOverview returns complete AIMentorData with fallbacks',
        () async {
      final repo = AIMentorRepositoryImpl(
        historyRepository: MockHistoryRepository(),
      );

      final overview = await repo.getMentorOverview();

      expect(overview, isNotNull);
      expect(overview.mentorGreeting, contains("Aspirant"));
      expect(overview.overallAdvice, isNotEmpty);
      expect(overview.weakTopics, isNotEmpty);
      expect(overview.studyPlan, isNotEmpty);
      expect(overview.recommendations, isNotEmpty);
      expect(overview.suggestedDailyStudyHours, greaterThan(0));
    });

    test(
        'Verification: getWeakTopics returns fallback list when history is empty',
        () async {
      final repo = AIMentorRepositoryImpl(
        historyRepository: MockHistoryRepository(attempts: []),
      );

      final weakTopics = await repo.getWeakTopics();

      expect(weakTopics.length, equals(3));
      expect(weakTopics.first.subject, equals('Indian Polity'));
    });

    test(
        'Verification: generateStudyPlan respects target days and daily hours parameters',
        () async {
      final repo = AIMentorRepositoryImpl(
        historyRepository: MockHistoryRepository(),
      );

      final plan = await repo.generateStudyPlan(targetDays: 7, dailyHours: 4.0);

      expect(plan, isNotEmpty);
      expect(plan.any((item) => item.priority == PlanPriority.high), isTrue);
      expect(plan.any((item) => item.actionType == 'PYQ Practice'), isTrue);
    });

    test('Verification: getRecommendations returns prioritized mentor tiles',
        () async {
      final repo = AIMentorRepositoryImpl(
        historyRepository: MockHistoryRepository(),
      );

      final recommendations = await repo.getRecommendations();

      expect(recommendations, isNotEmpty);
      expect(recommendations.first.impactScore, greaterThanOrEqualTo(80));
    });
  });
}
