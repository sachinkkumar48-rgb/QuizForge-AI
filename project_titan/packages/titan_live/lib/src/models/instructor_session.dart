import 'package:meta/meta.dart';

/// Immutable domain model representing instructor session controls and status.
@immutable
class InstructorSession {
  final String id;
  final String instructorId;
  final String instructorName;
  final String? avatarUrl;
  final String title;
  final String? bio;
  final bool isScreenSharing;
  final bool isWhiteboardActive;
  final bool isAudioMuted;
  final bool isVideoEnabled;

  const InstructorSession({
    required this.id,
    required this.instructorId,
    required this.instructorName,
    this.avatarUrl,
    required this.title,
    this.bio,
    this.isScreenSharing = false,
    this.isWhiteboardActive = false,
    this.isAudioMuted = false,
    this.isVideoEnabled = true,
  });

  InstructorSession copyWith({
    String? id,
    String? instructorId,
    String? instructorName,
    String? avatarUrl,
    String? title,
    String? bio,
    bool? isScreenSharing,
    bool? isWhiteboardActive,
    bool? isAudioMuted,
    bool? isVideoEnabled,
  }) {
    return InstructorSession(
      id: id ?? this.id,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isWhiteboardActive: isWhiteboardActive ?? this.isWhiteboardActive,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'instructorId': instructorId,
        'instructorName': instructorName,
        'avatarUrl': avatarUrl,
        'title': title,
        'bio': bio,
        'isScreenSharing': isScreenSharing,
        'isWhiteboardActive': isWhiteboardActive,
        'isAudioMuted': isAudioMuted,
        'isVideoEnabled': isVideoEnabled,
      };

  factory InstructorSession.fromJson(Map<String, dynamic> json) =>
      InstructorSession(
        id: json['id'] as String,
        instructorId: json['instructorId'] as String,
        instructorName: json['instructorName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        title: json['title'] as String,
        bio: json['bio'] as String?,
        isScreenSharing: json['isScreenSharing'] as bool? ?? false,
        isWhiteboardActive: json['isWhiteboardActive'] as bool? ?? false,
        isAudioMuted: json['isAudioMuted'] as bool? ?? false,
        isVideoEnabled: json['isVideoEnabled'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstructorSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          instructorId == other.instructorId &&
          isScreenSharing == other.isScreenSharing &&
          isWhiteboardActive == other.isWhiteboardActive;

  @override
  int get hashCode =>
      Object.hash(id, instructorId, isScreenSharing, isWhiteboardActive);
}
