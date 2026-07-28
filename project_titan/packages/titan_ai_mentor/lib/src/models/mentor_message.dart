import 'package:meta/meta.dart';

import 'mentor_recommendation.dart';

/// Sender of a mentor conversation message.
enum MentorMessageSender {
  user,
  mentor,
  system,
}

/// Immutable domain model representing a message in a Mentor conversation.
@immutable
class MentorMessage {
  final String id;
  final MentorMessageSender sender;
  final String content;
  final DateTime timestamp;
  final List<MentorRecommendation> recommendations;
  final Map<String, dynamic> metadata;

  MentorMessage({
    required this.id,
    required this.sender,
    required this.content,
    DateTime? timestamp,
    List<MentorRecommendation>? recommendations,
    Map<String, dynamic>? metadata,
  })  : timestamp = timestamp ?? DateTime.now(),
        recommendations =
            List<MentorRecommendation>.unmodifiable(recommendations ?? []),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? {});

  MentorMessage copyWith({
    String? id,
    MentorMessageSender? sender,
    String? content,
    DateTime? timestamp,
    List<MentorRecommendation>? recommendations,
    Map<String, dynamic>? metadata,
  }) {
    return MentorMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      recommendations: recommendations ?? this.recommendations,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'metadata': metadata,
      };

  factory MentorMessage.fromJson(Map<String, dynamic> json) => MentorMessage(
        id: json['id'] as String,
        sender: MentorMessageSender.values.firstWhere(
          (e) => e.name == json['sender'],
          orElse: () => MentorMessageSender.mentor,
        ),
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        recommendations: (json['recommendations'] as List? ?? [])
            .map((r) => MentorRecommendation.fromJson(
                Map<String, dynamic>.from(r as Map)))
            .toList(),
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentorMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sender == other.sender &&
          content == other.content;

  @override
  int get hashCode => Object.hash(id, sender, content);
}
