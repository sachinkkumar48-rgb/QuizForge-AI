import 'package:meta/meta.dart';

/// Value object representing Section 1: Welcome Header.
@immutable
class LearnerHeaderData {
  final String userId;
  final String displayName;
  final String greeting;
  final int streakDays;
  final String targetExam;
  final String? profilePictureUrl;

  const LearnerHeaderData({
    required this.userId,
    required this.displayName,
    required this.greeting,
    required this.streakDays,
    required this.targetExam,
    this.profilePictureUrl,
  });

  factory LearnerHeaderData.empty() => const LearnerHeaderData(
        userId: '',
        displayName: 'Learner',
        greeting: 'Welcome back',
        streakDays: 0,
        targetExam: 'UPSC CSE',
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'greeting': greeting,
        'streakDays': streakDays,
        'targetExam': targetExam,
        'profilePictureUrl': profilePictureUrl,
      };

  factory LearnerHeaderData.fromJson(Map<String, dynamic> json) =>
      LearnerHeaderData(
        userId: json['userId'] as String? ?? '',
        displayName: json['displayName'] as String? ?? 'Learner',
        greeting: json['greeting'] as String? ?? 'Welcome back',
        streakDays: json['streakDays'] as int? ?? 0,
        targetExam: json['targetExam'] as String? ?? 'UPSC CSE',
        profilePictureUrl: json['profilePictureUrl'] as String?,
      );
}

/// Value object representing Section 2: Today's Focus.
@immutable
class TodayFocusData {
  final String taskId;
  final String topic;
  final int estimatedStudyMinutes;
  final String priority; // High, Medium, Low
  final bool isCompleted;

  const TodayFocusData({
    required this.taskId,
    required this.topic,
    required this.estimatedStudyMinutes,
    required this.priority,
    this.isCompleted = false,
  });

