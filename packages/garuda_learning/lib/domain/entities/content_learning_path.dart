/// Content-to-Learning-Path Domain State Entities (TITAN-KO-042.0 P42).
///
/// Encapsulates the immutable entities connecting content discovery to the
/// authoritative adaptive learning engine:
/// EXAM → SUBJECT → TOPIC → LEARNING OBJECTIVE → DIAGNOSTIC / START POINT → PRACTICE → PROGRESS.
library;

import 'package:meta/meta.dart';

import 'learner_progress.dart';
import 'learning_objective.dart';
import 'learner_dashboard_state.dart';

/// Execution and browsing status of the content-to-learning-path journey.
enum ContentPathStatus {
  /// Initial catalogue loaded, awaiting exam selection.
  initial,

  /// Exam selected, subjects displayed.
  examSelected,

  /// Subject selected, topics displayed.
  subjectSelected,

  /// Topic selected, objective resolved and ready for pedagogical action.
  topicSelected,

  /// Selected topic currently has no PYQ-backed practice questions.
  emptyContent,

  /// Background operation in flight.
  loading,

  /// Error loading or resolving content path.
  error;

  bool get isInitial => this == ContentPathStatus.initial;
  bool get isExamSelected => this == ContentPathStatus.examSelected;
  bool get isSubjectSelected => this == ContentPathStatus.subjectSelected;
  bool get isTopicSelected => this == ContentPathStatus.topicSelected;
  bool get isEmptyContent => this == ContentPathStatus.emptyContent;
  bool get isLoading => this == ContentPathStatus.loading;
  bool get isError => this == ContentPathStatus.error;
}

/// Immutable descriptor for an available exam context in QuizForge AI.
@immutable
class ExamContext {
  final String id;
  final String code;
  final String name;
  final String category;
  final String conductingBody;
  final bool isSupported;
  final int subjectCount;
  final String description;

