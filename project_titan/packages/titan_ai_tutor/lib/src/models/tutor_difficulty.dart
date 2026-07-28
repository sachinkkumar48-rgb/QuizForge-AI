import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing dynamic difficulty settings.
@immutable
class TutorDifficulty {
  final TutorDifficultyLevel currentLevel;
  final double numericScale; // 1.0 to 10.0
  final double dynamicAdjustmentFactor;
  final String adaptReason;

  const TutorDifficulty({
    this.currentLevel = TutorDifficultyLevel.intermediate,
    this.numericScale = 5.0,
    this.dynamicAdjustmentFactor = 1.0,
    this.adaptReason = 'Initial baseline',
  });

  TutorDifficulty copyWith({
    TutorDifficultyLevel? currentLevel,
    double? numericScale,
    double? dynamicAdjustmentFactor,
    String? adaptReason,
  }) {
    return TutorDifficulty(
      currentLevel: currentLevel ?? this.currentLevel,
      numericScale: numericScale ?? this.numericScale,
      dynamicAdjustmentFactor:
          dynamicAdjustmentFactor ?? this.dynamicAdjustmentFactor,
      adaptReason: adaptReason ?? this.adaptReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentLevel': currentLevel.name,
        'numericScale': numericScale,
        'dynamicAdjustmentFactor': dynamicAdjustmentFactor,
        'adaptReason': adaptReason,
      };

  factory TutorDifficulty.fromJson(Map<String, dynamic> json) =>
      TutorDifficulty(
        currentLevel: TutorDifficultyLevel.values.firstWhere(
          (e) => e.name == json['currentLevel'],
          orElse: () => TutorDifficultyLevel.intermediate,
        ),
        numericScale: (json['numericScale'] as num? ?? 5.0).toDouble(),
        dynamicAdjustmentFactor:
            (json['dynamicAdjustmentFactor'] as num? ?? 1.0).toDouble(),
        adaptReason: json['adaptReason'] as String? ?? 'Initial baseline',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorDifficulty &&
          runtimeType == other.runtimeType &&
          currentLevel == other.currentLevel &&
          numericScale == other.numericScale;

  @override
  int get hashCode => Object.hash(currentLevel, numericScale);
}