  factory TodayFocusData.empty() => const TodayFocusData(
        taskId: '',
        topic: 'Indian Polity & Governance',
        estimatedStudyMinutes: 45,
        priority: 'High',
      );

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'topic': topic,
        'estimatedStudyMinutes': estimatedStudyMinutes,
        'priority': priority,
        'isCompleted': isCompleted,
      };

  factory TodayFocusData.fromJson(Map<String, dynamic> json) => TodayFocusData(
        taskId: json['taskId'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
        estimatedStudyMinutes: json['estimatedStudyMinutes'] as int? ?? 0,
        priority: json['priority'] as String? ?? 'Medium',
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

/// Value object representing Section 3: Continue Learning.
@immutable
class ContinueLearningData {
  final String courseId;
  final String courseTitle;
  final String lessonId;
  final String lessonTitle;
  final double progressPercentage; // 0.0 to 1.0
  final String contentType; // video, article, quiz

  const ContinueLearningData({
    required this.courseId,
    required this.courseTitle,
    required this.lessonId,
    required this.lessonTitle,
    required this.progressPercentage,
    required this.contentType,
  });

  factory ContinueLearningData.empty() => const ContinueLearningData(
        courseId: '',
        courseTitle: 'Modern Indian History',
        lessonId: '',
        lessonTitle: 'Freedom Movement 1857-1947',
        progressPercentage: 0.65,
        contentType: 'video',
      );

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        'courseTitle': courseTitle,
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
        'progressPercentage': progressPercentage,
        'contentType': contentType,
      };

  factory ContinueLearningData.fromJson(Map<String, dynamic> json) =>
      ContinueLearningData(
        courseId: json['courseId'] as String? ?? '',
        courseTitle: json['courseTitle'] as String? ?? '',
        lessonId: json['lessonId'] as String? ?? '',
        lessonTitle: json['lessonTitle'] as String? ?? '',
        progressPercentage:
            (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
        contentType: json['contentType'] as String? ?? 'video',
      );
}

/// Value object representing Section 4: Revision Due.
@immutable
class RevisionDueData {
  final int overdueCount;
  final int todayRevisionCount;
  final String nextRevisionTopic;
  final List<String> dueTopics;

  const RevisionDueData({
    required this.overdueCount,
    required this.todayRevisionCount,
    required this.nextRevisionTopic,
    required this.dueTopics,
  });

  factory RevisionDueData.empty() => const RevisionDueData(
        overdueCount: 3,
        todayRevisionCount: 12,
        nextRevisionTopic: 'Preamble & Fundamental Rights',
        dueTopics: ['Preamble', 'Fundamental Rights', 'Directive Principles'],
      );

  Map<String, dynamic> toJson() => {
        'overdueCount': overdueCount,
        'todayRevisionCount': todayRevisionCount,
        'nextRevisionTopic': nextRevisionTopic,
        'dueTopics': dueTopics,
      };

  factory RevisionDueData.fromJson(Map<String, dynamic> json) =>
      RevisionDueData(
        overdueCount: json['overdueCount'] as int? ?? 0,
        todayRevisionCount: json['todayRevisionCount'] as int? ?? 0,
        nextRevisionTopic: json['nextRevisionTopic'] as String? ?? '',
        dueTopics: (json['dueTopics'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );
}

/// Value object representing Section 5: AI Tutor.
@immutable
class AITutorData {
  final String questionOfTheDay;
  final String suggestedConcept;
  final String activeSessionId;

  const AITutorData({
    required this.questionOfTheDay,
    required this.suggestedConcept,
    required this.activeSessionId,
  });

  factory AITutorData.empty() => const AITutorData(
        questionOfTheDay:
            'What is the significance of the Basic Structure Doctrine in Indian Constitutional Law?',
        suggestedConcept: 'Judicial Review & Separation of Powers',
        activeSessionId: 'session_ai_001',
      );

  Map<String, dynamic> toJson() => {
        'questionOfTheDay': questionOfTheDay,
        'suggestedConcept': suggestedConcept,
        'activeSessionId': activeSessionId,
      };

  factory AITutorData.fromJson(Map<String, dynamic> json) => AITutorData(
        questionOfTheDay: json['questionOfTheDay'] as String? ?? '',
        suggestedConcept: json['suggestedConcept'] as String? ?? '',
        activeSessionId: json['activeSessionId'] as String? ?? '',
      );
}

/// Value object representing an individual Recommendation item.
@immutable
class RecommendationItemData {
  final String id;
  final String title;
  final String reason;
  final String priority;
  final String category;
  final String actionUrl;

  const RecommendationItemData({
    required this.id,
    required this.title,
    required this.reason,
    required this.priority,
    required this.category,
    required this.actionUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'reason': reason,
        'priority': priority,
        'category': category,
        'actionUrl': actionUrl,
      };

  factory RecommendationItemData.fromJson(Map<String, dynamic> json) =>
      RecommendationItemData(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        priority: json['priority'] as String? ?? 'Medium',
        category: json['category'] as String? ?? 'General',
        actionUrl: json['actionUrl'] as String? ?? '',
      );
}

/// Value object representing Section 6: Recommendations.
@immutable
class RecommendationsData {
  final List<RecommendationItemData> topRecommendations;

  const RecommendationsData({required this.topRecommendations});

  factory RecommendationsData.empty() => const RecommendationsData(
        topRecommendations: [
          RecommendationItemData(
            id: 'rec_1',
            title: 'Master Constitutional Amendments',
            reason: 'High frequency in Prelims PYQs',
            priority: 'High',
            category: 'Polity',
            actionUrl: '/academy/polity/amendments',
          ),
          RecommendationItemData(
            id: 'rec_2',
            title: 'Revise Inflation & Monetary Policy',
            reason: 'Weak accuracy (45%) in recent quiz',
            priority: 'High',
            category: 'Economy',
            actionUrl: '/revision/economy/inflation',
          ),
          RecommendationItemData(
            id: 'rec_3',
            title: 'Practice Environmental Protocols',
            reason: 'Recommended based on study goal',
            priority: 'Medium',
            category: 'Environment',
            actionUrl: '/smart_assessment/env_protocols',
          ),
          RecommendationItemData(
            id: 'rec_4',
            title: 'Solve Science & Tech Daily Quiz',
            reason: 'Keep streak active',
            priority: 'Medium',
            category: 'S&T',
            actionUrl: '/quiz/daily_st',
          ),
          RecommendationItemData(
            id: 'rec_5',
            title: 'Ask AI Tutor on Basic Structure',
            reason: 'Deepen conceptual clarity',
            priority: 'Medium',
            category: 'Polity',
            actionUrl: '/ai_tutor/basic_structure',
          ),
        ],
      );

  Map<String, dynamic> toJson() => {
        'topRecommendations':
            topRecommendations.map((e) => e.toJson()).toList(),
      };

  factory RecommendationsData.fromJson(Map<String, dynamic> json) =>
      RecommendationsData(
        topRecommendations: (json['topRecommendations'] as List<dynamic>?)
                ?.map((e) =>
                    RecommendationItemData.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

/// Value object representing Section 7: Journey.
@immutable
class JourneyData {
  final String roadmapTitle;
  final String currentMilestone;
  final double completionPercentage;
  final int totalMilestones;
  final int completedMilestones;

  const JourneyData({
    required this.roadmapTitle,
    required this.currentMilestone,
    required this.completionPercentage,
    required this.totalMilestones,
    required this.completedMilestones,
  });

  factory JourneyData.empty() => const JourneyData(
        roadmapTitle: 'UPSC CSE Prelims Roadmap',
        currentMilestone: 'Phase 2: Core Subject Mastery',
        completionPercentage: 0.42,
        totalMilestones: 12,
        completedMilestones: 5,
      );

  Map<String, dynamic> toJson() => {
        'roadmapTitle': roadmapTitle,
        'currentMilestone': currentMilestone,
        'completionPercentage': completionPercentage,
        'totalMilestones': totalMilestones,
        'completedMilestones': completedMilestones,
      };

  factory JourneyData.fromJson(Map<String, dynamic> json) => JourneyData(
        roadmapTitle: json['roadmapTitle'] as String? ?? '',
        currentMilestone: json['currentMilestone'] as String? ?? '',
        completionPercentage:
            (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
        totalMilestones: json['totalMilestones'] as int? ?? 0,
        completedMilestones: json['completedMilestones'] as int? ?? 0,
      );
}

/// Value object representing Section 8: Assessment Readiness.
@immutable
class AssessmentReadinessData {
  final int readinessScore; // 0 to 100
  final String weakestSubject;
  final String strongestSubject;
  final String readinessLevel; // Ready, On Track, Needs Attention

  const AssessmentReadinessData({
    required this.readinessScore,
    required this.weakestSubject,
    required this.strongestSubject,
    required this.readinessLevel,
  });

  factory AssessmentReadinessData.empty() => const AssessmentReadinessData(
        readinessScore: 74,
        weakestSubject: 'Economy & Banking',
        strongestSubject: 'Polity & Governance',
        readinessLevel: 'On Track',
      );

  Map<String, dynamic> toJson() => {
        'readinessScore': readinessScore,
        'weakestSubject': weakestSubject,
        'strongestSubject': strongestSubject,
        'readinessLevel': readinessLevel,
      };

  factory AssessmentReadinessData.fromJson(Map<String, dynamic> json) =>
      AssessmentReadinessData(
        readinessScore: json['readinessScore'] as int? ?? 0,
        weakestSubject: json['weakestSubject'] as String? ?? '',
        strongestSubject: json['strongestSubject'] as String? ?? '',
        readinessLevel: json['readinessLevel'] as String? ?? 'On Track',
      );
}

/// Value object representing Section 9: Weekly Analytics.
@immutable
class WeeklyAnalyticsData {
  final double studyHours;
  final double consistencyPercentage;
  final double accuracyPercentage;
  final double retentionPercentage;

  const WeeklyAnalyticsData({
    required this.studyHours,
    required this.consistencyPercentage,
    required this.accuracyPercentage,
    required this.retentionPercentage,
  });

  factory WeeklyAnalyticsData.empty() => const WeeklyAnalyticsData(
        studyHours: 24.5,
        consistencyPercentage: 0.85,
        accuracyPercentage: 0.78,
        retentionPercentage: 0.82,
      );

  Map<String, dynamic> toJson() => {
        'studyHours': studyHours,
        'consistencyPercentage': consistencyPercentage,
        'accuracyPercentage': accuracyPercentage,
        'retentionPercentage': retentionPercentage,
      };

  factory WeeklyAnalyticsData.fromJson(Map<String, dynamic> json) =>
      WeeklyAnalyticsData(
        studyHours: (json['studyHours'] as num?)?.toDouble() ?? 0.0,
        consistencyPercentage:
            (json['consistencyPercentage'] as num?)?.toDouble() ?? 0.0,
        accuracyPercentage:
            (json['accuracyPercentage'] as num?)?.toDouble() ?? 0.0,
        retentionPercentage:
            (json['retentionPercentage'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Value object representing individual Upcoming Event item.
@immutable
class UpcomingEventItemData {
  final String id;
  final String title;
  final String type; // live_class, mock_exam, deadline
  final DateTime scheduledTime;
  final String instructorOrDetails;

  const UpcomingEventItemData({
    required this.id,
    required this.title,
    required this.type,
    required this.scheduledTime,
    required this.instructorOrDetails,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'scheduledTime': scheduledTime.toIso8601String(),
        'instructorOrDetails': instructorOrDetails,
      };

  factory UpcomingEventItemData.fromJson(Map<String, dynamic> json) =>
      UpcomingEventItemData(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        type: json['type'] as String? ?? 'event',
        scheduledTime:
            DateTime.tryParse(json['scheduledTime'] as String? ?? '') ??
                DateTime.now(),
        instructorOrDetails: json['instructorOrDetails'] as String? ?? '',
      );
}

/// Value object representing Section 10: Upcoming Events.
@immutable
class UpcomingEventsData {
  final List<UpcomingEventItemData> events;

  const UpcomingEventsData({required this.events});

  factory UpcomingEventsData.empty() => UpcomingEventsData(
        events: [
          UpcomingEventItemData(
            id: 'event_1',
            title: 'Live Class: Current Affairs Weekly Round-up',
            type: 'live_class',
            scheduledTime: DateTime.now().add(const Duration(hours: 2)),
            instructorOrDetails: 'Prof. Sharma',
          ),
          UpcomingEventItemData(
            id: 'event_2',
            title: 'All-India Prelims Mock Test #4',
            type: 'mock_exam',
            scheduledTime: DateTime.now().add(const Duration(days: 1)),
            instructorOrDetails: 'Full Syllabus 100 Questions',
          ),
          UpcomingEventItemData(
            id: 'event_3',
            title: 'Mains Answer Writing Submission',
            type: 'deadline',
            scheduledTime: DateTime.now().add(const Duration(days: 2)),
            instructorOrDetails: 'GS Paper 2 Submission',
          ),
        ],
      );

  Map<String, dynamic> toJson() => {
        'events': events.map((e) => e.toJson()).toList(),
      };

  factory UpcomingEventsData.fromJson(Map<String, dynamic> json) =>
      UpcomingEventsData(
        events: (json['events'] as List<dynamic>?)
                ?.map((e) =>
                    UpcomingEventItemData.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

/// Value object representing Section 11: Achievements.
@immutable
class AchievementsData {
  final int totalBadges;
  final List<String> badges;
  final List<String> milestoneTitles;
  final int certificateCount;

  const AchievementsData({
    required this.totalBadges,
    required this.badges,
    required this.milestoneTitles,
    required this.certificateCount,
  });

  factory AchievementsData.empty() => const AchievementsData(
        totalBadges: 8,
        badges: ['🔥 7-Day Streak', '🎯 90%+ Accuracy', '📚 Polity Master'],
        milestoneTitles: [
          '50 Study Hours Completed',
          'First Full Mock Exam Cleared'
        ],
        certificateCount: 2,
      );

  Map<String, dynamic> toJson() => {
        'totalBadges': totalBadges,
        'badges': badges,
        'milestoneTitles': milestoneTitles,
        'certificateCount': certificateCount,
      };

  factory AchievementsData.fromJson(Map<String, dynamic> json) =>
      AchievementsData(
        totalBadges: json['totalBadges'] as int? ?? 0,
        badges: (json['badges'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        milestoneTitles: (json['milestoneTitles'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        certificateCount: json['certificateCount'] as int? ?? 0,
      );
}

/// Aggregate immutable root state for the Unified Dashboard.
@immutable
class UnifiedDashboardState {
  final bool isLoading;
  final bool isRefreshing;
  final bool isOffline;
  final String? errorMessage;
  final DateTime lastUpdated;
  final LearnerHeaderData header;
  final TodayFocusData todayFocus;
  final ContinueLearningData continueLearning;
  final RevisionDueData revisionDue;
  final AITutorData aiTutor;
  final RecommendationsData recommendations;
  final JourneyData journey;
  final AssessmentReadinessData assessmentReadiness;
  final WeeklyAnalyticsData weeklyAnalytics;
  final UpcomingEventsData upcomingEvents;
  final AchievementsData achievements;

  const UnifiedDashboardState({
    required this.isLoading,
    required this.isRefreshing,
    required this.isOffline,
    this.errorMessage,
    required this.lastUpdated,
    required this.header,
    required this.todayFocus,
    required this.continueLearning,
    required this.revisionDue,
    required this.aiTutor,
    required this.recommendations,
    required this.journey,
    required this.assessmentReadiness,
    required this.weeklyAnalytics,
    required this.upcomingEvents,
    required this.achievements,
  });

  factory UnifiedDashboardState.initial() => UnifiedDashboardState(
        isLoading: true,
        isRefreshing: false,
        isOffline: false,
        errorMessage: null,
        lastUpdated: DateTime.now(),
        header: LearnerHeaderData.empty(),
        todayFocus: TodayFocusData.empty(),
        continueLearning: ContinueLearningData.empty(),
        revisionDue: RevisionDueData.empty(),
        aiTutor: AITutorData.empty(),
        recommendations: RecommendationsData.empty(),
        journey: JourneyData.empty(),
        assessmentReadiness: AssessmentReadinessData.empty(),
        weeklyAnalytics: WeeklyAnalyticsData.empty(),
        upcomingEvents: UpcomingEventsData.empty(),
        achievements: AchievementsData.empty(),
      );

  UnifiedDashboardState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? isOffline,
    String? errorMessage,
    DateTime? lastUpdated,
    LearnerHeaderData? header,
    TodayFocusData? todayFocus,
    ContinueLearningData? continueLearning,
    RevisionDueData? revisionDue,
    AITutorData? aiTutor,
    RecommendationsData? recommendations,
    JourneyData? journey,
    AssessmentReadinessData? assessmentReadiness,
    WeeklyAnalyticsData? weeklyAnalytics,
    UpcomingEventsData? upcomingEvents,
    AchievementsData? achievements,
  }) {
    return UnifiedDashboardState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      header: header ?? this.header,
      todayFocus: todayFocus ?? this.todayFocus,
      continueLearning: continueLearning ?? this.continueLearning,
      revisionDue: revisionDue ?? this.revisionDue,
      aiTutor: aiTutor ?? this.aiTutor,
      recommendations: recommendations ?? this.recommendations,
      journey: journey ?? this.journey,
      assessmentReadiness: assessmentReadiness ?? this.assessmentReadiness,
      weeklyAnalytics: weeklyAnalytics ?? this.weeklyAnalytics,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      achievements: achievements ?? this.achievements,
    );
  }

  Map<String, dynamic> toJson() => {
        'isLoading': isLoading,
        'isRefreshing': isRefreshing,
        'isOffline': isOffline,
        'errorMessage': errorMessage,
        'lastUpdated': lastUpdated.toIso8601String(),
        'header': header.toJson(),
        'todayFocus': todayFocus.toJson(),
        'continueLearning': continueLearning.toJson(),
        'revisionDue': revisionDue.toJson(),
        'aiTutor': aiTutor.toJson(),
        'recommendations': recommendations.toJson(),
        'journey': journey.toJson(),
        'assessmentReadiness': assessmentReadiness.toJson(),
        'weeklyAnalytics': weeklyAnalytics.toJson(),
        'upcomingEvents': upcomingEvents.toJson(),
        'achievements': achievements.toJson(),
      };

  factory UnifiedDashboardState.fromJson(Map<String, dynamic> json) =>
      UnifiedDashboardState(
        isLoading: json['isLoading'] as bool? ?? false,
        isRefreshing: json['isRefreshing'] as bool? ?? false,
        isOffline: json['isOffline'] as bool? ?? false,
        errorMessage: json['errorMessage'] as String?,
        lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? '') ??
            DateTime.now(),
        header: json['header'] != null
            ? LearnerHeaderData.fromJson(json['header'] as Map<String, dynamic>)
            : LearnerHeaderData.empty(),
        todayFocus: json['todayFocus'] != null
            ? TodayFocusData.fromJson(
                json['todayFocus'] as Map<String, dynamic>)
            : TodayFocusData.empty(),
        continueLearning: json['continueLearning'] != null
            ? ContinueLearningData.fromJson(
                json['continueLearning'] as Map<String, dynamic>)
            : ContinueLearningData.empty(),
        revisionDue: json['revisionDue'] != null
            ? RevisionDueData.fromJson(
                json['revisionDue'] as Map<String, dynamic>)
            : RevisionDueData.empty(),
        aiTutor: json['aiTutor'] != null
            ? AITutorData.fromJson(json['aiTutor'] as Map<String, dynamic>)
            : AITutorData.empty(),
        recommendations: json['recommendations'] != null
            ? RecommendationsData.fromJson(
                json['recommendations'] as Map<String, dynamic>)
            : RecommendationsData.empty(),
        journey: json['journey'] != null
            ? JourneyData.fromJson(json['journey'] as Map<String, dynamic>)
            : JourneyData.empty(),
        assessmentReadiness: json['assessmentReadiness'] != null
            ? AssessmentReadinessData.fromJson(
                json['assessmentReadiness'] as Map<String, dynamic>)
            : AssessmentReadinessData.empty(),
        weeklyAnalytics: json['weeklyAnalytics'] != null
            ? WeeklyAnalyticsData.fromJson(
                json['weeklyAnalytics'] as Map<String, dynamic>)
            : WeeklyAnalyticsData.empty(),
        upcomingEvents: json['upcomingEvents'] != null
            ? UpcomingEventsData.fromJson(
                json['upcomingEvents'] as Map<String, dynamic>)
            : UpcomingEventsData.empty(),
        achievements: json['achievements'] != null
            ? AchievementsData.fromJson(
                json['achievements'] as Map<String, dynamic>)
            : AchievementsData.empty(),
      );
}
