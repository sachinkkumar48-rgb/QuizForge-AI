import 'package:meta/meta.dart';

/// Immutable entity tracking milestone progress, target hours, and exam goals.
@immutable
class GoalProgress {
  final String title;
  final String category;
  final double targetValue;
  final double currentValue;
  final String unit;
  final DateTime deadline;
  final bool isCompleted;

  const GoalProgress({
    required this.title,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    this.unit = 'hrs',
    required this.deadline,
    this.isCompleted = false,
  });

  double get completionPercentage =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  GoalProgress copyWith({
    String? title,
    String? category,
    double? targetValue,
    double? currentValue,
    String? unit,
    DateTime? deadline,
    bool? isCompleted,
  }) {
    return GoalProgress(
      title: title ?? this.title,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'unit': unit,
        'deadline': deadline.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory GoalProgress.fromJson(Map<String, dynamic> json) => GoalProgress(
        title: json['title'] as String,
        category: json['category'] as String? ?? 'General',
        targetValue: (json['targetValue'] as num? ?? 1.0).toDouble(),
        currentValue: (json['currentValue'] as num? ?? 0.0).toDouble(),
        unit: json['unit'] as String? ?? 'hrs',
        deadline: DateTime.parse(json['deadline'] as String),
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalProgress &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          category == other.category &&
          targetValue == other.targetValue &&
          currentValue == other.currentValue;

  @override
  int get hashCode => Object.hash(title, category, targetValue, currentValue);
}
