import '../../domain/entities/knowledge_object.dart';
import '../../domain/search/knowledge_search_query.dart';
import '../../domain/search/knowledge_search_service.dart';
import '../../domain/services/recommendation_service.dart';
import '../../domain/value_objects/knowledge_type.dart';
import 'learner_profile.dart';
import 'mentor_recommendation.dart';
import 'mentor_session.dart';
import 'recommendation_reason.dart';

/// Stateless application service orchestrating Knowledge Engine search, graph traversal,
/// PYQ, and Current Affairs services to generate personalized study guidance for learners.
class AIMentorService {
  final KnowledgeSearchService _searchService;
  final RecommendationService? _recommendationService;

  /// Constructs an [AIMentorService] with required [KnowledgeSearchService] and
  /// optional graph [RecommendationService].
  AIMentorService({
    required KnowledgeSearchService searchService,
    RecommendationService? recommendationService,
  })  : _searchService = searchService,
        _recommendationService = recommendationService;

  /// Generates a comprehensive personalized [MentorRecommendation] payload.
  Future<MentorRecommendation> generateRecommendation(
      LearnerProfile profile) async {
    final weakAreaObjects = await identifyWeakAreas(profile);
    final nextTopicObjects = await suggestNextTopics(profile);
    final pyqObjects = await suggestPYQs(profile);
    final caObjects = await suggestCurrentAffairs(profile);

    final primaryRecommendations = <KnowledgeObject>[
      ...weakAreaObjects,
      ...nextTopicObjects,
    ];

    final prereqObjects = <KnowledgeObject>[];
    final relatedObjects = <KnowledgeObject>[];

    final recService = _recommendationService;
    if (recService != null && primaryRecommendations.isNotEmpty) {
      for (final obj in primaryRecommendations.take(3)) {
        final prereqs = await recService.prerequisiteKnowledge(obj.id);
        final related = await recService.relatedKnowledge(obj.id);
        prereqObjects.addAll(prereqs);
        relatedObjects.addAll(related);
      }
    }

    final reason = profile.weakTopics.isNotEmpty
        ? RecommendationReason.weakAreaRemediation(
            topic: profile.weakTopics.first)
        : (profile.completedTopics.isNotEmpty
            ? RecommendationReason.nextTopicProgression(
                completedTopic: profile.completedTopics.first)
            : RecommendationReason(
                code: 'GOAL_ALIGNMENT',
                explanation:
                    'Recommended study topics aligned with goal: ${profile.currentGoal}.',
              ));

    return MentorRecommendation(
      recommendedTopics: primaryRecommendations.toSet().toList(),
      prerequisites: prereqObjects.toSet().toList(),
      relatedTopics: relatedObjects.toSet().toList(),
      suggestedPYQs: pyqObjects.toSet().toList(),
      suggestedCurrentAffairs: caObjects.toSet().toList(),
      reasoning: reason,
    );
  }

  /// Identifies knowledge objects corresponding to the learner's weak areas.
  Future<List<KnowledgeObject>> identifyWeakAreas(
      LearnerProfile profile) async {
    if (profile.weakTopics.isEmpty) return const [];

    final results = <KnowledgeObject>[];
    for (final topic in profile.weakTopics) {
      final searchResult = await _searchService.searchByTopic(topic, limit: 5);
      results.addAll(searchResult.items);
    }
    return _deduplicate(results);
  }

  /// Suggests next topics advancing from completed topics or preferred subjects.
  Future<List<KnowledgeObject>> suggestNextTopics(
      LearnerProfile profile) async {
    final results = <KnowledgeObject>[];

    final recService = _recommendationService;
    if (recService != null && profile.completedTopics.isNotEmpty) {
      for (final completed in profile.completedTopics) {
        final searchResult =
            await _searchService.searchByTopic(completed, limit: 3);
        for (final obj in searchResult.items) {
          final nextList = await recService.nextTopics(obj.id, limit: 3);
          results.addAll(nextList);
        }
      }
    }

    if (results.isEmpty) {
      final targetSubjects = profile.preferredSubjects.isNotEmpty
          ? profile.preferredSubjects
          : const ['Polity', 'Economy'];

      for (final subj in targetSubjects) {
        final searchResult =
            await _searchService.searchBySubject(subj, limit: 5);
        results.addAll(searchResult.items);
      }
    }

    return _deduplicate(results);
  }

