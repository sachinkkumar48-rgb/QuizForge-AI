import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/controllers/ai_mentor_controller.dart';
import 'package:quizforge_upsc/domain/usecases/generate_study_plan_usecase.dart';
import 'package:quizforge_upsc/models/ai_mentor_models.dart';
import 'package:quizforge_upsc/pages/ai_mentor_panel_page.dart';
import 'package:quizforge_upsc/repositories/ai_mentor_repository.dart';
import 'package:quizforge_upsc/widgets/dashboard/mentor/ai_mentor_card.dart';
import 'package:quizforge_upsc/widgets/dashboard/mentor/recommendation_card.dart';
import 'package:quizforge_upsc/widgets/dashboard/mentor/study_plan_card.dart';
import 'package:quizforge_upsc/widgets/dashboard/mentor/weak_topics_card.dart';
import 'package:titan_core/titan_core.dart';

class WidgetTestMentorRepo implements AIMentorRepository {
  @override
  Future<AIMentorData> getMentorOverview() async {
    final now = DateTime.now();
    return AIMentorData(
      mentorGreeting: "Welcome to AI Mentor!",
      overallAdvice: "Focus on Emergency Provisions and Monetary Policy.",
      weakTopics: const [
        WeakTopicInfo(
          id: 'wt_w1',
          subject: 'Indian Polity',
          topic: 'Emergency Provisions',
          accuracyPercentage: 54.0,
          questionsAttempted: 25,
          recommendedAction: 'Solve 20 PYQs',
        ),
      ],
      studyPlan: [
        StudyPlanItem(
          id: 'sp_w1',
          subject: 'Polity & Governance',
          topic: 'Fundamental Rights Articles 14-19',
          estimatedMinutes: 45,
          isCompleted: false,
          recommendedDate: now,
          priority: PlanPriority.high,
          actionType: 'PYQ Practice',
        ),
      ],
      recommendations: const [
        MentorRecommendation(
          id: 'mr_w1',
          title: 'Elimination Techniques',
          description: 'Notice pattern-based phrasing',
          category: 'Strategy Insight',
          iconName: 'lightbulb',
          impactScore: 92,
        ),
      ],
      suggestedDailyStudyHours: 3.5,
    );
  }

  @override
  Future<List<WeakTopicInfo>> getWeakTopics() async => [];

  @override
  Future<List<StudyPlanItem>> generateStudyPlan({
    int targetDays = 7,
    double dailyHours = 3.0,
  }) async =>
      [];

  @override
  Future<List<MentorRecommendation>> getRecommendations() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Mentor Widgets & Page Tests', () {
    tearDown(() {
      TitanServiceLocator.instance.reset();
    });

    testWidgets(
        'Verification: AIMentorCard renders greeting and study hours badge',
        (WidgetTester tester) async {
      final data = await WidgetTestMentorRepo().getMentorOverview();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: AIMentorCard(data: data),
          ),
        ),
      );

      expect(find.text("Welcome to AI Mentor!"), findsOneWidget);
      expect(find.text("3.5h Daily Target"), findsOneWidget);
      expect(find.text("Focus on Emergency Provisions and Monetary Policy."),
          findsOneWidget);
    });

    testWidgets(
        'Verification: WeakTopicsCard renders weak topic information and accuracy percentage',
        (WidgetTester tester) async {
      final data = await WidgetTestMentorRepo().getMentorOverview();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeakTopicsCard(weakTopics: data.weakTopics),
            ),
          ),
        ),
      );

      expect(find.text("Weak Topics Diagnostic"), findsOneWidget);
      expect(find.text("Emergency Provisions"), findsOneWidget);
      expect(find.text("54%"), findsOneWidget);
    });

    testWidgets(
        'Verification: StudyPlanCard renders study tasks and priority chips',
        (WidgetTester tester) async {
      final data = await WidgetTestMentorRepo().getMentorOverview();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudyPlanCard(studyPlan: data.studyPlan),
            ),
          ),
        ),
      );

      expect(find.text("AI Generated Study Plan"), findsOneWidget);
      expect(find.text("Fundamental Rights Articles 14-19"), findsOneWidget);
      expect(find.text("High"), findsOneWidget);
    });

    testWidgets(
        'Verification: RecommendationCard renders recommendation title and impact score',
        (WidgetTester tester) async {
      final data = await WidgetTestMentorRepo().getMentorOverview();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: SingleChildScrollView(
              child: RecommendationCard(recommendations: data.recommendations),
            ),
          ),
        ),
      );

      expect(find.text("Smart Recommendations"), findsOneWidget);
      expect(find.text("Elimination Techniques"), findsOneWidget);
      expect(find.text("+92 Impact"), findsOneWidget);
    });

    testWidgets(
        'Verification: AIMentorPanelPage renders full dashboard page reactively',
        (WidgetTester tester) async {
      final mockRepo = WidgetTestMentorRepo();
      final controller = AIMentorController(
        repository: mockRepo,
        generateStudyPlanUseCase: GenerateStudyPlanUseCaseImpl(
          repository: mockRepo,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: AIMentorPanelPage(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("AI Mentor Panel"), findsOneWidget);
      expect(find.text("Welcome to AI Mentor!"), findsOneWidget);
      expect(find.text("Weak Topics Diagnostic"), findsOneWidget);
      expect(find.text("AI Generated Study Plan"), findsOneWidget);
      expect(find.text("Smart Recommendations"), findsOneWidget);
    });
  });
}
