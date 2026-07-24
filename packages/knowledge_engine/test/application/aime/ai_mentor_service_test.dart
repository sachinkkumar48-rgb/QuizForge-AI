import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

import '../../domain/services/recommendation_service_test.dart';
import '../../domain/services/relationship_query_service_test.dart';

void main() {
  group('AIMentorService Tests', () {
    late FakeKnowledgeRepository knowledgeRepository;
    late FakeRelationshipRepository relRepository;
    late KnowledgeSearchService searchService;
    late RecommendationService recommendationService;
    late AIMentorService mentorService;

    final weakTopicObj = KnowledgeObject(
      id: 'k-weak-1',
      type: KnowledgeType.pdf,
      title: 'Judicial Review and Basic Structure',
      summary: 'Explanation of Judicial Review in Indian Constitution.',
      source: 'Polity Textbook',
      subjects: ['Polity'],
      topics: ['Judicial Review'],
      keywords: ['Judicial Review', 'Polity'],
    );

    final completedTopicObj = KnowledgeObject(
      id: 'k-completed-1',
      type: KnowledgeType.pdf,
      title: 'Preamble Features',
      summary: 'Summary of Preamble features.',
      source: 'Polity Textbook',
      subjects: ['Polity'],
      topics: ['Preamble'],
      keywords: ['Preamble', 'Polity'],
    );

    final pyqObj = KnowledgeObject(
      id: 'pyq-2023-01',
      type: KnowledgeType.pyq,
      title: '[UPSC CSE 2023] Judicial Review Question',
      summary: 'PYQ on Judicial Review powers.',
      source: 'UPSC CSE 2023',
      subjects: ['Polity'],
      topics: ['Judicial Review'],
      keywords: ['Judicial Review', 'PYQ', 'Polity'],
    );

    final caObj = KnowledgeObject(
      id: 'ca-2026-01',
      type: KnowledgeType.article,
      title: 'Supreme Court Ruling on Judicial Appointments',
      summary: 'Current affairs article on judicial review.',
      source: 'The Hindu',
      subjects: ['Polity'],
      topics: ['Judicial Review'],
      keywords: ['Judicial Review', 'Current Affairs', 'Polity'],
    );

    setUp(() async {
      knowledgeRepository = FakeKnowledgeRepository();
      relRepository = FakeRelationshipRepository();

      await knowledgeRepository.save(weakTopicObj);
      await knowledgeRepository.save(completedTopicObj);
      await knowledgeRepository.save(pyqObj);
      await knowledgeRepository.save(caObj);

      final queryService = RelationshipQueryService(relRepository);
      final traversalService = KnowledgeTraversalService(queryService);

      searchService = KnowledgeSearchService(
        knowledgeRepository: knowledgeRepository,
        queryService: queryService,
        traversalService: traversalService,
      );

      recommendationService = RecommendationService(
        knowledgeRepository: knowledgeRepository,
        queryService: queryService,
        traversalService: traversalService,
      );

      mentorService = AIMentorService(
        searchService: searchService,
        recommendationService: recommendationService,
      );
    });

    test(
        'identifyWeakAreas retrieves KnowledgeObjects corresponding to weakTopics',
        () async {
      final profile = LearnerProfile(
        learnerId: 'learner-100',
        weakTopics: ['Judicial Review'],
      );

      final weakAreas = await mentorService.identifyWeakAreas(profile);
      expect(weakAreas.length, greaterThanOrEqualTo(1));
      expect(weakAreas.any((obj) => obj.id == 'k-weak-1'), isTrue);
    });

    test(
        'suggestNextTopics suggests topics based on completed topics or preferred subjects',
        () async {
      final profile = LearnerProfile(
        learnerId: 'learner-101',
        completedTopics: ['Preamble'],
        preferredSubjects: ['Polity'],
      );

      final nextTopics = await mentorService.suggestNextTopics(profile);
      expect(nextTopics, isNotEmpty);
    });

    test('suggestRevision retrieves completed and study history items',
        () async {
      final profile = LearnerProfile(
        learnerId: 'learner-102',
        completedTopics: ['Judicial Review'],
        studyHistory: ['k-completed-1'],
      );

      final revisionItems = await mentorService.suggestRevision(profile);
      expect(revisionItems, isNotEmpty);
    });

    test('suggestPYQs filters PYQ knowledge objects relevant to topics',
        () async {
      final profile = LearnerProfile(
        learnerId: 'learner-103',
        weakTopics: ['Judicial Review'],
      );

      final pyqs = await mentorService.suggestPYQs(profile);
      expect(pyqs.length, greaterThanOrEqualTo(1));
      expect(pyqs.first.type, equals(KnowledgeType.pyq));
      expect(pyqs.first.id, equals('pyq-2023-01'));
    });

    test(
        'suggestCurrentAffairs filters article knowledge objects relevant to topics',
        () async {
      final profile = LearnerProfile(
        learnerId: 'learner-104',
        weakTopics: ['Judicial Review'],
      );

      final ca = await mentorService.suggestCurrentAffairs(profile);
      expect(ca.length, greaterThanOrEqualTo(1));
      expect(ca.first.type, equals(KnowledgeType.article));
      expect(ca.first.id, equals('ca-2026-01'));
    });

    test(
        'generateRecommendation orchestrates full recommendation payload deterministically',
        () async {
      final profile = LearnerProfile(
        learnerId: 'learner-105',
        weakTopics: ['Judicial Review'],
        preferredSubjects: ['Polity'],
        currentGoal: 'UPSC CSE 2026',
      );

      final rec = await mentorService.generateRecommendation(profile);

      expect(rec.recommendedTopics, isNotEmpty);
      expect(rec.suggestedPYQs, isNotEmpty);
      expect(rec.suggestedCurrentAffairs, isNotEmpty);
      expect(rec.reasoning.code, equals('WEAK_AREA_REMEDIATION'));
    });

    test(
        'createMentorSession creates session with timestamp and recommendation payload',
        () async {
      final profile = LearnerProfile(
        learnerId: 'learner-106',
        weakTopics: ['Judicial Review'],
      );

      final session = await mentorService.createMentorSession(profile);

      expect(session.sessionId, contains('learner-106'));
      expect(session.learnerId, equals('learner-106'));
      expect(session.recommendation.reasoning.code,
          equals('WEAK_AREA_REMEDIATION'));
      expect(session.metadata['goal'], equals(profile.currentGoal));
    });
  });
}
