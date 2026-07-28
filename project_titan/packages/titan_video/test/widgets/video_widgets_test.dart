import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning_content/titan_learning_content.dart';
import 'package:titan_video/titan_video.dart';

void main() {
  final sampleVideo = VideoContent(
    learningContent: LearningContent(
      id: 'v_w_01',
      title: 'Polity Video Lesson',
      description: 'Sample description',
      type: ContentType.video,
      metadata: ContentMetadata(
        author: 'Author',
        subject: 'Polity',
        topic: 'Preamble',
        difficultyLevel: 'Intermediate',
        estimatedDurationMinutes: 20,
        format: 'video_hd',
        tags: const ['polity', 'preamble'],
        isOfflineAvailable: true,
      ),
      objectives: const [],
      prerequisites: const [],
      outcomes: const [],
      references: const [],
    ),
    videoUrl: 'https://example.com/v.mp4',
    videoMetadata: const VideoMetadata(
      resolution: '1080p',
      frameRate: 30,
      codec: 'h264',
      durationSeconds: 1200,
      aspectRatio: 1.77,
      thumbnailUri: 'https://example.com/thumb.png',
    ),
    chapters: const [
      VideoChapter(
        id: 'c1',
        title: 'Chapter 1',
        startSeconds: 0,
        endSeconds: 600,
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
          endSeconds: 60,
          text: 'Sample transcript segment text'),
    ],
    bookmarks: [
      VideoBookmark(
        id: 'b1',
        contentId: 'v_w_01',
        timestampSeconds: 30,
        note: 'Bookmark 1',
        createdAt: DateTime(2026, 1, 1),
      ),
    ],
    notes: [
      VideoNote(
        id: 'n1',
        contentId: 'v_w_01',
        timestampSeconds: 45,
        text: 'Note 1',
        createdAt: DateTime(2026, 1, 1),
      ),
    ],
    highlights: const [],
  );

  testWidgets('VideoPlayerCard renders video title and controls',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VideoPlayerCard(
            video: sampleVideo,
            playbackState: const PlaybackState(
                isPlaying: false, positionSeconds: 10, durationSeconds: 1200),
            onPlayPause: () {},
            onSeek: (_) {},
            onTogglePip: () {},
            onToggleFullscreen: () {},
          ),
        ),
      ),
    );

    expect(find.text('Polity Video Lesson'), findsOneWidget);
    expect(find.byType(PlaybackTimeline), findsOneWidget);
    expect(find.byType(PlaybackControls), findsOneWidget);
  });

  testWidgets('TranscriptPanel displays transcript segment',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptPanel(
            segments: sampleVideo.transcript,
            currentTimestampSeconds: 30,
            onSegmentTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Sample transcript segment text'), findsOneWidget);
  });

  testWidgets('AIQuickActions renders action chips',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AIQuickActions(
            onExplainTimestamp: () {},
            onGenerateSummary: () {},
            onCreateFlashcards: () {},
            onGenerateQuiz: () {},
          ),
        ),
      ),
    );

    expect(find.text('Explain Timestamp'), findsOneWidget);
    expect(find.text('AI Summary'), findsOneWidget);
    expect(find.text('Create Flashcards'), findsOneWidget);
    expect(find.text('Generate Quiz'), findsOneWidget);
  });

  testWidgets('VideoStatisticsCard renders views and completion rate',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VideoStatisticsCard(
            statistics: VideoStatistics(
              totalViews: 1250,
              completionRatePercentage: 85.5,
              averageWatchDurationSeconds: 950,
              totalBookmarks: 10,
              totalNotes: 5,
              rewatchCount: 12,
            ),
          ),
        ),
      ),
    );

    expect(find.text('1250'), findsOneWidget);
    expect(find.text('86%'), findsOneWidget);
  });
}
