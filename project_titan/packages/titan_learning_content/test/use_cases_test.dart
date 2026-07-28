import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning_content/titan_learning_content.dart';

void main() {
  group('Use Cases Unit Tests', () {
    late LearningContentRepository repository;
    late GetLearningContentUseCase getLearningContentUseCase;
    late GetChapterContentsUseCase getChapterContentsUseCase;
    late UpdateContentProgressUseCase updateContentProgressUseCase;
    late MarkContentCompletedUseCase markContentCompletedUseCase;
    late ContinueLearningContentUseCase continueLearningContentUseCase;
    late GetRecommendedContentUseCase getRecommendedContentUseCase;

    setUp(() {
      repository = LearningContentRepositoryImpl();
      getLearningContentUseCase = GetLearningContentUseCase(repository);
      getChapterContentsUseCase = GetChapterContentsUseCase(repository);
      updateContentProgressUseCase = UpdateContentProgressUseCase(repository);
      markContentCompletedUseCase = MarkContentCompletedUseCase(repository);
      continueLearningContentUseCase =
          ContinueLearningContentUseCase(repository);
      getRecommendedContentUseCase = GetRecommendedContentUseCase(repository);
    });

    test('GetLearningContentUseCase retrieves content', () async {
      final content = await getLearningContentUseCase.execute('lc_video_01');
      expect(content, isNotNull);
    });

    test('GetChapterContentsUseCase retrieves list', () async {
      final contents = await getChapterContentsUseCase.execute('chap_p1_1');
      expect(contents.isNotEmpty, isTrue);
    });

    test('UpdateContentProgressUseCase updates progress', () async {
      final progress = await updateContentProgressUseCase.execute(
        userId: 'u1',
        contentId: 'lc_video_01',
        lastPositionSeconds: 100,
        completionPercentage: 25.0,
        timeSpentSeconds: 200,
      );
      expect(progress.completionPercentage, equals(25.0));
    });

    test('MarkContentCompletedUseCase marks completed', () async {
      final completion = await markContentCompletedUseCase.execute(
        userId: 'u1',
        contentId: 'lc_video_01',
      );
      expect(completion.contentId, equals('lc_video_01'));
    });

    test('ContinueLearningContentUseCase retrieves next content', () async {
      final content = await continueLearningContentUseCase.execute(
        userId: 'u1',
        chapterId: 'chap_p1_1',
      );
      expect(content, isNotNull);
    });

    test('GetRecommendedContentUseCase filters recommended items', () async {
      final items = await getRecommendedContentUseCase.execute(
        userId: 'u1',
        subject: 'Polity',
      );
      expect(items.every((c) => c.metadata.subject == 'Polity'), isTrue);
    });
  });
}
