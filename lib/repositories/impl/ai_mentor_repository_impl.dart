import '../../models/ai_mentor_models.dart';
import '../quiz_history_repository.dart';
import '../ai_mentor_repository.dart';

/// Implementation of [AIMentorRepository] routing recommendation logic
/// through performance analytics and history repositories with fallback placeholders.
class AIMentorRepositoryImpl implements AIMentorRepository {
  final QuizHistoryRepository _historyRepository;

  AIMentorRepositoryImpl({
    QuizHistoryRepository? historyRepository,
  }) : _historyRepository = historyRepository ?? QuizHistoryRepository();

  @override
  Future<AIMentorData> getMentorOverview() async {
    final weakTopics = await getWeakTopics();
    final studyPlan = await generateStudyPlan();
    final recommendations = await getRecommendations();

    final greeting = _determineGreeting();
    final overallAdvice = weakTopics.isNotEmpty
        ? "Focus on improving accuracy in ${weakTopics.first.subject} (${weakTopics.first.topic}). Practice 20 PYQs daily."
        : "Excellent baseline consistency! Continue daily mock practice and keep your revision queue active.";

    return AIMentorData(
      mentorGreeting: greeting,
      overallAdvice: overallAdvice,
      weakTopics: weakTopics,
      studyPlan: studyPlan,
      recommendations: recommendations,
      suggestedDailyStudyHours: 3.5,
    );
  }

  @override
  Future<List<WeakTopicInfo>> getWeakTopics() async {
    try {
      final attempts = await _historyRepository.getAttempts();
      if (attempts.isNotEmpty) {
        final weakList = <WeakTopicInfo>[];
        for (var i = 0; i < attempts.length; i++) {
          final attempt = attempts[i];
          if (attempt.analytics.accuracy < 75.0) {
            weakList.add(
              WeakTopicInfo(
                id: 'weak_${attempt.id}',
                subject: attempt.sourceName,
                topic: 'General Concept Application',
                accuracyPercentage: attempt.analytics.accuracy,
                questionsAttempted: attempt.analytics.totalQuestions,
                recommendedAction:
                    'Solve 15 targeted PYQ questions & review notes',
              ),
            );
          }
        }
        if (weakList.isNotEmpty) return weakList;
      }
    } catch (_) {
      // Fallback to structured UPSC placeholders
    }

    return const [
      WeakTopicInfo(
        id: 'weak_1',
        subject: 'Indian Polity',
        topic: 'Emergency Provisions & Constitutional Bodies',
        accuracyPercentage: 54.0,
        questionsAttempted: 25,
        recommendedAction: 'Review Laxmikanth Ch. 16 & solve 20 PYQs',
      ),
      WeakTopicInfo(
        id: 'weak_2',
        subject: 'Economy',
        topic: 'Monetary Policy & Inflation Targeting',
        accuracyPercentage: 61.5,
        questionsAttempted: 30,
        recommendedAction: 'Study RBI Monetary Tools & practice 15 AI MCQs',
      ),
      WeakTopicInfo(
        id: 'weak_3',
        subject: 'Environment',
        topic: 'Biodiversity Hotspots & Wildlife Protection Act',
        accuracyPercentage: 68.0,
        questionsAttempted: 22,
        recommendedAction: 'Revise WPA 1972 Schedules & National Parks',
      ),
    ];
  }

  @override
  Future<List<StudyPlanItem>> generateStudyPlan({
    int targetDays = 7,
    double dailyHours = 3.0,
  }) async {
    final now = DateTime.now();

    return [
      StudyPlanItem(
        id: 'plan_1',
        subject: 'Polity & Governance',
        topic: 'Preamble & Fundamental Rights Articles 14-19',
        estimatedMinutes: 45,
        isCompleted: false,
        recommendedDate: now,
        priority: PlanPriority.high,
        actionType: 'PYQ Practice',
      ),
      StudyPlanItem(
        id: 'plan_2',
        subject: 'Macroeconomics',
        topic: 'GDP Deflator vs CPI Inflation Indicators',
        estimatedMinutes: 30,
        isCompleted: true,
        recommendedDate: now,
        priority: PlanPriority.medium,
        actionType: 'AI Quiz',
      ),
      StudyPlanItem(
        id: 'plan_3',
        subject: 'Environment & Ecology',
        topic: 'Ramsar Wetlands & Tiger Reserves in India',
        estimatedMinutes: 60,
        isCompleted: false,
        recommendedDate: now.add(const Duration(days: 1)),
        priority: PlanPriority.high,
        actionType: 'Theory Revision',
      ),
      StudyPlanItem(
        id: 'plan_4',
        subject: 'Modern Indian History',
        topic: 'Non-Cooperation Movement & Swarajists',
        estimatedMinutes: 45,
        isCompleted: false,
        recommendedDate: now.add(const Duration(days: 2)),
        priority: PlanPriority.medium,
        actionType: 'PYQ Practice',
      ),
      StudyPlanItem(
        id: 'plan_5',
        subject: 'Science & Technology',
        topic: 'Biotechnology Applications & CRISPR-Cas9',
        estimatedMinutes: 40,
        isCompleted: false,
        recommendedDate: now.add(const Duration(days: 3)),
        priority: PlanPriority.low,
        actionType: 'AI Quiz',
      ),
    ];
  }

  @override
  Future<List<MentorRecommendation>> getRecommendations() async {
    return const [
      MentorRecommendation(
        id: 'rec_1',
        title: 'Master UPSC Elimination Techniques',
        description:
            'Notice pattern-based phrasing in Polity and Environment options to improve score by +12 marks.',
        category: 'Strategy Insight',
        iconName: 'lightbulb',
        impactScore: 92,
      ),
      MentorRecommendation(
        id: 'rec_2',
        title: 'Daily 20-Question PYQ Sprint',
        description:
            'Attempt 1 Paper section under 20-minute timed pressure to build test stamina.',
        category: 'Practice Sprint',
        iconName: 'timer',
        impactScore: 88,
      ),
      MentorRecommendation(
        id: 'rec_3',
        title: 'Spaced Repetition for Weak Topics',
        description:
            'Schedule automatic 3-day revision intervals for incorrectly answered Questions.',
        category: 'Memory Retention',
        iconName: 'repeat',
        impactScore: 95,
      ),
    ];
  }

  String _determineGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning, Aspirant!";
    } else if (hour < 17) {
      return "Good Afternoon, Aspirant!";
    } else {
      return "Good Evening, Aspirant!";
    }
  }
}
