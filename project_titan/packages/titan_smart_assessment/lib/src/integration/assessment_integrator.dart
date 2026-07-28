import 'package:titan_ai_mentor/titan_ai_mentor.dart';
import 'package:titan_ai_tutor/titan_ai_tutor.dart';
import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_learning_content/titan_learning_content.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_notes/titan_notes.dart';
import 'package:titan_planner/titan_planner.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_recommendation/titan_recommendation.dart';
import 'package:titan_search/titan_search.dart';
import 'package:titan_video/titan_video.dart';

import '../models/assessment_models.dart';

/// Integration bridge connecting [AssessmentEngine] with 13 TITAN ecosystem packages.
class AssessmentIntegrator {
  final TutorEngine? tutorEngine;
  final AskMentorUseCase? askMentorUseCase;
  final LearningContentRepository? contentRepository;
  final VideoPlaybackEngine? videoEngine;
  final SmartNotesEngine? notesEngine;
  final KnowledgeGraphEngine? knowledgeGraphEngine;
  final SearchUseCase? searchUseCase;
  final LearningProfileRepository? profileRepository;
  final RecommendationEngine? recommendationEngine;
  final StudyPlannerEngine? plannerEngine;
  final ResultAnalyticsRepository? analyticsRepository;

  const AssessmentIntegrator({
    this.tutorEngine,
    this.askMentorUseCase,
    this.contentRepository,
    this.videoEngine,
    this.notesEngine,
    this.knowledgeGraphEngine,
    this.searchUseCase,
    this.profileRepository,
    this.recommendationEngine,
    this.plannerEngine,
    this.analyticsRepository,
  });

  /// Reuses `titan_ai_tutor` to explain wrong answers and detect misconceptions.
  TutorEvaluation explainWrongAnswer({
    required QuizQuestion question,
    required String studentResponse,
  }) {
    final engine = tutorEngine ?? const TutorEngine();
    final topicName = question.topic ?? 'General';
    final concept = TutorConcept(
      id: 'concept_$topicName',
      title: question.question,
      description: question.explanation ?? '',
      subjectCategory: topicName,
      prerequisiteConceptIds: const [],
      relatedTopicIds: const [],
    );

    final exercise = TutorExercise(
      id: 'ex_${question.id}',
      conceptId: concept.id,
      title: question.question,
      prompt: question.question,
    );

    return engine.evaluateAnswer(
      exercise: exercise,
      studentResponse: studentResponse,
      concept: concept,
    );
  }

  /// Reuses `titan_ai_mentor` for motivational feedback & strategic exam guidance.
  Future<AssessmentFeedback> generateMentorFeedback({
    required AssessmentResult result,
    required String userId,
    String userName = 'Aspirant',
  }) async {
    String motivation = 'Keep pressing forward! Persistence is key in UPSC.';
    String strategy = 'Focus revision on identified weak topics.';

    if (askMentorUseCase != null) {
      final msg = await askMentorUseCase!.execute(
        userId: userId,
        userName: userName,
        prompt:
            'Provide motivational feedback for assessment score: ${result.score}/${result.totalPossibleScore}',
      );
      motivation = msg.content;
    }

    return AssessmentFeedback(
      id: 'feedback_${result.id}',
      assessmentId: result.assessmentId,
      motivationalNote: motivation,
      strategicGuidance: strategy,
      strengthsSummary: const ['High accuracy in strong subjects'],
      weaknessSummary:
          result.analysis?.skillGaps.map((g) => g.conceptTitle).toList() ??
              const [],
    );
  }

  /// Leverages `titan_learning_profile` to update mastery, strengths, and progress.
  Future<LearningProfile?> updateLearnerProfile(
      ResultAnalytics analytics) async {
    if (profileRepository == null) return null;
    return profileRepository!.updateProfileFromQuizAnalytics(analytics);
  }

  /// Leverages `titan_notes` to generate revision summaries and flashcards.
  SmartNote generateRevisionNotes({
    required String title,
    required String summaryContent,
    required String conceptId,
  }) {
    final now = DateTime.now();
    final note = SmartNote(
      id: 'rev_note_${now.millisecondsSinceEpoch}',
      title: title,
      content: summaryContent,
      type: NoteType.aiGenerated,
      knowledgeNodeIds: [conceptId],
      sections: const [],
      tags: const [],
      attachments: const [],
      bookmarks: const [],
      versions: const [],
      comments: const [],
      references: const [],
      highlights: const [],
      annotations: const [],
      createdAt: now,
      updatedAt: now,
    );
    final engine = notesEngine ?? const SmartNotesEngine();
    return engine.aiEnhancement(note);
  }

  /// Leverages `titan_search` to find relevant study material.
  Future<List<SearchResult>> searchStudyMaterials(String queryText) async {
    if (searchUseCase == null) return [];
    return searchUseCase!.execute(query: SearchQuery(rawQuery: queryText));
  }

  /// Schedules retests and revision tasks via `titan_planner`.
  StudyPlan? scheduleRevisionPlan(PlannerContext context) {
    if (plannerEngine == null) return null;
    return plannerEngine!.generate(context);
  }
}
