import 'package:flutter_test/flutter_test.dart';
import 'package:titan_video/titan_video.dart';

void main() {
  group('VideoRepositoryImpl Tests', () {
    late VideoRepository repository;

    setUp(() {
      repository = VideoRepositoryImpl();
    });

    test('getVideoContentById retrieves default seeded video', () async {
      final video = await repository.getVideoContentById('lc_video_01');
      expect(video, isNotNull);
      expect(video!.title, contains('Preamble'));
      expect(video.chapters.length, equals(3));
      expect(video.subtitleTracks.length, equals(2));
      expect(video.transcript.length, equals(3));
    });

    test('savePlaybackPosition updates state and history', () async {
      final updatedState = await repository.savePlaybackPosition(
        userId: 'user_123',
        contentId: 'lc_video_01',
        positionSeconds: 450,
        durationSeconds: 1800,
      );

      expect(updatedState.positionSeconds, equals(450));
      expect(updatedState.durationSeconds, equals(1800));

      final continueWatching = await repository.getContinueWatching('user_123');
      expect(continueWatching.length, equals(1));
      expect(continueWatching.first.lastPositionSeconds, equals(450));
    });

    test('saveBookmark and getBookmarks store and retrieve bookmarks',
        () async {
      final bm = await repository.saveBookmark(
        userId: 'user_123',
        contentId: 'lc_video_01',
        timestampSeconds: 600,
        note: 'Important ruling details',
      );

      expect(bm.timestampSeconds, equals(600));

      final bookmarks = await repository.getBookmarks(
          userId: 'user_123', contentId: 'lc_video_01');
      expect(bookmarks.length, equals(1));
      expect(bookmarks.first.note, equals('Important ruling details'));
    });

    test('getTranscript and getSubtitles return lists', () async {
      final transcript = await repository.getTranscript('lc_video_01');
      expect(transcript.isNotEmpty, isTrue);

      final subtitles = await repository.getSubtitles('lc_video_01');
      expect(subtitles.isNotEmpty, isTrue);
    });

    test('prepareOfflineDownload returns completed download status', () async {
      final download = await repository.prepareOfflineDownload(
        userId: 'user_123',
        contentId: 'lc_video_01',
      );

      expect(download.contentId, equals('lc_video_01'));
      expect(download.status, equals('completed'));
    });
  });
}
