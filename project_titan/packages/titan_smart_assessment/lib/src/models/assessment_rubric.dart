import 'package:meta/meta.dart';

/// Immutable domain model representing scoring rubrics and negative marking rules.
@immutable
class AssessmentRubric {
  final String id;
  final String name;
  final List<String> criteria;
  final double maxPoints;
  final double negativePenaltyPerWrong; // e.g. -0.66 for UPSC GS
  final bool partialCreditAllowed;

  const AssessmentRubric({
    required this.id,
    required this.name,
    this.criteria = const [],
    this.maxPoints = 2.0,
    this.negativePenaltyPerWrong = 0.66,
    this.partialCreditAllowed = false,
  });

  AssessmentRubric copyWith({
    String? id,
    String? name,
    List<String>? criteria,
    double? maxPoints,
    double? negativePenaltyPerWrong,
    bool? partialCreditAllowed,
  }) {
    return AssessmentRubric(
      id: id ?? this.id,
      name: name ?? this.name,
      criteria: criteria ?? this.criteria,
      maxPoints: maxPoints ?? this.maxPoints,
      negativePenaltyPerWrong:
          negativePenaltyPerWrong ?? this.negativePenaltyPerWrong,
      partialCreditAllowed: partialCreditAllowed ?? this.partialCreditAllowed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'criteria': criteria,
        'maxPoints': maxPoints,
        'negativePenaltyPerWrong': negativePenaltyPerWrong,
        'partialCreditAllowed': partialCreditAllowed,
      };

  factory AssessmentRubric.fromJson(Map<String, dynamic> json) =>
      AssessmentRubric(
        id: json['id'] as String,
        name: json['name'] as String,
        criteria: (json['criteria'] as List? ?? []).cast<String>(),
        maxPoints: (json['maxPoints'] as num? ?? 2.0).toDouble(),
        negativePenaltyPerWrong:
            (json['negativePenaltyPerWrong'] as num? ?? 0.66).toDouble(),
        partialCreditAllowed: json['partialCreditAllowed'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentRubric &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}
