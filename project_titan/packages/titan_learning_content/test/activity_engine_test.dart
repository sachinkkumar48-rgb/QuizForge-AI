import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning_content/titan_learning_content.dart';

void main() {
  group('LearningActivityEngine Unit Tests', () {
    late LearningActivityEngine engine;

    setUp(() {
      engine = LearningActivityEngine();
    });

    test('recordActivity logs event and returns aggregate record', () {
      final record = engine.recordStarted(userId: 'u1', contentId: 'lc1');
      expect(record.userId, equals('u1'));
      expect(record.contentId, equals('lc1'));
      expect(record.activityCount, equals(1));
      expect(record.activityBreakdown['started'], equals(1));
    });

    test('tracks all activity types correctly', () {
      engine.recordStarted(userId: 'u1', contentId: 'lc1');
      engine.recordViewed(userId: 'u1', contentId: 'lc1', durationSeconds: 60);
      engine.recordPlayed(userId: 'u1', contentId: 'lc1', durationSeconds: 120);
      engine.recordRead(userId: 'u1', contentId: 'lc1', durationSeconds: 40);
      engine.recordPaused(userId: 'u1', contentId: 'lc1', durationSeconds: 10);
      engine.recordResumed(userId: 'u1', contentId: 'lc1');
      engine.recordAttempted(userId: 'u1', contentId: 'lc1');
      engine.recordCompleted(
          userId: 'u1', contentId: 'lc1', durationSeconds: 30);
      engine.recordRevised(userId: 'u1', contentId: 'lc1', durationSeconds: 20);
      engine.recordDownloaded(userId: 'u1', contentId: 'lc1');
      engine.recordShared(userId: 'u1', contentId: 'lc1');
      engine.recordAskedAI(
          userId: 'u1', contentId: 'lc1', query: 'What is Preamble?');
      final record = engine.recordDiscussed(
          userId: 'u1', contentId: 'lc1', topic: 'Constitutional Rights');

      expect(record.activityCount, equals(13));
      expect(record.totalDurationSeconds, equals(280));
      expect(record.activityBreakdown.length, equals(13));
    });
  });
}
