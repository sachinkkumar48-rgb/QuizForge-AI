import 'package:meta/meta.dart';

/// Immutable domain model representing a synchronized transcript segment with knowledge node linkage.
@immutable
class TranscriptSegment {
  final String id;
  final int startSeconds;
  final int endSeconds;
  final String text;
  final String? speakerName;
  final String? knowledgeNodeId;

  const TranscriptSegment({
    required this.id,
    required this.startSeconds,
    required this.endSeconds,
    required this.text,
    this.speakerName,
    this.knowledgeNodeId,
  });

  TranscriptSegment copyWith({
    String? id,
    int? startSeconds,
    int? endSeconds,
    String? text,
    String? speakerName,
    String? knowledgeNodeId,
  }) {
    return TranscriptSegment(
      id: id ?? this.id,
      startSeconds: startSeconds ?? this.startSeconds,
      endSeconds: endSeconds ?? this.endSeconds,
      text: text ?? this.text,
      speakerName: speakerName ?? this.speakerName,
      knowledgeNodeId: knowledgeNodeId ?? this.knowledgeNodeId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startSeconds': startSeconds,
        'endSeconds': endSeconds,
        'text': text,
        'speakerName': speakerName,
        'knowledgeNodeId': knowledgeNodeId,
      };

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) =>
      TranscriptSegment(
        id: json['id'] as String,
        startSeconds: json['startSeconds'] as int? ?? 0,
        endSeconds: json['endSeconds'] as int? ?? 0,
        text: json['text'] as String? ?? '',
        speakerName: json['speakerName'] as String?,
        knowledgeNodeId: json['knowledgeNodeId'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptSegment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          startSeconds == other.startSeconds &&
          endSeconds == other.endSeconds &&
          text == other.text &&
          speakerName == other.speakerName &&
          knowledgeNodeId == other.knowledgeNodeId;

  @override
  int get hashCode => Object.hash(
        id,
        startSeconds,
        endSeconds,
        text,
        speakerName,
        knowledgeNodeId,
      );
}
