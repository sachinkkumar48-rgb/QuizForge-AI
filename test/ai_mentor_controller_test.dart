import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/controllers/ai_mentor_controller.dart';
import 'package:quizforge_upsc/core/di/service_locator_init.dart';
import 'package:quizforge_upsc/domain/usecases/generate_study_plan_usecase.dart';
import 'package:quizforge_upsc/models/ai_mentor_models.dart';
import 'package:quizforge_upsc/repositories/ai_mentor_repository.dart';
import 'package:titan_core/titan_core.dart';

class MockAIMentorRepo implements AIMentorRepository {
  @override
  Future<AIMentorData> getMentorOverview() async {
    final now = DateTime.now();
    return AIMentorData(
      mentorGreeting: "Good Morning, Test Aspirant!",
      overallAdvice: "Maintain daily mock consistency.",
      weakTopics: const [
        WeakTopicInfo(
          id: 'wt_test_1',
          subject: 'Polity',
          topic: 'Preamble',
          accuracyPercentage: 50.0,
          questionsAttempted: 10,
          recommendedAction: 'Solve 10 PYQs',
        ),
      ],
      studyPlan: [
        StudyPlanItem(
          id: 'sp_test_1',
          subject: 'Polity',
          topic: 'Fundamental Rights',
          estimatedMinutes: 30,
          isCompleted: false,
          recommendedDate: now,
          priority: PlanPriority.high,
          actionType: 'PYQ Practice',
        ),
      ],
      recommendations: const [
        MentorRecommendation(
          id: 'mr_test_1',
          title: 'Speed Sprint',
          description: 'Practice under timed conditions',
          category: 'Strategy',
          iconName: 'timer',
          impactScore: 90,
        ),
      ],
      suggestedDailyStudyHours: 3.0,
    );
  }

  @override
  Future<List<WeakTopicInfo>> getWeakTopics() async => [];

  @override
  Future<List<StudyPlanItem>> generateStudyPlan({
    int targetDays = 7,
    double dailyHours = 3.0,
  }) async {
    return [
      StudyPlanItem(
        id: 'sp_custom_1',
        subject: 'Economy',
        topic: 'Fiscal Policy',
        estimatedMinutes: 45,
        isCompleted: false,
        recommendedDate: DateTime.now(),
        priority: PlanPriority.high,
        actionType: 'AI Quiz',
      ),
    ];
  }

  @override
  Future<List<MentorRecommendation>> getRecommendations() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AIMentorController Unit Tests', () {
    setUp(() {
      AIMentorRepository.instance = MockAIMentorRepo();
    });

    tearDown(() {
      TitanServiceLocator.instance.reset();
    });

    test('Verification: AIMentorController loads ready state with mentor data',
        () async {
      final mockRepo = MockAIMentorRepo();
      final controller = AIMentorController(
        repository: mockRepo,
        generateStudyPlanUseCase: GenerateStudyPlanUseCaseImpl(
          repository: mockRepo,
        ),
      );

      await Future.delayed(Duration.zero);

      expect(controller.state.isReady, isTrue);
      expect(controller.state.data?.mentorGreeting, contains("Test Aspirant"));
      expect(controller.state.data?.weakTopics, isNotEmpty);
    });

    test(
        'Verification: generateCustomStudyPlan executes via GenerateStudyPlanUseCase',
        () async {
      final mockRepo = MockAIMentorRepo();
      final controller = AIMentorController(
        repository: mockRepo,
        generateStudyPlanUseCase: GenerateStudyPlanUseCaseImpl(
          repository: mockRepo,
        ),
      );

      await Future.delayed(Duration.zero);
      await controller.generateCustomStudyPlan(targetDays: 5, dailyHours: 4.0);

      expect(controller.state.data?.studyPlan.first.id, equals('sp_custom_1'));
      expect(controller.state.data?.suggestedDailyStudyHours, equals(4.0));
    });

    test('Verification: toggleTaskCompletion toggles completion state of item',
        () async {
      final mockRepo = MockAIMentorRepo();
      final controller = AIMentorController(
        repository: mockRepo,
        generateStudyPlanUseCase: GenerateStudyPlanUseCaseImpl(
          repository: mockRepo,
        ),
      );

      await Future.delayed(Duration.zero);
      expect(controller.state.data?.studyPlan.first.isCompleted, isFalse);

      controller.toggleTaskCompletion('sp_test_1');

      expect(controller.state.data?.studyPlan.first.isCompleted, isTrue);
    });

    test('Verification: AIMentorController resolves via DI service locator',
        () {
      setupServiceLocator();
      final controller = locate<AIMentorController>();

      expect(controller, isNotNull);
    });
  });
}
