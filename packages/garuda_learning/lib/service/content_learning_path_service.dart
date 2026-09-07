/// Content-to-Learning-Path Service (TITAN-KO-042.0 P42).
///
/// Production domain service connecting content catalogue discovery to the
/// authoritative adaptive learning engine:
/// EXAM → SUBJECT → TOPIC → LEARNING OBJECTIVE → DIAGNOSTIC / START POINT → PRACTICE → PROGRESS.
library;

import 'package:garuda_pyq/garuda_pyq.dart';

import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/bloom_taxonomy_level.dart';
import '../domain/entities/content_learning_path.dart';
import '../domain/entities/learner_dashboard_state.dart';
import '../domain/entities/learning_objective.dart';
import '../domain/entities/session_checkpoint.dart';
import '../repository/session_checkpoint_repository.dart';
import 'adaptive_learning_decision_engine.dart';
import 'authoritative_learning_state_recovery_service.dart';
import 'curriculum_service.dart';
import 'deterministic_remedial_lesson_service.dart';
import 'diagnostic_assessment_service.dart';

/// Pure domain application service orchestrating the content-to-learning-path pipeline.
class ContentLearningPathService {
  final CurriculumService _curriculumService;
  final AuthoritativeLearningStateRecoveryService _authRecoveryService;
  final SessionCheckpointRepository _checkpointRepository;
  final AdaptiveLearningDecisionEngine _decisionEngine;
  final DeterministicRemedialLessonService? _remedialService;
  final DiagnosticAssessmentService? _diagnosticService;
  final List<NormalizedQuestion> _seedQuestions;

  ContentLearningPathService({
    required CurriculumService curriculumService,
    required AuthoritativeLearningStateRecoveryService authRecoveryService,
    required SessionCheckpointRepository checkpointRepository,
    AdaptiveLearningDecisionEngine? decisionEngine,
    DeterministicRemedialLessonService? remedialService,
    DiagnosticAssessmentService? diagnosticService,
    List<NormalizedQuestion>? seedQuestions,
  })  : _curriculumService = curriculumService,
        _authRecoveryService = authRecoveryService,
        _checkpointRepository = checkpointRepository,
        _decisionEngine = decisionEngine ?? AdaptiveLearningDecisionEngine(),
        _remedialService = remedialService,
        _diagnosticService = diagnosticService,
        _seedQuestions = seedQuestions ?? const [];

  CurriculumService get curriculumService => _curriculumService;
  AuthoritativeLearningStateRecoveryService get authRecoveryService =>
      _authRecoveryService;
  SessionCheckpointRepository get checkpointRepository => _checkpointRepository;
  AdaptiveLearningDecisionEngine get decisionEngine => _decisionEngine;
  DeterministicRemedialLessonService? get remedialService => _remedialService;
  DiagnosticAssessmentService? get diagnosticService => _diagnosticService;
  List<NormalizedQuestion> get seedQuestions => _seedQuestions;

  /// Returns the catalogue of available examinations.
  List<ExamContext> getAvailableExams() {
    return const [
      ExamContext(
        id: 'upsc_prelims_gs1',
        code: 'UPSC_PRELIMS_GS1',
        name: 'UPSC Civil Services - Prelims GS1',
        category: 'Central Civil Services',
        conductingBody: 'Union Public Service Commission',
        isSupported: true,
        subjectCount: 2,
        description:
            'General Studies Paper 1 for UPSC Civil Services Preliminary Examination.',
      ),
      ExamContext(
        id: 'cds',
        code: 'CDS',
        name: 'Combined Defence Services Examination',
        category: 'Defense Services',
        conductingBody: 'Union Public Service Commission',
        isSupported: false,
        subjectCount: 0,
        description:
            'Combined Defence Services Examination (Catalogue Preview).',
      ),
      ExamContext(
        id: 'nda',
        code: 'NDA',
        name: 'National Defence Academy Examination',
        category: 'Defense Services',
        conductingBody: 'Union Public Service Commission',
        isSupported: false,
        subjectCount: 0,
        description:
            'National Defence Academy Examination (Catalogue Preview).',
      ),
      ExamContext(
        id: 'capf',
        code: 'CAPF',
        name: 'Central Armed Police Forces (AC)',
        category: 'Defense Services',
        conductingBody: 'Union Public Service Commission',
        isSupported: false,
        subjectCount: 0,
        description:
            'Central Armed Police Forces Examination (Catalogue Preview).',
      ),
      ExamContext(
        id: 'rbi_grade_b',
        code: 'RBI_GRADE_B',
        name: 'RBI Grade B Officer Examination',
        category: 'Regulatory & Banking',
        conductingBody: 'Reserve Bank of India',
        isSupported: false,
        subjectCount: 0,
        description: 'RBI Grade B Officer Examination (Catalogue Preview).',
      ),
    ];
  }

