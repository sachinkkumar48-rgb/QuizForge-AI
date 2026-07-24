import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('RecommendationReason Tests', () {
    test('initializes correctly with factory constructors', () {
      final weakReason =
          RecommendationReason.weakAreaRemediation(topic: 'Judicial Review');
      expect(weakReason.code, equals('WEAK_AREA_REMEDIATION'));
      expect(weakReason.explanation, contains('Judicial Review'));
      expect(weakReason.weight, equals(0.95));

      final nextReason =
          RecommendationReason.nextTopicProgression(completedTopic: 'Preamble');
      expect(nextReason.code, equals('NEXT_TOPIC_PROGRESSION'));
      expect(nextReason.explanation, contains('Preamble'));

      final prereqReason =
          RecommendationReason.prerequisiteGap(targetTopic: 'Basic Structure');
      expect(prereqReason.code, equals('PREREQUISITE_GAP'));

      final revisionReason =
          RecommendationReason.revisionDue(topic: 'Fundamental Duties');
      expect(revisionReason.code, equals('REVISION_DUE'));
    });

    test('throws assertion error for invalid weight out of range [0.0, 1.0]',
        () {
      expect(
        () =>
            RecommendationReason(code: 'TEST', explanation: 'exp', weight: 1.5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('toMap and fromMap achieve full serialization', () {
      final reason = RecommendationReason(
        code: 'CUSTOM_REASON',
        explanation: 'Custom reason explanation.',
        weight: 0.88,
        metadata: {'tag': 'custom'},
      );

      final map = reason.toMap();
      final restored = RecommendationReason.fromMap(map);

      expect(restored, equals(reason));
      expect(restored.code, equals('CUSTOM_REASON'));
      expect(restored.weight, equals(0.88));
    });
  });
}
