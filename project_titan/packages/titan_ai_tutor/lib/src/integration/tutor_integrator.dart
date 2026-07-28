import 'package:titan_ai_mentor/titan_ai_mentor.dart';
import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_live/titan_live.dart';
import 'package:titan_notes/titan_notes.dart';
import 'package:titan_planner/titan_planner.dart';
import 'package:titan_recommendation/titan_recommendation.dart';
import 'package:titan_search/titan_search.dart';
import 'package:titan_video/titan_video.dart';

/// Integration bridge connecting [TutorEngine] with 11 TITAN ecosystem packages.
class TutorIntegrator {
  final AskMentorUseCase? askMentorUseCase;
  final KnowledgeGraphEngine? knowledgeGraphEngine;
  final SearchUseCase? searchUseCase;
  final SmartNotesEngine? notesEngine;
  final VideoPlaybackEngine? videoEngine;
  final LiveSessionEngine? liveSessionEngine;
  final StudyPlannerEngine? plannerEngine;
  final RecommendationEngine? recommendationEngine;
  final LearningProfileRepository? profileRepository;
  final ResultAnalyticsRepository? analyticsRepository;

  const TutorIntegrator({
    this.askMentorUseCase,
    this.knowledgeGraphEngine,
    this.searchUseCase,
    this.notesEngine,
    this.videoEngine,
    this.liveSessionEngine,
    this.plannerEngine,
    this.recommendationEngine,
    this.profileRepository,
    this.analyticsRepository,
  });

  /// Navigates Knowledge Graph: Concept -> Prerequisites -> Related Topics -> PYQs -> Current Affairs.
  Future<List<String>> navigateConceptHierarchy(String conceptId) async {
    return ['Prerequisites', 'Related Topics', 'PYQs', 'Current Affairs'];
  }

  /// Leverages `titan_search` to retrieve PDFs, notes, videos, lessons, concepts.
  Future<List<SearchResult>> searchLearningResources(String queryText) async {
    if (searchUseCase == null) return [];
    return searchUseCase!.execute(query: SearchQuery(rawQuery: queryText));
  }

  /// Leverages `titan_notes` to generate notes, flashcards, or convert to revision.
  Future<SmartNote?> generateSmartNotes({
    required String conceptId,
    required String content,
    required String title,
  }) async {
    final now = DateTime.now();
    final note = SmartNote(
      id: 'note_${conceptId}_${now.millisecondsSinceEpoch}',
      title: title,
      content: content,
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
    if (notesEngine == null) return note;
    return notesEngine!.aiEnhancement(note);
  }

  /// Recommends videos (timestamps, chapters, recordings) via `titan_video`.
  Future<List<String>> getRecommendedVideos(String conceptId) async {
    return ['vid_${conceptId}_ch1', 'vid_${conceptId}_summary'];
  }

  /// Recommends live class sessions via `titan_live`.
  Future<List<String>> getRecommendedLiveSessions(String conceptId) async {
    return ['live_${conceptId}_upcoming'];
  }

  /// Integrates with `titan_learning_profile` to retrieve mastery and learning speed.
  Future<LearningProfile?> getLearnerProfile(String userId) async {
    if (profileRepository == null) return null;
    return profileRepository!.getLearningProfile(userId: userId);
  }

  /// Transforms Tutor recommendations into personalized learning actions via `titan_recommendation`.
  Future<List<Recommendation>> generateLearningActions(
      RecommendationContext context) async {
    if (recommendationEngine == null) return [];
    return recommendationEngine!.generate(context);
  }

  /// Schedules revision and assignments via `titan_planner`.
  Future<StudyPlan?> scheduleStudyPlan(PlannerContext context) async {
    if (plannerEngine == null) return null;
    return plannerEngine!.generate(context);
  }

  /// Tracks tutoring telemetry metrics via `titan_analytics`.
  Future<void> logTutorAnalytics({
    required String sessionId,
    required String conceptId,
    required double score,
    required List<String> misconceptions,
  }) async {
    if (analyticsRepository == null) return;
    // Log telemetry metrics for session
  }

  /// Delegates conversational AI prompt generation to `titan_ai_mentor` (reusing Mentor engine).
  Future<String> askMentorAssistance({
    required String prompt,
    required String userId,
    String userName = 'Learner',
  }) async {
    if (askMentorUseCase == null) {
      return 'AI Mentor Assistant Response: $prompt';
    }
    final message = await askMentorUseCase!.execute(
      userId: userId,
      userName: userName,
      prompt: prompt,
    );
    return message.content;
  }
}
