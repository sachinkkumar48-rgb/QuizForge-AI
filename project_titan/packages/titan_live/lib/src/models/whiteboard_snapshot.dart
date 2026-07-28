import 'package:meta/meta.dart';

/// Immutable domain model representing a whiteboard snapshot.
@immutable
class WhiteboardSnapshot {
  final String id;
  final String sessionId;
  final String title;
  final String? imageUrl;
  final String drawingDataJson;
  final DateTime capturedAt;
  final String capturedBy;

  const WhiteboardSnapshot({
    required this.id,
    required this.sessionId,
    required this.title,
    this.imageUrl,
    required this.drawingDataJson,
    required this.capturedAt,
    required this.capturedBy,
  });

  WhiteboardSnapshot copyWith({
    String? id,
    String? sessionId,
    String? title,
    String? imageUrl,
    String? drawingDataJson,
    DateTime? capturedAt,
    String? capturedBy,
  }) {
    return WhiteboardSnapshot(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      drawingDataJson: drawingDataJson ?? this.drawingDataJson,
      capturedAt: capturedAt ?? this.capturedAt,
      capturedBy: capturedBy ?? this.capturedBy,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'title': title,
        'imageUrl': imageUrl,
        'drawingDataJson': drawingDataJson,
        'capturedAt': capturedAt.toIso8601String(),
        'capturedBy': capturedBy,
      };

  factory WhiteboardSnapshot.fromJson(Map<String, dynamic> json) =>
      WhiteboardSnapshot(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        title: json['title'] as String,
        imageUrl: json['imageUrl'] as String?,
        drawingDataJson: json['drawingDataJson'] as String,
        capturedAt: DateTime.parse(json['capturedAt'] as String),
        capturedBy: json['capturedBy'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WhiteboardSnapshot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          title == other.title;

  @override
  int get hashCode => Object.hash(id, sessionId, title);
}
