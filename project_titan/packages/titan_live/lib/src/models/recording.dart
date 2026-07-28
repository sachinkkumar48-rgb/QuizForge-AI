import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing a live session recording.
@immutable
class Recording {
  final String id;
  final String sessionId;
  final String? videoUrl;
  final int durationSeconds;
  final int fileSizeBytes;
  final RecordingStatus status;
  final DateTime createdAt;
  final String? learningContentId;

  const Recording({
    required this.id,
    required this.sessionId,
    this.videoUrl,
    required this.durationSeconds,
    this.fileSizeBytes = 0,
    this.status = RecordingStatus.notStarted,
    required this.createdAt,
    this.learningContentId,
  });

  Recording copyWith({
    String? id,
    String? sessionId,
    String? videoUrl,
    int? durationSeconds,
    int? fileSizeBytes,
    RecordingStatus? status,
    DateTime? createdAt,
    String? learningContentId,
  }) {
    return Recording(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      videoUrl: videoUrl ?? this.videoUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      learningContentId: learningContentId ?? this.learningContentId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'videoUrl': videoUrl,
        'durationSeconds': durationSeconds,
        'fileSizeBytes': fileSizeBytes,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'learningContentId': learningContentId,
      };

  factory Recording.fromJson(Map<String, dynamic> json) => Recording(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        videoUrl: json['videoUrl'] as String?,
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
        status: RecordingStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => RecordingStatus.notStarted,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        learningContentId: json['learningContentId'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recording &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, sessionId, status);
}
