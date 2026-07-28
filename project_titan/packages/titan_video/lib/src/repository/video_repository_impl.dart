import 'package:titan_learning_content/titan_learning_content.dart';

import '../integration/video_engine_integrator.dart';
import '../models/video_models.dart';
import 'video_repository.dart';

/// Concrete implementation of [VideoRepository] handling playback state persistence,
/// transcript retrieval, bookmarking, caching, and cross-engine synchronization.
class VideoRepositoryImpl implements VideoRepository {
  final VideoEngineIntegrator integrator;
  final Map<String, VideoContent> _videoCatalog = {};
  final Map<String, VideoContent> _metadataCache = {};
  final Map<String, List<VideoBookmark>> _bookmarkStore =
      {}; // Key: '${userId}_${contentId}'
  final Map<String, List<VideoHighlight>> _highlightStore =
      {}; // Key: '${userId}_${contentId}'
  final Map<String, PlaybackHistory> _historyStore =
      {}; // Key: '${userId}_${contentId}'

  VideoRepositoryImpl({
    VideoEngineIntegrator? integrator,
    List<VideoContent>? initialVideos,
  }) : integrator = integrator ?? const VideoEngineIntegrator() {
    if (initialVideos != null && initialVideos.isNotEmpty) {
      for (final v in initialVideos) {
        _videoCatalog[v.id] = v;
        _metadataCache[v.id] = v;
      }
    } else {
      _seedDefaultCatalog();
    }
  }

