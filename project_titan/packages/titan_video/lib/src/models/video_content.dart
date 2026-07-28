import 'package:meta/meta.dart';
import 'package:titan_learning_content/titan_learning_content.dart';

import 'playback_state.dart';
import 'subtitle_track.dart';
import 'transcript_segment.dart';
import 'video_bookmark.dart';
import 'video_chapter.dart';
import 'video_highlight.dart';
import 'video_metadata.dart';
import 'video_note.dart';

/// Immutable domain model composing [LearningContent] for professional video lessons.
@immutable
class VideoContent {
  final LearningContent learningContent;
  final String videoUrl;
  final VideoMetadata videoMetadata;
  final List<VideoChapter> chapters;
  final List<SubtitleTrack> subtitleTracks;
  final List<TranscriptSegment> transcript;
  final PlaybackState playbackState;
  final List<VideoBookmark> bookmarks;
  final List<VideoNote> notes;
  final List<VideoHighlight> highlights;

  VideoContent({
    required this.learningContent,
    required this.videoUrl,
    required this.videoMetadata,
    required List<VideoChapter> chapters,
    required List<SubtitleTrack> subtitleTracks,
    required List<TranscriptSegment> transcript,
    this.playbackState = const PlaybackState(),
    required List<VideoBookmark> bookmarks,
    required List<VideoNote> notes,
    required List<VideoHighlight> highlights,
  })  : chapters = List<VideoChapter>.unmodifiable(chapters),
        subtitleTracks = List<SubtitleTrack>.unmodifiable(subtitleTracks),
        transcript = List<TranscriptSegment>.unmodifiable(transcript),
        bookmarks = List<VideoBookmark>.unmodifiable(bookmarks),
        notes = List<VideoNote>.unmodifiable(notes),
        highlights = List<VideoHighlight>.unmodifiable(highlights);

  // Delegates accessing composed LearningContent properties without duplication
  String get id => learningContent.id;
  String get title => learningContent.title;
  String get description => learningContent.description;
  ContentType get type => learningContent.type;
  ContentMetadata get metadata => learningContent.metadata;
  List<ContentObjective> get objectives => learningContent.objectives;
  List<ContentPrerequisite> get prerequisites => learningContent.prerequisites;
  List<ContentOutcome> get outcomes => learningContent.outcomes;
  ContentProgress? get progress => learningContent.progress;

  VideoContent copyWith({
    LearningContent? learningContent,
    String? videoUrl,
    VideoMetadata? videoMetadata,
    List<VideoChapter>? chapters,
    List<SubtitleTrack>? subtitleTracks,
    List<TranscriptSegment>? transcript,
    PlaybackState? playbackState,
    List<VideoBookmark>? bookmarks,
    List<VideoNote>? notes,
    List<VideoHighlight>? highlights,
  }) {
    return VideoContent(
      learningContent: learningContent ?? this.learningContent,
      videoUrl: videoUrl ?? this.videoUrl,
      videoMetadata: videoMetadata ?? this.videoMetadata,
      chapters: chapters ?? this.chapters,
      subtitleTracks: subtitleTracks ?? this.subtitleTracks,
      transcript: transcript ?? this.transcript,
      playbackState: playbackState ?? this.playbackState,
      bookmarks: bookmarks ?? this.bookmarks,
      notes: notes ?? this.notes,
      highlights: highlights ?? this.highlights,
    );
  }

  Map<String, dynamic> toJson() => {
        'learningContent': learningContent.toJson(),
        'videoUrl': videoUrl,
        'videoMetadata': videoMetadata.toJson(),
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'subtitleTracks': subtitleTracks.map((s) => s.toJson()).toList(),
        'transcript': transcript.map((t) => t.toJson()).toList(),
        'playbackState': playbackState.toJson(),
        'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
        'notes': notes.map((n) => n.toJson()).toList(),
        'highlights': highlights.map((h) => h.toJson()).toList(),
      };

  factory VideoContent.fromJson(Map<String, dynamic> json) => VideoContent(
        learningContent: LearningContent.fromJson(
            Map<String, dynamic>.from(json['learningContent'] as Map)),
        videoUrl: json['videoUrl'] as String? ?? '',
        videoMetadata: VideoMetadata.fromJson(
            Map<String, dynamic>.from(json['videoMetadata'] as Map)),
        chapters: (json['chapters'] as List? ?? [])
            .map((c) =>
                VideoChapter.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
        subtitleTracks: (json['subtitleTracks'] as List? ?? [])
            .map((s) =>
                SubtitleTrack.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList(),
        transcript: (json['transcript'] as List? ?? [])
            .map((t) =>
                TranscriptSegment.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList(),
        playbackState: json['playbackState'] != null
            ? PlaybackState.fromJson(
                Map<String, dynamic>.from(json['playbackState'] as Map))
            : const PlaybackState(),
        bookmarks: (json['bookmarks'] as List? ?? [])
            .map((b) =>
                VideoBookmark.fromJson(Map<String, dynamic>.from(b as Map)))
            .toList(),
        notes: (json['notes'] as List? ?? [])
            .map((n) => VideoNote.fromJson(Map<String, dynamic>.from(n as Map)))
            .toList(),
        highlights: (json['highlights'] as List? ?? [])
            .map((h) =>
                VideoHighlight.fromJson(Map<String, dynamic>.from(h as Map)))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoContent &&
          runtimeType == other.runtimeType &&
          learningContent == other.learningContent &&
          videoUrl == other.videoUrl &&
          videoMetadata == other.videoMetadata &&
          playbackState == other.playbackState &&
          _listEquals(chapters, other.chapters) &&
          _listEquals(subtitleTracks, other.subtitleTracks) &&
          _listEquals(transcript, other.transcript) &&
          _listEquals(bookmarks, other.bookmarks) &&
          _listEquals(notes, other.notes) &&
          _listEquals(highlights, other.highlights);

  @override
  int get hashCode => Object.hash(
        learningContent,
        videoUrl,
        videoMetadata,
        playbackState,
        Object.hashAll(chapters),
        Object.hashAll(subtitleTracks),
        Object.hashAll(transcript),
        Object.hashAll(bookmarks),
        Object.hashAll(notes),
        Object.hashAll(highlights),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
