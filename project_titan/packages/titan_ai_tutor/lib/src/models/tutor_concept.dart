import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing a concept taught by the AI Tutor.
@immutable
class TutorConcept {
  final String id;
  final String title;
  final String description;
  final String subjectCategory;
  final TutorDifficultyLevel baseDifficulty;
  final List<String> prerequisiteConceptIds;
  final List<String> relatedTopicIds;
  final List<String> pyqReferences;
  final double userMasteryScore; // 0.0 to 100.0

  const TutorConcept({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectCategory,
    this.baseDifficulty = TutorDifficultyLevel.intermediate,
    required this.prerequisiteConceptIds,
    required this.relatedTopicIds,
    this.pyqReferences = const [],
    this.userMasteryScore = 0.0,
  });

  TutorConcept copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectCategory,
    TutorDifficultyLevel? baseDifficulty,
    List<String>? prerequisiteConceptIds,
    List<String>? relatedTopicIds,
    List<String>? pyqReferences,
    double? userMasteryScore,
  }) {
    return TutorConcept(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectCategory: subjectCategory ?? this.subjectCategory,
      baseDifficulty: baseDifficulty ?? this.baseDifficulty,
      prerequisiteConceptIds:
          prerequisiteConceptIds ?? this.prerequisiteConceptIds,
      relatedTopicIds: relatedTopicIds ?? this.relatedTopicIds,
      pyqReferences: pyqReferences ?? this.pyqReferences,
      userMasteryScore: userMasteryScore ?? this.userMasteryScore,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subjectCategory': subjectCategory,
        'baseDifficulty': baseDifficulty.name,
        'prerequisiteConceptIds': prerequisiteConceptIds,
        'relatedTopicIds': relatedTopicIds,
        'pyqReferences': pyqReferences,
        'userMasteryScore': userMasteryScore,
      };

  factory TutorConcept.fromJson(Map<String, dynamic> json) => TutorConcept(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        subjectCategory:
            json['subjectCategory'] as String? ?? 'General Studies',
        baseDifficulty: TutorDifficultyLevel.values.firstWhere(
          (e) => e.name == json['baseDifficulty'],
          orElse: () => TutorDifficultyLevel.intermediate,
        ),
        prerequisiteConceptIds:
            (json['prerequisiteConceptIds'] as List? ?? []).cast<String>(),
        relatedTopicIds:
            (json['relatedTopicIds'] as List? ?? []).cast<String>(),
        pyqReferences: (json['pyqReferences'] as List? ?? []).cast<String>(),
        userMasteryScore: (json['userMasteryScore'] as num? ?? 0.0).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorConcept &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          userMasteryScore == other.userMasteryScore;

  @override
  int get hashCode => Object.hash(id, title, userMasteryScore);
}