  /// Returns available subjects for a specific [examId].
  List<SubjectContext> getSubjectsForExam(String examId) {
    final cleanExam = examId.trim().toLowerCase();
    if (cleanExam == 'upsc_prelims_gs1' || cleanExam == 'upsc_cse') {
      return const [
        SubjectContext(
          id: 'indian_polity',
          name: 'Indian Polity',
          examId: 'upsc_prelims_gs1',
          topicCount: 5,
          description:
              'Indian Constitution, Political System, Panchayati Raj, Public Policy, Rights Issues.',
        ),
        SubjectContext(
          id: 'economy',
          name: 'Economy',
          examId: 'upsc_prelims_gs1',
          topicCount: 2,
          description:
              'Economic and Social Development, Sustainable Development, Poverty, Inclusion, Demographics.',
        ),
      ];
    }
    return const [];
  }

  /// Returns available topics for a subject within an exam context.
  List<TopicContext> getTopicsForSubject(
    String examId,
    String subjectId, {
    List<NormalizedQuestion>? corpus,
  }) {
    final cleanExam = examId.trim().toLowerCase();
    final cleanSubject = subjectId.trim().toLowerCase();
    final activeCorpus = corpus ?? _seedQuestions;

    int countForTopic(String topicName) {
      final tLower = topicName.trim().toLowerCase();
      return activeCorpus.where((q) {
        return q.topic.trim().toLowerCase() == tLower ||
            q.objectiveIds.any((oid) => oid.trim().toLowerCase() == tLower);
      }).length;
    }

    if ((cleanExam == 'upsc_prelims_gs1' || cleanExam == 'upsc_cse') &&
        (cleanSubject == 'indian_polity' || cleanSubject == 'polity')) {
      final frCount = countForTopic('Fundamental Rights');
      final bsCount = countForTopic('Preamble & Basic Structure');
      final epCount = countForTopic('Emergency Provisions');
      final dpCount = countForTopic('Directive Principles');
      final plCount = countForTopic('Parliament & State Legislature');

      return [
        TopicContext(
          id: 'fundamental_rights',
          name: 'Fundamental Rights',
          subjectId: 'indian_polity',
          examId: 'upsc_prelims_gs1',
          objectiveId: 'lo_article_21_foundations',
          objectiveTitle: 'Evaluate the Expansion of Article 21 Rights',
          description:
              'Fundamental Rights guaranteed under Part III of the Constitution of India.',
          questionCount: frCount,
          hasPyqContent: frCount > 0,
        ),
        TopicContext(
          id: 'preamble_and_basic_structure',
          name: 'Preamble & Basic Structure',
          subjectId: 'indian_polity',
          examId: 'upsc_prelims_gs1',
          objectiveId: 'lo_preamble_identity',
          objectiveTitle:
              'Understand the Preamble as the Key to the Constitution',
          description:
              'Preamble identity and the judicial evolution of the Basic Structure Doctrine.',
          questionCount: bsCount,
          hasPyqContent: bsCount > 0,
        ),
        TopicContext(
          id: 'emergency_provisions',
          name: 'Emergency Provisions',
          subjectId: 'indian_polity',
          examId: 'upsc_prelims_gs1',
          objectiveId: 'lo_emergency_provisions',
          objectiveTitle: 'Emergency Provisions & Constitutional Safeguards',
          description:
              'National, State, and Financial Emergencies under Articles 352-360.',
          questionCount: epCount,
          hasPyqContent: epCount > 0,
        ),
        TopicContext(
          id: 'directive_principles',
          name: 'Directive Principles',
          subjectId: 'indian_polity',
          examId: 'upsc_prelims_gs1',
          objectiveId: 'lo_dpsp',
          objectiveTitle: 'Directive Principles of State Policy',
          description:
              'Part IV Directive Principles and their relation to Fundamental Rights.',
          questionCount: dpCount,
          hasPyqContent: dpCount > 0,
        ),
        TopicContext(
          id: 'parliament_and_state_legislature',
          name: 'Parliament & State Legislature',
          subjectId: 'indian_polity',
          examId: 'upsc_prelims_gs1',
          objectiveId: 'lo_parliament',
          objectiveTitle: 'Legislative Procedure and Parliamentary Privileges',
          description:
              'Structure, functioning, conduct of business, powers & privileges of Parliament.',
          questionCount: plCount,
          hasPyqContent: plCount > 0,
        ),
      ];
    }

    if ((cleanExam == 'upsc_prelims_gs1' || cleanExam == 'upsc_cse') &&
        (cleanSubject == 'economy' || cleanSubject == 'economics')) {
      final macroCount = countForTopic('Macroeconomics');
      final fiscalCount = countForTopic('Fiscal Policy & Budgeting');

      return [
        TopicContext(
          id: 'macroeconomics',
          name: 'Macroeconomics',
          subjectId: 'economy',
          examId: 'upsc_prelims_gs1',
          objectiveId: 'lo_macroeconomics',
          objectiveTitle: 'Macroeconomic Principles & Inflation',
          description:
              'Inflation, Monetary Policy, GDP, and Growth Indicators.',
          questionCount: macroCount,
          hasPyqContent: macroCount > 0,
        ),
        TopicContext(
          id: 'fiscal_policy_and_budgeting',
          name: 'Fiscal Policy & Budgeting',
          subjectId: 'economy',
          examId: 'upsc_prelims_gs1',
          objectiveId: 'lo_fiscal_policy',
          objectiveTitle: 'Fiscal Deficit & Government Budgeting',
          description:
              'Revenue and capital receipts, budget deficit, and fiscal management.',
          questionCount: fiscalCount,
          hasPyqContent: fiscalCount > 0,
        ),
      ];
    }

    return const [];
  }

