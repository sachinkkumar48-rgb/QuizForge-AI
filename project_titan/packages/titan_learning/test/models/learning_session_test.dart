import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning/titan_learning.dart';

void main() {
  group('Session Models Unit Tests', () {
    test('LearningSession JSON serialization and deserialization', () {
      final session = LearningSession.start(
        sessionId: 's_001',
        userId: 'u_001',
        courseId: 'c_001',
        courseTitle: 'Polity',
        lessonId: 'l_001',
        lessonTitle: 'Fundamental Rights',
      );

      final json = session.toJson();
      final deserialized = LearningSession.fromJson(json);

      expect(deserialized.sessionId, equals(session.sessionId));
      expect(deserialized.userId, equals(session.userId));
      expect(deserialized.courseTitle, equals(session.courseTitle));
      expect(deserialized.status, equals(LearningSessionStatus.active));
    });

    test('LearningFlowSummary JSON serialization', () {
      final summary = LearningFlowSummary.empty('s_100');
      final json = summary.toJson();
      final restored = LearningFlowSummary.fromJson(json);

      expect(restored.sessionId, equals('s_100'));
    });
  });
}
