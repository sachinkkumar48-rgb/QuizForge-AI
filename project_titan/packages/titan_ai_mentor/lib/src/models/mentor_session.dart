import 'package:meta/meta.dart';

import 'mentor_message.dart';

/// Immutable domain model representing an ongoing or historical AI mentor chat session.
@immutable
class MentorSession {
  final String id;
  final String userId;
  final String title;
  final List<MentorMessage> messages;
  final String? summary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

  MentorSession({
    required this.id,
    required this.userId,
    required this.title,
    List<MentorMessage>? messages,
    this.summary,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isArchived = false,
  })  : messages = List<MentorMessage>.unmodifiable(messages ?? []),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  MentorSession copyWith({
    String? id,
    String? userId,
    String? title,
    List<MentorMessage>? messages,
    String? summary,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return MentorSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
        'summary': summary,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isArchived': isArchived,
      };

  factory MentorSession.fromJson(Map<String, dynamic> json) => MentorSession(
        id: json['id'] as String,
        userId: json['userId'] as String,
        title: json['title'] as String,
        messages: (json['messages'] as List? ?? [])
            .map((m) =>
                MentorMessage.fromJson(Map<String, dynamic>.from(m as Map)))
            .toList(),
        summary: json['summary'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        isArchived: json['isArchived'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentorSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title;

  @override
  int get hashCode => Object.hash(id, userId, title);
}
