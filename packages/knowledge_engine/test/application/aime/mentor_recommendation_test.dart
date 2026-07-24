import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('MentorRecommendation Tests', () {
    final kObj1 = KnowledgeObject(
      id: 'k-100',
      type: KnowledgeType.article,
      title: 'Polity Article',
      summary: 'Summary A',
      source: 'PIB',
    );

    final kObj2 = KnowledgeObject(
      id: 'pyq-100',
      type: KnowledgeType.pyq,
      title: 'PYQ Question',
      summary: 'Summary B',
      source: 'UPSC CSE 2023',
    );

    test('initializes correctly and enforces immutability', () {
      final rec = MentorRecommendation(
        recommendedTopics: [kObj1],
        suggestedPYQs: [kObj2],
        reasoning: RecommendationReason.weakAreaRemediation(topic: 'Polity'),
      );

      expect(rec.recommendedTopics.length, equals(1));
      expect(rec.suggestedPYQs.length, equals(1));
      expect(rec.reasoning.code, equals('WEAK_AREA_REMEDIATION'));

      expect(() => (rec.recommendedTopics as List).add(kObj2),
          throwsUnsupportedError);
    });

    test('toMap and fromMap achieve full serialization', () {
      final rec = MentorRecommendation(
        recommendedTopics: [kObj1],
        suggestedPYQs: [kObj2],
        reasoning: RecommendationReason.nextTopicProgression(
            completedTopic: 'Polity Basics'),
      );

      final map = rec.toMap();
      final restored = MentorRecommendation.fromMap(map);

      expect(restored, equals(rec));
      expect(restored.recommendedTopics.first.id, equals('k-100'));
      expect(restored.suggestedPYQs.first.id, equals('pyq-100'));
    });
  });
}
