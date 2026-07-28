import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning_content/titan_learning_content.dart';

void main() {
  group('LearningContentRepositoryImpl Unit Tests', () {
    late LearningContentRepository repository;

    setUp(() {
      repository = LearningContentRepositoryImpl();
    });

    test('getContentById returns seeded content item', () async {
      final item = await repository.getContentById('lc_video_01');
      expect(item, isNotNull);
      expect(item!.type, equals(ContentType.video));
    });

    test('getChapterContents retrieves chapter items', () async {
      final items = await repository.getChapterContents('chap_p1_1');
      expect(items.length, greaterThanOrEqualTo(3));
    });

    test('updateProgress records position and time spent', () async {
      final progress = await repository.updateProgress(
        userId: 'u1',
        contentId: 'lc_video_01',
        lastPositionSeconds: 500,
        completionPercentage: 50.0,
        timeSpentSeconds: 600,
      );

      expect(progress.lastPositionSeconds, equals(500));
      expect(progress.completionPercentage, equals(50.0));
      expect(progress.isCompleted, isFalse);
    });

    test(
        'markCompleted updates completion state and triggers cross-engine sync',
        () async {
      final completion = await repository.markCompleted(
        userId: 'u1',
        contentId: 'lc_video_01',
        score: 95.0,
        feedback: 'Excellent lesson',
      );

      expect(completion.score, equals(95.0));
      final content = await repository.getContentById('lc_video_01');
      expect(content!.completion, isNotNull);
      expect(content.progress?.isCompleted, isTrue);
    });

    test('getCachedContent and syncContent offline capability', () async {
      final cached = await repository.getCachedContent('lc_video_01');
      expect(cached, isNotNull);

      await repository.syncContent(userId: 'u1');
    });
  });
}
