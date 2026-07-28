import 'package:meta/meta.dart';

/// Enumeration of all discrete steps in the end-to-end TITAN learning flow.
enum LearningFlowStep {
  dashboard,
  academy,
  courseDetails,
  module,
  chapter,
  learningContent,
  mediaPlayback, // Video / PDF / Article
  smartNotes,
  aiTutor,
  quickQuiz,
  adaptiveAssessment,
  instantFeedback,
  revisionPlan,
  journeyUpdate,
  completed,
}

/// Status of a LearningSession.
enum LearningSessionStatus {
  active,
  paused,
  completed,
  abandoned,
  recovered,
}

/// Immutable value object representing a study session checkpoint.
@immutable
class StudyCheckpoint {
  final String checkpointId;
  final LearningFlowStep step;
  final double progressPercentage;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const StudyCheckpoint({
    required this.checkpointId,
    required this.step,
    required this.progressPercentage,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'checkpointId': checkpointId,
        'step': step.name,
        'progressPercentage': progressPercentage,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory StudyCheckpoint.fromJson(Map<String, dynamic> json) =>
      StudyCheckpoint(
        checkpointId: json['checkpointId'] as String? ?? '',
        step: LearningFlowStep.values.firstWhere(
          (e) => e.name == json['step'],
          orElse: () => LearningFlowStep.learningContent,
        ),
        progressPercentage:
            (json['progressPercentage'] as num? ?? 0.0).toDouble(),
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );
}

/// Immutable summary produced at the conclusion of a LearningSession.
@immutable
class LearningFlowSummary {
  final String sessionId;
  final int totalDurationMinutes;
  final int videoWatchTimeMinutes;
  final int notesCreatedCount;
  final int aiQuestionsAskedCount;
  final double quizAccuracy;
  final int revisionScheduledCount;
  final List<String> achievementsEarned;
  final DateTime completedAt;

  const LearningFlowSummary({
    required this.sessionId,
    required this.totalDurationMinutes,
    required this.videoWatchTimeMinutes,
    required this.notesCreatedCount,
    required this.aiQuestionsAskedCount,
    required this.quizAccuracy,
    required this.revisionScheduledCount,
    required this.achievementsEarned,
    required this.completedAt,
  });

  factory LearningFlowSummary.empty(String sessionId) => LearningFlowSummary(
        sessionId: sessionId,
        totalDurationMinutes: 0,
        videoWatchTimeMinutes: 0,
        notesCreatedCount: 0,
        aiQuestionsAskedCount: 0,
        quizAccuracy: 0.0,
        revisionScheduledCount: 0,
        achievementsEarned: const [],
        completedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'totalDurationMinutes': totalDurationMinutes,
        'videoWatchTimeMinutes': videoWatchTimeMinutes,
        'notesCreatedCount': notesCreatedCount,
        'aiQuestionsAskedCount': aiQuestionsAskedCount,
        'quizAccuracy': quizAccuracy,
        'revisionScheduledCount': revisionScheduledCount,
        'achievementsEarned': achievementsEarned,
        'completedAt': completedAt.toIso8601String(),
      };

  factory LearningFlowSummary.fromJson(Map<String, dynamic> json) =>
      LearningFlowSummary(
        sessionId: json['sessionId'] as String? ?? '',
        totalDurationMinutes: json['totalDurationMinutes'] as int? ?? 0,
        videoWatchTimeMinutes: json['videoWatchTimeMinutes'] as int? ?? 0,
        notesCreatedCount: json['notesCreatedCount'] as int? ?? 0,
        aiQuestionsAskedCount: json['aiQuestionsAskedCount'] as int? ?? 0,
        quizAccuracy: (json['quizAccuracy'] as num? ?? 0.0).toDouble(),
        revisionScheduledCount: json['revisionScheduledCount'] as int? ?? 0,
        achievementsEarned: (json['achievementsEarned'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Pure Dart entity representing an active or completed LearningSession.
@immutable
class LearningSession {
  final String sessionId;
  final String userId;
  final String courseId;
  final String courseTitle;
  final String lessonId;
  final String lessonTitle;
  final LearningSessionStatus status;
  final DateTime startTime;
  final DateTime lastActiveTime;
  final StudyCheckpoint lastCheckpoint;
  final List<StudyCheckpoint> checkpoints;

  const LearningSession({
    required this.sessionId,
    required this.userId,
    required this.courseId,
    required this.courseTitle,
    required this.lessonId,
    required this.lessonTitle,
    required this.status,
    required this.startTime,
    required this.lastActiveTime,
    required this.lastCheckpoint,
    required this.checkpoints,
  });

  factory LearningSession.start({
    required String sessionId,
    required String userId,
    required String courseId,
    required String courseTitle,
    required String lessonId,
    required String lessonTitle,
  }) {
    final now = DateTime.now();
    final initialCheckpoint = StudyCheckpoint(
      checkpointId: 'cp_01',
      step: LearningFlowStep.learningContent,
      progressPercentage: 0.0,
      timestamp: now,
    );

    return LearningSession(
      sessionId: sessionId,
      userId: userId,
      courseId: courseId,
      courseTitle: courseTitle,
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      status: LearningSessionStatus.active,
      startTime: now,
      lastActiveTime: now,
      lastCheckpoint: initialCheckpoint,
      checkpoints: [initialCheckpoint],
    );
  }

  LearningSession copyWith({
    LearningSessionStatus? status,
    DateTime? lastActiveTime,
    StudyCheckpoint? lastCheckpoint,
    List<StudyCheckpoint>? checkpoints,
  }) {
    return LearningSession(
      sessionId: sessionId,
      userId: userId,
      courseId: courseId,
      courseTitle: courseTitle,
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      status: status ?? this.status,
      startTime: startTime,
      lastActiveTime: lastActiveTime ?? DateTime.now(),
      lastCheckpoint: lastCheckpoint ?? this.lastCheckpoint,
      checkpoints: checkpoints ?? this.checkpoints,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'userId': userId,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
        'status': status.name,
        'startTime': startTime.toIso8601String(),
        'lastActiveTime': lastActiveTime.toIso8601String(),
        'lastCheckpoint': lastCheckpoint.toJson(),
        'checkpoints': checkpoints.map((c) => c.toJson()).toList(),
      };

  factory LearningSession.fromJson(Map<String, dynamic> json) =>
      LearningSession(
        sessionId: json['sessionId'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        courseId: json['courseId'] as String? ?? '',
        courseTitle: json['courseTitle'] as String? ?? '',
        lessonId: json['lessonId'] as String? ?? '',
        lessonTitle: json['lessonTitle'] as String? ?? '',
        status: LearningSessionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => LearningSessionStatus.active,
        ),
        startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ??
            DateTime.now(),
        lastActiveTime:
            DateTime.tryParse(json['lastActiveTime'] as String? ?? '') ??
                DateTime.now(),
        lastCheckpoint: json['lastCheckpoint'] != null
            ? StudyCheckpoint.fromJson(
                json['lastCheckpoint'] as Map<String, dynamic>)
            : StudyCheckpoint(
                checkpointId: 'cp_0',
                step: LearningFlowStep.learningContent,
                progressPercentage: 0.0,
                timestamp: DateTime.now(),
              ),
        checkpoints: (json['checkpoints'] as List<dynamic>?)
                ?.map(
                    (c) => StudyCheckpoint.fromJson(c as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

/// Aggregate reactive state for the end-to-end learning flow.
@immutable
class LearningFlowState {
  final LearningFlowStep currentStep;
  final bool isOffline;
  final bool isSyncing;
  final bool isInterrupted;
  final String? errorMessage;
  final LearningSession? session;
  final LearningFlowSummary? summary;

  const LearningFlowState({
    required this.currentStep,
    required this.isOffline,
    required this.isSyncing,
    required this.isInterrupted,
    this.errorMessage,
    this.session,
    this.summary,
  });

  factory LearningFlowState.initial() => const LearningFlowState(
        currentStep: LearningFlowStep.dashboard,
        isOffline: false,
        isSyncing: false,
        isInterrupted: false,
        errorMessage: null,
        session: null,
        summary: null,
      );

  LearningFlowState copyWith({
    LearningFlowStep? currentStep,
    bool? isOffline,
    bool? isSyncing,
    bool? isInterrupted,
    String? errorMessage,
    LearningSession? session,
    LearningFlowSummary? summary,
  }) {
    return LearningFlowState(
      currentStep: currentStep ?? this.currentStep,
      isOffline: isOffline ?? this.isOffline,
      isSyncing: isSyncing ?? this.isSyncing,
      isInterrupted: isInterrupted ?? this.isInterrupted,
      errorMessage: errorMessage,
      session: session ?? this.session,
      summary: summary ?? this.summary,
    );
  }
}
