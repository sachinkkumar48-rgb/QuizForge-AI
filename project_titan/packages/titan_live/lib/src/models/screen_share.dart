import 'package:meta/meta.dart';

/// Immutable domain model representing screen sharing state in a live session.
@immutable
class ScreenShare {
  final String id;
  final String sessionId;
  final String presenterId;
  final String presenterName;
  final String? streamUrl;
  final bool isSharing;
  final DateTime startedAt;

  const ScreenShare({
    required this.id,
    required this.sessionId,
    required this.presenterId,
    required this.presenterName,
    this.streamUrl,
    this.isSharing = false,
    required this.startedAt,
  });

  ScreenShare copyWith({
    String? id,
    String? sessionId,
    String? presenterId,
    String? presenterName,
    String? streamUrl,
    bool? isSharing,
    DateTime? startedAt,
  }) {
    return ScreenShare(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      presenterId: presenterId ?? this.presenterId,
      presenterName: presenterName ?? this.presenterName,
      streamUrl: streamUrl ?? this.streamUrl,
      isSharing: isSharing ?? this.isSharing,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'presenterId': presenterId,
        'presenterName': presenterName,
        'streamUrl': streamUrl,
        'isSharing': isSharing,
        'startedAt': startedAt.toIso8601String(),
      };

  factory ScreenShare.fromJson(Map<String, dynamic> json) => ScreenShare(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        presenterId: json['presenterId'] as String,
        presenterName: json['presenterName'] as String,
        streamUrl: json['streamUrl'] as String?,
        isSharing: json['isSharing'] as bool? ?? false,
        startedAt: DateTime.parse(json['startedAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenShare &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          isSharing == other.isSharing;

  @override
  int get hashCode => Object.hash(id, sessionId, isSharing);
}