  void _seedDefaultCatalog() {
    final learningContentPolity = LearningContent(
      id: 'lc_video_01',
      title: 'Preamble & Constitutional Philosophy',
      description:
          'Comprehensive video analysis of sovereign, socialist, secular, democratic, republic principles.',
      type: ContentType.video,
      chapterId: 'chap_p1_1',
      courseId: 'course_polity_101',
      knowledgeNodeId: 'node_polity_preamble',
      metadata: ContentMetadata(
        author: 'Dr. M. Laxmikanth',
        subject: 'Polity',
        topic: 'Indian Polity',
        difficultyLevel: 'Intermediate',
        estimatedDurationMinutes: 30,
        format: 'mp4_hd',
        fileSizeFormat: '145 MB',
        tags: const ['Preamble', 'Constitution', 'Polity'],
        isOfflineAvailable: true,
      ),
      objectives: const [
        ContentObjective(
          id: 'obj_1',
          title: 'Analyze Preamble Keywords',
          description: 'Understand legal implications of Preamble terminology.',
          bloomsTaxonomyLevel: 'Analyze',
        ),
      ],
      prerequisites: const [],
      outcomes: const [
        ContentOutcome(
          id: 'out_1',
          title: 'Preamble Mastery',
          description:
              'Ability to answer UPSC Prelims and Mains questions on Preamble.',
          masteryGain: 15.0,
        ),
      ],
      references: const [],
    );

    final defaultChapters = [
      const VideoChapter(
        id: 'chap_v1_1',
        title: 'Historical Evolution of Preamble',
        startSeconds: 0,
        endSeconds: 300,
        thumbnailUri: 'assets/thumbnails/ch1.png',
      ),
      const VideoChapter(
        id: 'chap_v1_2',
        title: 'Key Terms: Sovereign, Socialist, Secular',
        startSeconds: 300,
        endSeconds: 900,
        thumbnailUri: 'assets/thumbnails/ch2.png',
      ),
      const VideoChapter(
        id: 'chap_v1_3',
        title: 'Kesavananda Bharati Case & Amendability',
        startSeconds: 900,
        endSeconds: 1800,
        thumbnailUri: 'assets/thumbnails/ch3.png',
      ),
    ];

    final defaultSubtitles = [
      const SubtitleTrack(
        id: 'sub_en',
        languageCode: 'en',
        languageName: 'English',
        srcUri: 'assets/subtitles/polity_en.vtt',
        isDefault: true,
      ),
      const SubtitleTrack(
        id: 'sub_hi',
        languageCode: 'hi',
        languageName: 'Hindi',
        srcUri: 'assets/subtitles/polity_hi.vtt',
      ),
    ];

    final defaultTranscript = [
      const TranscriptSegment(
        id: 'ts_1',
        startSeconds: 0,
        endSeconds: 30,
        text:
            'Welcome aspirants. Today we analyze the Preamble of the Indian Constitution.',
        speakerName: 'Dr. Laxmikanth',
        knowledgeNodeId: 'node_polity_preamble_intro',
      ),
      const TranscriptSegment(
        id: 'ts_2',
        startSeconds: 31,
        endSeconds: 90,
        text:
            'The Preamble embodies the basic structure and underlying philosophy of our Democratic Republic.',
        speakerName: 'Dr. Laxmikanth',
        knowledgeNodeId: 'node_polity_basic_structure',
      ),
      const TranscriptSegment(
        id: 'ts_3',
        startSeconds: 91,
        endSeconds: 180,
        text:
            'In the Kesavananda Bharati case 1973, the Supreme Court declared Preamble as an integral part of the Constitution.',
        speakerName: 'Dr. Laxmikanth',
        knowledgeNodeId: 'node_polity_kesavananda',
      ),
    ];

    final videoPolity = VideoContent(
      learningContent: learningContentPolity,
      videoUrl: 'https://cdn.titan.academy/videos/polity_preamble.mp4',
      videoMetadata: const VideoMetadata(
        resolution: '1080p',
        frameRate: 30,
        codec: 'h264',
        bitRateBps: 2500000,
        aspectRatio: 1.7777777777777777,
        isHls: true,
        durationSeconds: 1800,
        thumbnailUri: 'assets/thumbnails/polity_preamble.png',
      ),
      chapters: defaultChapters,
      subtitleTracks: defaultSubtitles,
      transcript: defaultTranscript,
      playbackState: const PlaybackState(
        positionSeconds: 120,
        durationSeconds: 1800,
        isPlaying: false,
      ),
      bookmarks: [
        VideoBookmark(
          id: 'bm_1',
          contentId: 'lc_video_01',
          timestampSeconds: 900,
          note: 'Kesavananda Bharati case ruling details',
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
      notes: [
        VideoNote(
          id: 'vn_1',
          contentId: 'lc_video_01',
          timestampSeconds: 31,
          text: 'Preamble embodies basic structure doctrine.',
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
      highlights: const [
        VideoHighlight(
          id: 'vh_1',
          contentId: 'lc_video_01',
          startSeconds: 300,
          endSeconds: 450,
          note: 'Sovereign & Socialist explanation',
        ),
      ],
    );

    _videoCatalog[videoPolity.id] = videoPolity;
    _metadataCache[videoPolity.id] = videoPolity;
  }

  @override
  Future<VideoContent?> getVideoContentById(String contentId) async {
    return _videoCatalog[contentId] ?? _metadataCache[contentId];
  }

  @override
  Future<PlaybackState> savePlaybackPosition({
    required String userId,
    required String contentId,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    final video = await getVideoContentById(contentId);
    if (video == null) {
      throw ArgumentError('Video with id $contentId not found');
    }

    final key = '${userId}_$contentId';
    final history = _historyStore[key];
    final updatedHistory = PlaybackHistory(
      contentId: contentId,
      userId: userId,
      lastPositionSeconds: positionSeconds,
      watchCount: (history?.watchCount ?? 0) + 1,
      totalTimeWatchedSeconds: (history?.totalTimeWatchedSeconds ?? 0) + 10,
      lastWatchedAt: DateTime.now(),
    );

    _historyStore[key] = updatedHistory;

    final newState = video.playbackState.copyWith(
      positionSeconds: positionSeconds,
      durationSeconds: durationSeconds,
    );

    final updatedVideo = video.copyWith(playbackState: newState);
    _videoCatalog[contentId] = updatedVideo;

    // Cross-engine profile sync
    await integrator.syncWatchProgressToProfile(
      userId: userId,
      video: video,
      watchedSeconds: 10,
    );

    return newState;
  }

  @override
  Future<VideoBookmark> saveBookmark({
    required String userId,
    required String contentId,
    required int timestampSeconds,
    required String note,
  }) async {
    final key = '${userId}_$contentId';
    final bookmarks = _bookmarkStore.putIfAbsent(key, () => []);

    final bookmark = VideoBookmark(
      id: 'bm_${DateTime.now().millisecondsSinceEpoch}',
      contentId: contentId,
      timestampSeconds: timestampSeconds,
      note: note,
      createdAt: DateTime.now(),
    );

    bookmarks.add(bookmark);

    final video = _videoCatalog[contentId];
    if (video != null) {
      _videoCatalog[contentId] =
          video.copyWith(bookmarks: List<VideoBookmark>.from(bookmarks));
    }

    return bookmark;
  }

  @override
  Future<List<VideoBookmark>> getBookmarks({
    required String userId,
    required String contentId,
  }) async {
    final key = '${userId}_$contentId';
    return _bookmarkStore[key] ?? const [];
  }

  @override
  Future<VideoHighlight> saveHighlight({
    required String userId,
    required String contentId,
    required int startSeconds,
    required int endSeconds,
    required String note,
    String? colorHex,
  }) async {
    final key = '${userId}_$contentId';
    final highlights = _highlightStore.putIfAbsent(key, () => []);

    final highlight = VideoHighlight(
      id: 'vh_${DateTime.now().millisecondsSinceEpoch}',
      contentId: contentId,
      startSeconds: startSeconds,
      endSeconds: endSeconds,
      note: note,
      colorHex: colorHex ?? '#FFD54F',
    );

    highlights.add(highlight);

    final video = _videoCatalog[contentId];
    if (video != null) {
      _videoCatalog[contentId] =
          video.copyWith(highlights: List<VideoHighlight>.from(highlights));
    }

    return highlight;
  }

  @override
  Future<List<TranscriptSegment>> getTranscript(String contentId) async {
    final video = await getVideoContentById(contentId);
    return video?.transcript ?? const [];
  }

  @override
  Future<List<SubtitleTrack>> getSubtitles(String contentId) async {
    final video = await getVideoContentById(contentId);
    return video?.subtitleTracks ?? const [];
  }

  @override
  Future<List<ContinueWatching>> getContinueWatching(String userId) async {
    final results = <ContinueWatching>[];

    for (final video in _videoCatalog.values) {
      final key = '${userId}_${video.id}';
      final history = _historyStore[key];
      final pos =
          history?.lastPositionSeconds ?? video.playbackState.positionSeconds;
      final dur = video.videoMetadata.durationSeconds;

      if (pos > 0 && pos < dur) {
        results.add(
          ContinueWatching(
            contentId: video.id,
            videoTitle: video.title,
            thumbnailUri: video.videoMetadata.thumbnailUri,
            lastPositionSeconds: pos,
            totalDurationSeconds: dur,
            progressPercentage: (pos / dur * 100.0).clamp(0.0, 100.0),
            lastWatchedAt: history?.lastWatchedAt ?? DateTime.now(),
          ),
        );
      }
    }

    return results;
  }

  @override
  Future<void> cacheVideoMetadata(VideoContent video) async {
    _metadataCache[video.id] = video;
  }

  @override
  Future<VideoDownload> prepareOfflineDownload({
    required String userId,
    required String contentId,
  }) async {
    final video = await getVideoContentById(contentId);
    if (video == null) {
      throw ArgumentError('Video with id $contentId not found');
    }

    return VideoDownload(
      contentId: contentId,
      localPath: '/storage/titan/downloads/${video.id}.mp4',
      downloadedBytes: 145000000,
      totalBytes: 145000000,
      status: 'completed',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }
}
