import 'package:meta/meta.dart';

/// Immutable entity representing accuracy, speed, and mastery performance trends over time.
@immutable
class PerformanceTrend {
  final List<DateTime> timestamps;
  final List<double> accuracyPoints;
  final List<double> studyHoursPoints;
  final double averageAccuracy;
  final String trendDirection; // 'improving', 'stable', 'declining'

  PerformanceTrend({
    required List<DateTime> timestamps,
    required List<double> accuracyPoints,
    required List<double> studyHoursPoints,
    required this.averageAccuracy,
    this.trendDirection = 'improving',
  })  : timestamps = List<DateTime>.unmodifiable(timestamps),
        accuracyPoints = List<double>.unmodifiable(accuracyPoints),
        studyHoursPoints = List<double>.unmodifiable(studyHoursPoints);

  factory PerformanceTrend.empty() => PerformanceTrend(
        timestamps: [DateTime.now()],
        accuracyPoints: const [0.0],
        studyHoursPoints: const [0.0],
        averageAccuracy: 0.0,
        trendDirection: 'stable',
      );

  PerformanceTrend copyWith({
    List<DateTime>? timestamps,
    List<double>? accuracyPoints,
    List<double>? studyHoursPoints,
    double? averageAccuracy,
    String? trendDirection,
  }) {
    return PerformanceTrend(
      timestamps: timestamps ?? this.timestamps,
      accuracyPoints: accuracyPoints ?? this.accuracyPoints,
      studyHoursPoints: studyHoursPoints ?? this.studyHoursPoints,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      trendDirection: trendDirection ?? this.trendDirection,
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamps': timestamps.map((t) => t.toIso8601String()).toList(),
        'accuracyPoints': accuracyPoints,
        'studyHoursPoints': studyHoursPoints,
        'averageAccuracy': averageAccuracy,
        'trendDirection': trendDirection,
      };

  factory PerformanceTrend.fromJson(Map<String, dynamic> json) =>
      PerformanceTrend(
        timestamps: (json['timestamps'] as List? ?? [])
            .map((t) => DateTime.parse(t as String))
            .toList(),
        accuracyPoints: (json['accuracyPoints'] as List? ?? [])
            .cast<num>()
            .map((e) => e.toDouble())
            .toList(),
        studyHoursPoints: (json['studyHoursPoints'] as List? ?? [])
            .cast<num>()
            .map((e) => e.toDouble())
            .toList(),
        averageAccuracy: (json['averageAccuracy'] as num? ?? 0.0).toDouble(),
        trendDirection: json['trendDirection'] as String? ?? 'stable',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceTrend &&
          runtimeType == other.runtimeType &&
          averageAccuracy == other.averageAccuracy &&
          trendDirection == other.trendDirection;

  @override
  int get hashCode => Object.hash(averageAccuracy, trendDirection);
}
