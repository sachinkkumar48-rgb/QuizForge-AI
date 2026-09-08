/// Grading Policy & Scale Domain Entities (TITAN-KO-050.0 P50).
///
/// Deterministic rubric and letter-grade evaluation policies with configurable
/// threshold bands, boundary handling, and division-by-zero protection.
library;

import 'package:meta/meta.dart';

/// Represents a single discrete grading band (e.g. 'A+', min 90.0%).
@immutable
class GradingScaleBand {
  /// Letter grade symbol (e.g. 'A+', 'A', 'B', 'C', 'D', 'F').
  final String letterGrade;

  /// Inclusive lower percentage bound [0.0, 100.0].
  final double minPercentage;

  /// Educational description or performance tier.
  final String description;

  /// Whether this band represents passing academic standing.
  final bool isPassing;

  const GradingScaleBand({
    required this.letterGrade,
    required this.minPercentage,
    this.description = '',
    this.isPassing = true,
  }) : assert(minPercentage >= 0.0 && minPercentage <= 100.0,
            'minPercentage must be in range [0.0, 100.0]');

  Map<String, dynamic> toJson() => {
        'letterGrade': letterGrade,
        'minPercentage': minPercentage,
        'description': description,
        'isPassing': isPassing,
      };

  factory GradingScaleBand.fromJson(Map<String, dynamic> json) =>
      GradingScaleBand(
        letterGrade: json['letterGrade'] as String? ?? 'F',
        minPercentage: (json['minPercentage'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] as String? ?? '',
        isPassing: json['isPassing'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradingScaleBand &&
          letterGrade == other.letterGrade &&
          minPercentage == other.minPercentage &&
          description == other.description &&
          isPassing == other.isPassing;

  @override
  int get hashCode =>
      Object.hash(letterGrade, minPercentage, description, isPassing);

  @override
  String toString() =>
      'GradingScaleBand($letterGrade >= ${minPercentage.toStringAsFixed(1)}%, pass: $isPassing)';
}

/// Configurable, deterministic grading policy.
@immutable
class GradingPolicy {
  /// Ordered list of bands from highest to lowest threshold.
  final List<GradingScaleBand> bands;

  /// Passing threshold percentage (default 40.0%).
  final double passingPercentage;

  const GradingPolicy({
    this.bands = defaultBands,
    this.passingPercentage = 40.0,
  });

  const GradingPolicy.standard()
      : bands = standardBands,
        passingPercentage = 40.0;

  /// Standard 5-tier institutional scale.
  static const List<GradingScaleBand> standardBands = [
    GradingScaleBand(
      letterGrade: 'A',
      minPercentage: 80.0,
      description: 'Excellent Mastery',
      isPassing: true,
    ),
    GradingScaleBand(
      letterGrade: 'B',
      minPercentage: 65.0,
      description: 'Good Competence',
      isPassing: true,
    ),
    GradingScaleBand(
      letterGrade: 'C',
      minPercentage: 50.0,
      description: 'Average Competence',
      isPassing: true,
    ),
    GradingScaleBand(
      letterGrade: 'D',
      minPercentage: 40.0,
      description: 'Minimum Pass',
      isPassing: true,
    ),
    GradingScaleBand(
      letterGrade: 'F',
      minPercentage: 0.0,
      description: 'Fail',
      isPassing: false,
    ),
  ];

  /// Default 6-tier institutional grading scale.
  static const List<GradingScaleBand> defaultBands = [
    GradingScaleBand(
      letterGrade: 'A+',
      minPercentage: 90.0,
      description: 'Outstanding Distinction',
      isPassing: true,
    ),
    GradingScaleBand(
      letterGrade: 'A',
      minPercentage: 80.0,
      description: 'Excellent Mastery',
      isPassing: true,
    ),
    GradingScaleBand(
      letterGrade: 'B',
      minPercentage: 70.0,
      description: 'Very Good Competence',
      isPassing: true,
    ),
    GradingScaleBand(
      letterGrade: 'C',
      minPercentage: 60.0,
      description: 'Good Standing',
      isPassing: true,
    ),
    GradingScaleBand(
      letterGrade: 'D',
      minPercentage: 40.0,
      description: 'Satisfactory / Minimum Pass',
      isPassing: true,
    ),
    GradingScaleBand(
      letterGrade: 'F',
      minPercentage: 0.0,
      description: 'Unsatisfactory / Fail',
      isPassing: false,
    ),
  ];

  /// Calculates percentage safely.
  double calculatePercentage(double score, double maxScore) {
    if (maxScore <= 0.0 || maxScore.isNaN || maxScore.isInfinite) return 0.0;
    if (score <= 0.0 || score.isNaN || score.isInfinite) return 0.0;
    return (score / maxScore) * 100.0;
  }

  /// Resolves matching band for [percentage].
  GradingScaleBand resolveBand(double percentage) {
    if (percentage.isNaN || percentage.isInfinite || percentage <= 0.0) {
      return bands.lastWhere((b) => b.letterGrade == 'F',
          orElse: () => bands.last);
    }
    final effectivePercentage = percentage > 100.0 ? 100.0 : percentage;
    for (final band in bands) {
      if (effectivePercentage >= band.minPercentage) {
        return band;
      }
    }
    return bands.last;
  }

  /// Deterministically maps [percentage] into a letter grade.
  String calculateGrade(double percentage) {
    return resolveBand(percentage).letterGrade;
  }

  /// Whether [percentage] satisfies passing standards.
  bool isPassing(double percentage) {
    if (percentage.isNaN || percentage.isInfinite) return false;
    return percentage >= passingPercentage;
  }

  Map<String, dynamic> toJson() => {
        'bands': bands.map((b) => b.toJson()).toList(),
        'passingPercentage': passingPercentage,
      };

  factory GradingPolicy.fromJson(Map<String, dynamic> json) => GradingPolicy(
        bands: (json['bands'] as List<dynamic>?)
                ?.map((e) => GradingScaleBand.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList() ??
            defaultBands,
        passingPercentage:
            (json['passingPercentage'] as num?)?.toDouble() ?? 40.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradingPolicy &&
          passingPercentage == other.passingPercentage &&
          _listEquals(bands, other.bands);

  @override
  int get hashCode => Object.hash(passingPercentage, Object.hashAll(bands));

  static bool _listEquals(List<GradingScaleBand> a, List<GradingScaleBand> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
