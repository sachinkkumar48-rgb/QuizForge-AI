import '../models/video_models.dart';

/// Clean Architecture abstract repository interface for Professional Video Learning Engine.
abstract class VideoRepository {
  /// Fetches video content item by ID.
  Future<VideoContent?> getVideoContentById(String contentId);

  /// Saves current playback position and updates watching history.
  Future<PlaybackState> savePlaybackPosition({
    required String userId,
    required String contentId,
    required int positionSeconds,
    required int durationSeconds,
  });

  /// Saves a timestamped bookmark for a video.
  Future<VideoBookmark> saveBookmark({
    required String userId,
    required String contentId,
    required int timestampSeconds,
    required String note,
  });

  /// Retrieves bookmarks for a video and user.
  Future<List<VideoBookmark>> getBookmarks({
    required String userId,
    required String contentId,
  });

  /// Saves a video highlight segment.
  Future<VideoHighlight> saveHighlight({
    required String userId,
    required String contentId,
    required int startSeconds,
    required int endSeconds,
    required String note,
    String? colorHex,
  });

  /// Retrieves video transcript segments.
  Future<List<TranscriptSegment>> getTranscript(String contentId);

  /// Retrieves subtitle tracks for a video.
  Future<List<SubtitleTrack>> getSubtitles(String contentId);

  /// Retrieves active continue watching videos for a user.
  Future<List<ContinueWatching>> getContinueWatching(String userId);

  /// Caches video metadata locally.
  Future<void> cacheVideoMetadata(VideoContent video);

  /// Initiates or retrieves offline video download state.
  Future<VideoDownload> prepareOfflineDownload({
    required String userId,
    required String contentId,
  });
}
