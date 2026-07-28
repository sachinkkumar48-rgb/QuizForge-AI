import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning_content/titan_learning_content.dart';
import 'package:titan_video/titan_video.dart';

void main() {
  group('VideoContent & Models Tests', () {
    test(
        'VideoContent composes LearningContent and delegates getters without duplication',
        () {
      final lc = LearningContent(
        id: 'lc_test_01',
        title: 'Polity Basics',
        description: 'Basic introduction to Polity',
        type: ContentType.video,
        metadata: ContentMetadata(
          author: 'Author A',
          subject: 'Polity',
          topic: 'Preamble',
          difficultyLevel: 'Beginner',
          estimatedDurationMinutes: 15,
          format: 'video_hd',
          tags: const ['polity', 'preamble'],
          isOfflineAvailable: true,
        ),
        objectives: const [
          ContentObjective(
            id: 'o1',
            title: 'Objective 1',
            description: 'Desc 1',
            bloomsTaxonomyLevel: 'Understand',
          )
        ],
        prerequisites: const [],
        outcomes: const [],
        references: const [],
      );

      final video = VideoContent(
        learningContent: lc,
        videoUrl: 'https://example.com/video.mp4',
        videoMetadata: const VideoMetadata(
          resolution: '1080p',
          frameRate: 60,
          codec: 'h264',
          durationSeconds: 600,
          thumbnailUri: 'https://example.com/thumb.png',
        ),
        chapters: const [
          VideoChapter(
            id: 'c1',
            title: 'Intro',
            startSeconds: 0,
            endSeconds: 100,
            thumbnailUri: 'https://example.com/ch1.png',
          ),
        ],
        subtitleTracks: const [
          SubtitleTrack(
            id: 's1',
            languageCode: 'en',
            languageName: 'English',
            srcUri: 'https://example.com/sub.vtt',
          ),
        ],
        transcript: const [
          TranscriptSegment(
              id: 't1',
              startSeconds: 0,
              endSeconds: 10,
              text: 'Hello Aspirants'),
        ],
        bookmarks: const [],
        notes: const [],
        highlights: const [],
      );

      expect(video.id, equals('lc_test_01'));
      expect(video.title, equals('Polity Basics'));
      expect(video.description, equals('Basic introduction to Polity'));
      expect(video.type, equals(ContentType.video));
      expect(video.objectives.length, equals(1));

      // Test JSON round-trip
      final json = video.toJson();
      final restored = VideoContent.fromJson(json);
      expect(restored.id, equals(video.id));
      expect(restored.videoUrl, equals(video.videoUrl));
      expect(restored.chapters.first.title, equals('Intro'));
    });

    test('VideoQuality and PlaybackSpeed extensions work correctly', () {
      expect(VideoQuality.fhd1080p.label, equals('1080p Full HD'));
      expect(PlaybackSpeed.speed1_5x.multiplier, equals(1.5));
      expect(PlaybackSpeed.speed1_5x.label, equals('1.5x'));
    });
  });
}