  /// Identifies knowledge objects due for revision practice.
  Future<List<KnowledgeObject>> suggestRevision(LearnerProfile profile) async {
    final revisionTargets = <String>[
      ...profile.completedTopics,
      ...profile.studyHistory,
    ];

    if (revisionTargets.isEmpty) return const [];

    final results = <KnowledgeObject>[];
    for (final target in revisionTargets.take(5)) {
      final searchResult = await _searchService.search(
        KnowledgeSearchQuery(freeText: target, limit: 3),
      );
      results.addAll(searchResult.items);
    }

    return _deduplicate(results);
  }

  /// Suggests Previous Year Questions (PYQs) relevant to the learner's study topics.
  Future<List<KnowledgeObject>> suggestPYQs(
    LearnerProfile profile, {
    List<String>? topics,
  }) async {
    final targetTopics = topics ??
        [
          ...profile.weakTopics,
          ...profile.preferredSubjects,
        ];

    final results = <KnowledgeObject>[];

    if (targetTopics.isNotEmpty) {
      for (final topic in targetTopics.take(3)) {
        final searchResult = await _searchService.search(
          KnowledgeSearchQuery(
            freeText: topic,
            knowledgeTypes: const [KnowledgeType.pyq],
            limit: 5,
          ),
        );
        results.addAll(searchResult.items);
      }
    } else {
      final searchResult = await _searchService.search(
        KnowledgeSearchQuery(
          knowledgeTypes: const [KnowledgeType.pyq],
          limit: 10,
        ),
      );
      results.addAll(searchResult.items);
    }

    return _deduplicate(results);
  }

  /// Suggests Current Affairs articles providing real-world context for study topics.
  Future<List<KnowledgeObject>> suggestCurrentAffairs(
    LearnerProfile profile, {
    List<String>? topics,
  }) async {
    final targetTopics = topics ??
        [
          ...profile.weakTopics,
          ...profile.preferredSubjects,
        ];

    final results = <KnowledgeObject>[];

    if (targetTopics.isNotEmpty) {
      for (final topic in targetTopics.take(3)) {
        final searchResult = await _searchService.search(
          KnowledgeSearchQuery(
            freeText: topic,
            knowledgeTypes: const [KnowledgeType.article],
            limit: 5,
          ),
        );
        results.addAll(searchResult.items);
      }
    } else {
      final searchResult = await _searchService.search(
        KnowledgeSearchQuery(
          knowledgeTypes: const [KnowledgeType.article],
          limit: 10,
        ),
      );
      results.addAll(searchResult.items);
    }

    return _deduplicate(results);
  }

  /// Creates a new [MentorSession] containing a freshly generated recommendation cycle.
  Future<MentorSession> createMentorSession(LearnerProfile profile) async {
    final recommendation = await generateRecommendation(profile);
    final timestamp = DateTime.now();
    final sessionId =
        'session-${profile.learnerId}-${timestamp.millisecondsSinceEpoch}';

    return MentorSession(
      sessionId: sessionId,
      learnerId: profile.learnerId,
      timestamp: timestamp,
      recommendation: recommendation,
      metadata: {
        'goal': profile.currentGoal,
        'weakCount': profile.weakTopics.length,
      },
    );
  }

  static List<KnowledgeObject> _deduplicate(List<KnowledgeObject> items) {
    final seenIds = <String>{};
    final unique = <KnowledgeObject>[];
    for (final item in items) {
      if (seenIds.add(item.id)) {
        unique.add(item);
      }
    }
    return unique;
  }
}
