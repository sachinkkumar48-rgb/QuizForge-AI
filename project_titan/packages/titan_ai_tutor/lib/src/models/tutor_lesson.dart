import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing a structured lesson presented by the AI Tutor.
@immutable
class TutorLesson {
  final String id;
  final String title;
  final String conceptId;
  final String explanation;
  final String analogy;
  final String mnemonic;
  final List<String> examples;
  final List<String> recommendedVideoIds;
  final List<String> recommendedNoteIds;
  final List<String> recommendedLiveClassIds;
  final TutorDifficultyLevel difficulty;
  final int estimatedDurationMinutes;
  final DateTime createdAt;

  const TutorLesson({
    required this.id,
    required this.title,
    required this.conceptId,
    required this.explanation,
    this.analogy = '',
    this.mnemonic = '',
    this.examples = const [],
    this.recommendedVideoIds = const [],
    this.recommendedNoteIds = const [],
    this.recommendedLiveClassIds = const [],
    this.difficulty = TutorDifficultyLevel.intermediate,
    this.estimatedDurationMinutes = 15,
    required this.createdAt,
  });

  TutorLesson copyWith({
    String? id,
    String? title,
    String? conceptId,
    String? explanation,
    String? analogy,
    String? mnemonic,
    List<String>? examples,
    List<String>? recommendedVideoIds,
    List<String>? recommendedNoteIds,
    List<String>? recommendedLiveClassIds,
    TutorDifficultyLevel? difficulty,
    int? estimatedDurationMinutes,
    DateTime? createdAt,
  }) {
    return TutorLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      conceptId: conceptId ?? this.conceptId,
      explanation: explanation ?? this.explanation,
      analogy: analogy ?? this.analogy,
      mnemonic: mnemonic ?? this.mnemonic,
      examples: examples ?? this.examples,
      recommendedVideoIds: recommendedVideoIds ?? this.recommendedVideoIds,
      recommendedNoteIds: recommendedNoteIds ?? this.recommendedNoteIds,
      recommendedLiveClassIds:
          recommendedLiveClassIds ?? this.recommendedLiveClassIds,
      difficulty: difficulty ?? this.difficulty,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'conceptId': conceptId,
        'explanation': explanation,
        'analogy': analogy,
        'mnemonic': mnemonic,
        'examples': examples,
        'recommendedVideoIds': recommendedVideoIds,
        'recommendedNoteIds': recommendedNoteIds,
        'recommendedLiveClassIds': recommendedLiveClassIds,
        'difficulty': difficulty.name,
        'estimatedDurationMinutes': estimatedDurationMinutes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TutorLesson.fromJson(Map<String, dynamic> json) => TutorLesson(
        id: json['id'] as String,
        title: json['title'] as String,
        conceptId: json['conceptId'] as String,
        explanation: json['explanation'] as String,
        analogy: json['analogy'] as String? ?? '',
        mnemonic: json['mnemonic'] as String? ?? '',
        examples: (json['examples'] as List? ?? []).cast<String>(),
        recommendedVideoIds:
            (json['recommendedVideoIds'] as List? ?? []).cast<String>(),
        recommendedNoteIds:
            (json['recommendedNoteIds'] as List? ?? []).cast<String>(),
        recommendedLiveClassIds:
            (json['recommendedLiveClassIds'] as List? ?? []).cast<String>(),
        difficulty: TutorDifficultyLevel.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => TutorDifficultyLevel.intermediate,
        ),
        estimatedDurationMinutes:
            json['estimatedDurationMinutes'] as int? ?? 15,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorLesson &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          conceptId == other.conceptId;

  @override
  int get hashCode => Object.hash(id, title, conceptId);
}
