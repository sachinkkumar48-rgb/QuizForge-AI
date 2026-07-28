import 'package:meta/meta.dart';

/// Immutable domain model representing memory accumulated across tutoring sessions for a learner.
@immutable
class TutorMemory {
  final String id;
  final String userId;
  final String conceptId;
  final List<String> rememberedMisconceptions;
  final List<String> repeatedErrors;
  final List<String> strengths;
  final List<String> keyTakeaways;
  final DateTime lastInteractedAt;

  const TutorMemory({
    required this.id,
    required this.userId,
    required this.conceptId,
    this.rememberedMisconceptions = const [],
    this.repeatedErrors = const [],
    this.strengths = const [],
    this.keyTakeaways = const [],
    required this.lastInteractedAt,
  });

  TutorMemory copyWith({
    String? id,
    String? userId,
    String? conceptId,
    List<String>? rememberedMisconceptions,
    List<String>? repeatedErrors,
    List<String>? strengths,
    List<String>? keyTakeaways,
    DateTime? lastInteractedAt,
  }) {
    return TutorMemory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      conceptId: conceptId ?? this.conceptId,
      rememberedMisconceptions:
          rememberedMisconceptions ?? this.rememberedMisconceptions,
      repeatedErrors: repeatedErrors ?? this.repeatedErrors,
      strengths: strengths ?? this.strengths,
      keyTakeaways: keyTakeaways ?? this.keyTakeaways,
      lastInteractedAt: lastInteractedAt ?? this.lastInteractedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'conceptId': conceptId,
        'rememberedMisconceptions': rememberedMisconceptions,
        'repeatedErrors': repeatedErrors,
        'strengths': strengths,
        'keyTakeaways': keyTakeaways,
        'lastInteractedAt': lastInteractedAt.toIso8601String(),
      };

  factory TutorMemory.fromJson(Map<String, dynamic> json) => TutorMemory(
        id: json['id'] as String,
        userId: json['userId'] as String,
        conceptId: json['conceptId'] as String,
        rememberedMisconceptions:
            (json['rememberedMisconceptions'] as List? ?? []).cast<String>(),
        repeatedErrors: (json['repeatedErrors'] as List? ?? []).cast<String>(),
        strengths: (json['strengths'] as List? ?? []).cast<String>(),
        keyTakeaways: (json['keyTakeaways'] as List? ?? []).cast<String>(),
        lastInteractedAt: DateTime.parse(json['lastInteractedAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorMemory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          conceptId == other.conceptId;

  @override
  int get hashCode => Object.hash(id, userId, conceptId);
}
