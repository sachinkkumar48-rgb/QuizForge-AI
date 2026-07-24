import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('MentorSession Tests', () {
    final rec = MentorRecommendation(
      recommendedTopics: const [],
      reasoning:
          RecommendationReason(code: 'TEST', explanation: 'Test explanation'),
    );

    test('initializes correctly with timestamp and metadata', () {
      final session = MentorSession(
        sessionId: 'sess-001',
        learnerId: 'learner-001',
        recommendation: rec,
        metadata: {'channel': 'app'},
      );

      expect(session.sessionId, equals('sess-001'));
      expect(session.learnerId, equals('learner-001'));
      expect(session.recommendation, equals(rec));
      expect(session.metadata['channel'], equals('app'));
    });

    test('toMap and fromMap achieve full serialization', () {
      final now = DateTime.parse('2026-07-23T15:00:00.000Z');
      final session = MentorSession(
        sessionId: 'sess-002',
        learnerId: 'learner-002',
        timestamp: now,
        recommendation: rec,
      );

      final map = session.toMap();
      final restored = MentorSession.fromMap(map);

      expect(restored, equals(session));
      expect(restored.sessionId, equals('sess-002'));
      expect(restored.timestamp, equals(now));
    });
  });
}