  const ExamContext({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.conductingBody,
    this.isSupported = true,
    this.subjectCount = 0,
    this.description = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamContext &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Immutable descriptor for a subject within an exam context.
@immutable
class SubjectContext {
  final String id;
  final String name;
  final String examId;
  final int topicCount;
  final String description;

  const SubjectContext({
    required this.id,
    required this.name,
    required this.examId,
    this.topicCount = 0,
    this.description = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectContext &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          examId == other.examId;

  @override
  int get hashCode => Object.hash(id, examId);
}

/// Immutable descriptor for a topic within a subject, mapped to a learning objective.
@immutable
class TopicContext {
  final String id;
  final String name;
  final String subjectId;
  final String examId;
  final String? objectiveId;
  final String? objectiveTitle;
  final String description;
  final int questionCount;
  final bool hasPyqContent;

  const TopicContext({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.examId,
    this.objectiveId,
    this.objectiveTitle,
    this.description = '',
    this.questionCount = 0,
    this.hasPyqContent = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicContext &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          subjectId == other.subjectId &&
          examId == other.examId;

  @override
  int get hashCode => Object.hash(id, subjectId, examId);
}

/// Complete immutable state snapshot of the learner's content-to-learning path.
@immutable
class ContentLearningPathState {
  final ContentPathStatus status;
  final List<ExamContext> availableExams;
  final ExamContext? selectedExam;
  final List<SubjectContext> availableSubjects;
  final SubjectContext? selectedSubject;
  final List<TopicContext> availableTopics;
  final TopicContext? selectedTopic;
  final LearningObjective? resolvedObjective;
  final bool isDiagnosticRequired;
  final bool canResumeActiveSession;
  final String? activeSessionId;
  final int? activeSessionCursor;
  final int? activeSessionTotal;
  final LearnerProgress? authoritativeProgress;
  final AdaptiveActionType recommendedAction;
  final String actionTitle;
  final String actionDescription;
  final String? errorMessage;
  final bool isObjectiveAchieved;
  final String? nextObjectiveId;
  final String? nextObjectiveTitle;
  final String? remedialLessonId;

  const ContentLearningPathState({
    required this.status,
    this.availableExams = const [],
    this.selectedExam,
    this.availableSubjects = const [],
    this.selectedSubject,
    this.availableTopics = const [],
    this.selectedTopic,
    this.resolvedObjective,
    this.isDiagnosticRequired = false,
    this.canResumeActiveSession = false,
    this.activeSessionId,
    this.activeSessionCursor,
    this.activeSessionTotal,
    this.authoritativeProgress,
    this.recommendedAction = AdaptiveActionType.none,
    this.actionTitle = '',
    this.actionDescription = '',
    this.errorMessage,
    this.isObjectiveAchieved = false,
    this.nextObjectiveId,
    this.nextObjectiveTitle,
    this.remedialLessonId,
  });

  factory ContentLearningPathState.initial({
    required List<ExamContext> availableExams,
  }) {
    return ContentLearningPathState(
      status: ContentPathStatus.initial,
      availableExams: availableExams,
    );
  }

  factory ContentLearningPathState.loading({
    List<ExamContext>? availableExams,
    ExamContext? selectedExam,
    List<SubjectContext>? availableSubjects,
    SubjectContext? selectedSubject,
  }) {
    return ContentLearningPathState(
      status: ContentPathStatus.loading,
      availableExams: availableExams ?? const [],
      selectedExam: selectedExam,
      availableSubjects: availableSubjects ?? const [],
      selectedSubject: selectedSubject,
    );
  }

  factory ContentLearningPathState.error({
    required String message,
    List<ExamContext>? availableExams,
    ExamContext? selectedExam,
  }) {
    return ContentLearningPathState(
      status: ContentPathStatus.error,
      availableExams: availableExams ?? const [],
      selectedExam: selectedExam,
      errorMessage: message,
    );
  }

  ContentLearningPathState copyWith({
    ContentPathStatus? status,
    List<ExamContext>? availableExams,
    ExamContext? selectedExam,
    List<SubjectContext>? availableSubjects,
    SubjectContext? selectedSubject,
    List<TopicContext>? availableTopics,
    TopicContext? selectedTopic,
    LearningObjective? resolvedObjective,
    bool? isDiagnosticRequired,
    bool? canResumeActiveSession,
    String? activeSessionId,
    int? activeSessionCursor,
    int? activeSessionTotal,
    LearnerProgress? authoritativeProgress,
    AdaptiveActionType? recommendedAction,
    String? actionTitle,
    String? actionDescription,
    String? errorMessage,
    bool? isObjectiveAchieved,
    String? nextObjectiveId,
    String? nextObjectiveTitle,
    String? remedialLessonId,
  }) {
    return ContentLearningPathState(
      status: status ?? this.status,
      availableExams: availableExams ?? this.availableExams,
      selectedExam: selectedExam ?? this.selectedExam,
      availableSubjects: availableSubjects ?? this.availableSubjects,
      selectedSubject: selectedSubject ?? this.selectedSubject,
      availableTopics: availableTopics ?? this.availableTopics,
      selectedTopic: selectedTopic ?? this.selectedTopic,
      resolvedObjective: resolvedObjective ?? this.resolvedObjective,
      isDiagnosticRequired: isDiagnosticRequired ?? this.isDiagnosticRequired,
      canResumeActiveSession:
          canResumeActiveSession ?? this.canResumeActiveSession,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      activeSessionCursor: activeSessionCursor ?? this.activeSessionCursor,
      activeSessionTotal: activeSessionTotal ?? this.activeSessionTotal,
      authoritativeProgress:
          authoritativeProgress ?? this.authoritativeProgress,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      actionTitle: actionTitle ?? this.actionTitle,
      actionDescription: actionDescription ?? this.actionDescription,
      errorMessage: errorMessage ?? this.errorMessage,
      isObjectiveAchieved: isObjectiveAchieved ?? this.isObjectiveAchieved,
      nextObjectiveId: nextObjectiveId ?? this.nextObjectiveId,
      nextObjectiveTitle: nextObjectiveTitle ?? this.nextObjectiveTitle,
      remedialLessonId: remedialLessonId ?? this.remedialLessonId,
    );
  }
}
