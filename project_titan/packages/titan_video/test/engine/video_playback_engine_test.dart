import 'package:flutter_test/flutter_test.dart';
import 'package:titan_video/titan_video.dart';

void main() {
  group('VideoPlaybackEngine Pure Dart Tests', () {
    late VideoPlaybackEngine engine;

    setUp(() {
      engine = VideoPlaybackEngine(
        chapters: const [
          VideoChapter(
              id: 'c1', title: 'Chapter 1', startSeconds: 0, endSeconds: 100),
          VideoChapter(
              id: 'c2', title: 'Chapter 2', startSeconds: 100, endSeconds: 200),
        ],
      );
    });

    tearDown(() {
      engine.dispose();
    });

    test('Initial state is paused at position 0', () {
      expect(engine.currentState.isPlaying, isFalse);
      expect(engine.currentState.positionSeconds, equals(0));
      expect(engine.currentState.speed, equals(PlaybackSpeed.speed1_0x));
    });

    test('Play, pause, resume state transitions emit on stream', () async {
      final states = <PlaybackState>[];
      final sub = engine.stateStream.listen(states.add);

      engine.play(durationSeconds: 300);
      expect(engine.currentState.isPlaying, isTrue);
      expect(engine.currentState.durationSeconds, equals(300));

      engine.pause();
      expect(engine.currentState.isPlaying, isFalse);

      engine.resume();
      expect(engine.currentState.isPlaying, isTrue);

      await pumpEventQueue();
      expect(states.length, equals(3));
      await sub.cancel();
    });

    test('Seek, Speed, Mute, Volume, PIP, Fullscreen state modifications', () {
      engine.play(durationSeconds: 500);
      engine.seekTo(120);
      expect(engine.currentState.positionSeconds, equals(120));

      engine.setSpeed(PlaybackSpeed.speed1_5x);
      expect(engine.currentState.speed, equals(PlaybackSpeed.speed1_5x));

      engine.toggleMute();
      expect(engine.currentState.isMuted, isTrue);

      engine.setVolume(0.8);
      expect(engine.currentState.volume, equals(0.8));
      expect(engine.currentState.isMuted, isFalse);

      engine.setPipActive(true);
      expect(engine.currentState.isPipActive, isTrue);

      engine.setFullscreen(true);
      expect(engine.currentState.isFullscreen, isTrue);
    });

    test('Jump to chapter updates position to chapter start', () {
      engine.play(durationSeconds: 500);
      engine.jumpToChapter(1);
      expect(engine.currentState.positionSeconds, equals(100));
    });

    test('Tick position advances position according to speed', () {
      engine.play(durationSeconds: 500);
      engine.setSpeed(PlaybackSpeed.speed2_0x);
      engine.tickPosition(5); // 5 * 2 = 10 sec advance
      expect(engine.currentState.positionSeconds, equals(10));
    });
  });
}
