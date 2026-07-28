import 'package:flutter_test/flutter_test.dart';
import 'package:titan_video/titan_video.dart';

void main() {
  group('Video Engine Use Cases Tests', () {
    late VideoRepository repository;
    late VideoPlaybackEngine engine;
    late PlayVideoUseCase playVideoUseCase;
    late PauseVideoUseCase pauseVideoUseCase;
    late ResumeVideoUseCase resumeVideoUseCase;
    late SeekVideoUseCase seekVideoUseCase;
    late SavePlaybackUseCase savePlaybackUseCase;
    late ToggleBookmarkUseCase toggleBookmarkUseCase;
    late GetTranscriptUseCase getTranscriptUseCase;
    late GetSubtitlesUseCase getSubtitlesUseCase;
    late ContinueWatchingUseCase continueWatchingUseCase;
    late CompleteVideoUseCase completeVideoUseCase;
    late GenerateVideoSummaryUseCase generateVideoSummaryUseCase;

    setUp(() {
      repository = VideoRepositoryImpl();
      engine = VideoPlaybackEngine();
      playVideoUseCase = PlayVideoUseCase(repository, engine);
      pauseVideoUseCase = PauseVideoUseCase(engine);
      resumeVideoUseCase = ResumeVideoUseCase(engine);
      seekVideoUseCase = SeekVideoUseCase(engine);
      savePlaybackUseCase = SavePlaybackUseCase(repository);
      toggleBookmarkUseCase = ToggleBookmarkUseCase(repository);
      getTranscriptUseCase = GetTranscriptUseCase(repository);
      getSubtitlesUseCase = GetSubtitlesUseCase(repository);
      continueWatchingUseCase = ContinueWatchingUseCase(repository);
      completeVideoUseCase = CompleteVideoUseCase(repository);
      generateVideoSummaryUseCase = GenerateVideoSummaryUseCase(repository);
    });

    tearDown(() {
      engine.dispose();
    });

    test('PlayVideoUseCase loads video and starts playback engine', () async {
      final video = await playVideoUseCase.execute('lc_video_01');
      expect(video, isNotNull);
      expect(engine.currentState.isPlaying, isTrue);
      expect(engine.chapters.length, equals(3));
    });

    test('Pause, Resume, Seek use cases operate cleanly on engine', () {
      engine.play(durationSeconds: 1000);
      pauseVideoUseCase.execute();
      expect(engine.currentState.isPlaying, isFalse);

      resumeVideoUseCase.execute();
      expect(engine.currentState.isPlaying, isTrue);

      seekVideoUseCase.execute(300);
      expect(engine.currentState.positionSeconds, equals(300));
    });

    test(
        'SavePlaybackUseCase and ToggleBookmarkUseCase update repository state',
        () async {
      final state = await savePlaybackUseCase.execute(
        userId: 'u1',
        contentId: 'lc_video_01',
        positionSeconds: 150,
        durationSeconds: 1800,
      );
      expect(state.positionSeconds, equals(150));

      final bookmark = await toggleBookmarkUseCase.execute(
        userId: 'u1',
        contentId: 'lc_video_01',
        timestampSeconds: 150,
        note: 'Saved note',
      );
      expect(bookmark.timestampSeconds, equals(150));
    });

    test(
        'GetTranscript, GetSubtitles, and ContinueWatching use cases return expected data',
        () async {
      final transcript = await getTranscriptUseCase.execute('lc_video_01');
      expect(transcript.isNotEmpty, isTrue);

      final subtitles = await getSubtitlesUseCase.execute('lc_video_01');
      expect(subtitles.isNotEmpty, isTrue);

      await savePlaybackUseCase.execute(
        userId: 'u1',
        contentId: 'lc_video_01',
        positionSeconds: 500,
        durationSeconds: 1800,
      );

      final items = await continueWatchingUseCase.execute('u1');
      expect(items.length, equals(1));
    });

    test(
        'CompleteVideoUseCase and GenerateVideoSummaryUseCase execute successfully',
        () async {
      final video = await completeVideoUseCase.execute(
          userId: 'u1', contentId: 'lc_video_01');
      expect(video, isNotNull);

      final summary = await generateVideoSummaryUseCase.execute('lc_video_01');
      expect(summary, contains('Preamble'));
    });
  });
}