  /// Retrieves a specific topic by its IDs.
  TopicContext? getTopicById(
    String examId,
    String subjectId,
    String topicId, {
    List<NormalizedQuestion>? corpus,
  }) {
    final topics = getTopicsForSubject(examId, subjectId, corpus: corpus);
    final cleanTopicId = topicId.trim().toLowerCase();
    for (final topic in topics) {
      if (topic.id.toLowerCase() == cleanTopicId ||
          topic.name.toLowerCase() == cleanTopicId) {
        return topic;
      }
    }
    return null;
  }

  /// Resolves the complete content-to-learning-path state for a learner.
  Future<ContentLearningPathState> resolveLearningPath({
    required String learnerId,
    required String examId,
    required String subjectId,
    required String topicId,
    DateTime? asOfDate,
    List<NormalizedQuestion>? corpus,
  }) async {
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();
    final cleanSubject = subjectId.trim().toLowerCase();
    final cleanTopic = topicId.trim().toLowerCase();
    final effectiveDate = (asOfDate ?? DateTime.now()).toUtc();
    final activeCorpus = corpus ?? _seedQuestions;

    if (cleanLearner.isEmpty) {
      return ContentLearningPathState.error(
        message: 'learnerId cannot be empty',
        availableExams: getAvailableExams(),
      );
    }

    final exams = getAvailableExams();
    final ExamContext? exam = exams.cast<ExamContext?>().firstWhere(
          (e) => e?.id == cleanExam || e?.code.toLowerCase() == cleanExam,
          orElse: () => null,
        );

    if (exam == null || !exam.isSupported) {
      return ContentLearningPathState.error(
        message:
            'Exam "$examId" is currently not supported for active learning paths.',
        availableExams: exams,
        selectedExam: exam,
      );
    }

    final subjects = getSubjectsForExam(cleanExam);
    final SubjectContext? subject = subjects.cast<SubjectContext?>().firstWhere(
          (s) =>
              s?.id == cleanSubject ||
              s?.name.toLowerCase() == cleanSubject ||
              (cleanSubject == 'polity' && s?.id == 'indian_polity'),
          orElse: () => null,
        );

    if (subject == null) {
      return ContentLearningPathState.error(
        message: 'Subject "$subjectId" not found for exam "${exam.name}".',
        availableExams: exams,
        selectedExam: exam,
      );
    }

    final topics =
        getTopicsForSubject(cleanExam, subject.id, corpus: activeCorpus);
    final TopicContext? topic = getTopicById(
      cleanExam,
      subject.id,
      cleanTopic,
      corpus: activeCorpus,
    );

    if (topic == null) {
      return ContentLearningPathState.error(
        message: 'Topic "$topicId" not found under subject "${subject.name}".',
        availableExams: exams,
        selectedExam: exam,
      );
    }

    // Resolve Canonical Learning Objective
    final objectiveId = topic.objectiveId ?? 'lo_${topic.id}';
    final LearningObjective resolvedObjective =
        _curriculumService.getObjectiveById(objectiveId) ??
            LearningObjective(
              id: objectiveId,
              unitId: 'unit_${subject.id}',
              title: topic.objectiveTitle ?? topic.name,
              description: topic.description,
              bloomLevel: BloomTaxonomyLevel.understand,
              sequenceIndex: 1,
              provenance: 'UPSC Preliminary Examination Syllabus',
            );

    // Step 2: Truthful Empty-Content Check
    if (!topic.hasPyqContent || topic.questionCount == 0) {
      return ContentLearningPathState(
        status: ContentPathStatus.emptyContent,
        availableExams: exams,
        selectedExam: exam,
        availableSubjects: subjects,
        selectedSubject: subject,
        availableTopics: topics,
        selectedTopic: topic,
        resolvedObjective: resolvedObjective,
        recommendedAction: AdaptiveActionType.none,
        actionTitle: 'No Practice Questions Available',
        actionDescription:
            'Currently, there are no verified PYQ questions for "${topic.name}" in the offline catalogue. Please select another topic to begin learning.',
      );
    }

    // Step 3: Check for Resumable In-Flight Session Checkpoints
    final checkpoints = await _checkpointRepository.listCheckpoints(
      learnerId: cleanLearner,
      examId: cleanExam,
    );
    final uncompleted = checkpoints.where((cp) => !cp.isCompleted).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    SessionCheckpoint? resumableCheckpoint;
    for (final cp in uncompleted) {
      final cpTopic = cp.metadata['topic']?.toString().toLowerCase() ?? '';
      final cpTopicId = cp.metadata['topicId']?.toString().toLowerCase() ?? '';
      if (cp.activeObjectiveId == resolvedObjective.id ||
          cpTopic == topic.name.toLowerCase() ||
          cpTopicId == topic.id) {
        resumableCheckpoint = cp;
        break;
      }
    }

    if (resumableCheckpoint != null) {
      final totalQ = resumableCheckpoint.metadata['totalQuestions'] as int? ??
          (resumableCheckpoint.completedQuestionIds.length + 3);
      final cursor = resumableCheckpoint.questionIndex;

      return ContentLearningPathState(
        status: ContentPathStatus.topicSelected,
        availableExams: exams,
        selectedExam: exam,
        availableSubjects: subjects,
        selectedSubject: subject,
        availableTopics: topics,
        selectedTopic: topic,
        resolvedObjective: resolvedObjective,
        canResumeActiveSession: true,
        activeSessionId: resumableCheckpoint.sessionId,
        activeSessionCursor: cursor,
        activeSessionTotal: totalQ,
        recommendedAction: AdaptiveActionType.continueSession,
        actionTitle: 'Resume Practice Session',
        actionDescription:
            'Continue your in-flight practice session on ${topic.name} from question ${cursor + 1} of $totalQ.',
      );
    }

    // Step 4: Inspect Authoritative Learner State
    final recoveryResult = await _authRecoveryService.recover(
      learnerId: cleanLearner,
      examId: cleanExam,
      requestedAt: effectiveDate,
    );

    final authState = recoveryResult.state ??
        AuthoritativeLearnerState.empty(
          learnerId: cleanLearner,
          examId: cleanExam,
          createdAt: effectiveDate,
        );

    final progress = authState.progressMap[resolvedObjective.id];
    final bool hasAnyAttempts =
        authState.progressMap.values.any((p) => p.attemptCount > 0);

    // Pedagogical Decision Branching
    if (!hasAnyAttempts) {
      // Cold start: learner has zero attempts across exam
      return ContentLearningPathState(
        status: ContentPathStatus.topicSelected,
        availableExams: exams,
        selectedExam: exam,
        availableSubjects: subjects,
        selectedSubject: subject,
        availableTopics: topics,
        selectedTopic: topic,
        resolvedObjective: resolvedObjective,
        isDiagnosticRequired: true,
        authoritativeProgress: progress,
        recommendedAction: AdaptiveActionType.takeDiagnostic,
        actionTitle: 'Take Diagnostic Assessment',
        actionDescription:
            'Evaluate your baseline competency on ${topic.name} to establish your personalized start point.',
      );
    }

    if (progress != null &&
        progress.attemptCount >= 3 &&
        progress.successRate < 0.6) {
      // Persistent weakness condition
      return ContentLearningPathState(
        status: ContentPathStatus.topicSelected,
        availableExams: exams,
        selectedExam: exam,
        availableSubjects: subjects,
        selectedSubject: subject,
        availableTopics: topics,
        selectedTopic: topic,
        resolvedObjective: resolvedObjective,
        authoritativeProgress: progress,
        recommendedAction: AdaptiveActionType.startRemedialLesson,
        actionTitle: 'Start Remedial Lesson: ${topic.name}',
        actionDescription:
            'Persistent conceptual errors detected (${(progress.successRate * 100).toStringAsFixed(0)}% accuracy). A targeted remedial micro-review is recommended before continuing practice.',
      );
    }

    // Ready for adaptive practice
    return ContentLearningPathState(
      status: ContentPathStatus.topicSelected,
      availableExams: exams,
      selectedExam: exam,
      availableSubjects: subjects,
      selectedSubject: subject,
      availableTopics: topics,
      selectedTopic: topic,
      resolvedObjective: resolvedObjective,
      authoritativeProgress: progress,
      recommendedAction: AdaptiveActionType.continuePractice,
      actionTitle: 'Start Adaptive Practice',
      actionDescription:
          'Begin adaptive PYQ-backed practice drill on ${topic.name} (${topic.questionCount} questions available).',
    );
  }
}
