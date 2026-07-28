import 'package:meta/meta.dart';

/// Immutable domain model defining difficulty distribution profiles.
@immutable
class DifficultyProfile {
  final String targetDifficultyLevel; // Easy, Medium, Hard, Adaptive
  final double easyRatio; // e.g. 0.30
  final double mediumRatio; // e.g. 0.50
  final double hardRatio; // e.g. 0.20
  final bool adaptiveStepping;

  const DifficultyProfile({
    this.targetDifficultyLevel = 'Medium',
    this.easyRatio = 0.3,
    this.mediumRatio = 0.5,
    this.hardRatio = 0.2,
    this.adaptiveStepping = true,
  });

  DifficultyProfile copyWith({
    String? targetDifficultyLevel,
    double? easyRatio,
    double? mediumRatio,
    double? hardRatio,
    bool? adaptiveStepping,
  }) {
    return DifficultyProfile(
      targetDifficultyLevel:
          targetDifficultyLevel ?? this.targetDifficultyLevel,
      easyRatio: easyRatio ?? this.easyRatio,
      mediumRatio: mediumRatio ?? this.mediumRatio,
      hardRatio: hardRatio ?? this.hardRatio,
      adaptiveStepping: adaptiveStepping ?? this.adaptiveStepping,
    );
  }

  Map<String, dynamic> toJson() => {
        'targetDifficultyLevel': targetDifficultyLevel,
        'easyRatio': easyRatio,
        'mediumRatio': mediumRatio,
        'hardRatio': hardRatio,
        'adaptiveStepping': adaptiveStepping,
      };

  factory DifficultyProfile.fromJson(Map<String, dynamic> json) =>
      DifficultyProfile(
        targetDifficultyLevel:
            json['targetDifficultyLevel'] as String? ?? 'Medium',
        easyRatio: (json['easyRatio'] as num? ?? 0.3).toDouble(),
        mediumRatio: (json['mediumRatio'] as num? ?? 0.5).toDouble(),
        hardRatio: (json['hardRatio'] as num? ?? 0.2).toDouble(),
        adaptiveStepping: json['adaptiveStepping'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DifficultyProfile &&
          runtimeType == other.runtimeType &&
          targetDifficultyLevel == other.targetDifficultyLevel &&
          easyRatio == other.easyRatio;

  @override
  int get hashCode => Object.hash(targetDifficultyLevel, easyRatio);
}
