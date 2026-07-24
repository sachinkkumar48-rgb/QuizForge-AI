import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/controllers/learning_coach_controller.dart';
import 'package:quizforge_upsc/models/analytics_engine_models.dart';
import 'package:quizforge_upsc/models/learning_coach_models.dart';
import 'package:quizforge_upsc/models/pyq_question_model.dart';
import 'package:quizforge_upsc/pages/ai_learning_coach_page.dart';
import 'package:quizforge_upsc/services/ai/coach/claude_learning_coach.dart';
import 'package:quizforge_upsc/services/ai/coach/gemini_learning_coach.dart';
import 'package:quizforge_upsc/services/ai/coach/learning_coach.dart';
import 'package:quizforge_upsc/services/ai/coach/learning_coach_factory.dart';
import 'package:quizforge_upsc/services/ai/coach/local_llm_learning_coach.dart';
import 'package:quizforge_upsc/services/ai/coach/openai_learning_coach.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LearningInsightsModel sampleInsights;
  late List<PyqQuestionModel> sampleQuestions;

  setUp(() {
    sampleInsights = LearningInsightsModel(
      overallAccuracy: 65.0,
      subjectAccuracy: {},
      topicAccuracy: {},
      yearAccuracy: {},
      difficultyAccuracy: {},
      averageTimePerQuestionSeconds: 45.0,
      averageQuizScore: 65.0,
      dailyQuestionsSolved: 10,
      weeklyQuestionsSolved: 50,
      monthlyQuestionsSolved: 180,
      currentStreak: 5,
      longestStreak: 12,
      revisionCompletionPercent: 40.0,
      bookmarkCount: 4,
      incorrectQuestionCount: 8,
      questionAttemptFrequency: {},
      weakAreaInsights: [],
      strongSubjects: ['Polity'],
      weakSubjects: ['History', 'Economy'],
    );

    sampleQuestions = [
      PyqQuestionModel(
        id: 'Q_COACH_01',
        year: 2024,
        exam: 'UPSC CSE',
        paper: 'GS Paper 1',
        subject: 'History',
        topic: 'Ancient History',
        difficulty: 'Medium',
        question: 'Harappan trade contacts',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'A',
        officialAnswer: 'A',
        userSelectedAnswer: 'B',
        explanation: PyqExplanation(official: 'Exp'),
        reference: 'RS Sharma',
      ),
    ];

    LearningCoachFactory.reset();
  });

  group('AI Learning Coach Provider Tests (Decoupled LLM Architecture)', () {
    test('GeminiLearningCoach conforms to LearningCoach interface', () async {
      final LearningCoach coach = GeminiLearningCoach();
      expect(coach.providerId, equals('gemini'));
      expect(coach.providerName, contains('Gemini'));

      final PerformanceAnalysis analysis =
          await coach.analyzePerformance(insights: sampleInsights);
      expect(analysis.weeklyReport.isNotEmpty, isTrue);
      expect(analysis.weakTopics.isNotEmpty, isTrue);
      expect(analysis.recommendedPyqs.isNotEmpty, isTrue);
      expect(analysis.recommendedAiQuizzes.isNotEmpty, isTrue);
      expect(analysis.studyHoursSuggestion.isNotEmpty, isTrue);
      expect(analysis.motivationalInsights.isNotEmpty, isTrue);
    });

    test('OpenAiLearningCoach conforms to LearningCoach interface', () async {
      final LearningCoach coach = OpenAiLearningCoach();
      expect(coach.providerId, equals('openai'));
      expect(coach.providerName, contains('OpenAI'));

      final analysis = await coach.analyzePerformance(insights: sampleInsights);
      expect(analysis.weeklyReport.contains('OpenAI'), isTrue);

      final recs = await coach.recommendRevision(
        weakTopics: ['History'],
        questions: sampleQuestions,
      );
      expect(recs.recommendedPyqs.isNotEmpty, isTrue);
    });

    test('ClaudeLearningCoach conforms to LearningCoach interface', () async {
      final LearningCoach coach = ClaudeLearningCoach();
      expect(coach.providerId, equals('claude'));
      expect(coach.providerName, contains('Claude'));

      final exp = await coach.explainWeakness(
        weaknessTopic: 'Economy',
        accuracyPercent: 35.0,
      );
      expect(exp.topic, equals('Economy'));
      expect(exp.rootCauses.isNotEmpty, isTrue);
    });

    test('LocalLlmLearningCoach conforms to LearningCoach interface', () async {
      final LearningCoach coach = LocalLlmLearningCoach();
      expect(coach.providerId, equals('local_llm'));
      expect(coach.providerName, contains('Local LLM'));

      final plan = await coach.generateStudyPlan(
        weakTopics: ['Geography'],
        totalDays: 5,
        dailyHoursAvailable: 3.0,
      );
      expect(plan.totalDays, equals(5));
      expect(plan.dailyFocusAreas.length, equals(5));
    });
  });

  group('LearningCoachFactory Dynamic Switching Tests', () {
    test('Switches active coach dynamically', () {
      expect(LearningCoachFactory.activeCoachType,
          equals(CoachProviderType.gemini));
      expect(
          LearningCoachFactory.getActiveCoach().providerId, equals('gemini'));

      LearningCoachFactory.setActiveCoachType(CoachProviderType.openAi);
      expect(LearningCoachFactory.activeCoachType,
          equals(CoachProviderType.openAi));
      expect(
          LearningCoachFactory.getActiveCoach().providerId, equals('openai'));

      LearningCoachFactory.setActiveCoachType(CoachProviderType.claude);
      expect(LearningCoachFactory.activeCoachType,
          equals(CoachProviderType.claude));
      expect(
          LearningCoachFactory.getActiveCoach().providerId, equals('claude'));
    });
  });

  group('LearningCoachController Integration & UI Widget Test', () {
    test('LearningCoachController manages state across API operations',
        () async {
      final controller = LearningCoachController(
        coach: OpenAiLearningCoach(),
      );

      await controller.analyzePerformance(sampleInsights);
      expect(controller.analysis, isNotNull);
      expect(controller.isLoading, isFalse);

      await controller.explainWeakness('Polity', 40.0);
      expect(controller.explanation, isNotNull);

      await controller.generateStudyPlan(
        weakTopics: ['Polity'],
        totalDays: 7,
        dailyHoursAvailable: 4.0,
      );
      expect(controller.studyPlan, isNotNull);
    });

    testWidgets('AiLearningCoachPage renders coach dashboard cleanly',
        (tester) async {
      final testController = LearningCoachController(
        coach: OpenAiLearningCoach(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AiLearningCoachPage(
            questions: sampleQuestions,
            controller: testController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI Learning Coach'), findsOneWidget);
      expect(find.text('Weekly Performance Report'), findsOneWidget);
      expect(find.text('Identified Weak Topics'), findsOneWidget);
      expect(find.text('Suggested Daily Study Hours'), findsOneWidget);
      expect(find.text('Recommended PYQs'), findsOneWidget);
      expect(find.text('Recommended AI Quizzes'), findsOneWidget);
    });
  });
}
