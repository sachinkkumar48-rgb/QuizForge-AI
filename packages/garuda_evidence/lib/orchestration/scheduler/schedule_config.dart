import 'package:meta/meta.dart';

/// Supported scheduling frequencies for evidence collection pipelines.
enum ScheduleType {
  manual,
  hourly,
  daily,
  weekly,
  monthly,
  cron,
}

/// Immutable configuration contract for scheduling evidence collectors.
@immutable
class ScheduleConfig {
  final ScheduleType scheduleType;
  final String? cronExpression;
  final DateTime? lastRunTime;
  final DateTime? nextRunTime;
  final bool isEnabled;

  const ScheduleConfig({
    required this.scheduleType,
    this.cronExpression,
    this.lastRunTime,
    this.nextRunTime,
    this.isEnabled = true,
  });

  ScheduleConfig copyWith({
    ScheduleType? scheduleType,
    String? cronExpression,
    DateTime? lastRunTime,
    DateTime? nextRunTime,
    bool? isEnabled,
  }) {
    return ScheduleConfig(
      scheduleType: scheduleType ?? this.scheduleType,
      cronExpression: cronExpression ?? this.cronExpression,
      lastRunTime: lastRunTime ?? this.lastRunTime,
      nextRunTime: nextRunTime ?? this.nextRunTime,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'scheduleType': scheduleType.name,
        'cronExpression': cronExpression,
        'lastRunTime': lastRunTime?.toIso8601String(),
        'nextRunTime': nextRunTime?.toIso8601String(),
        'isEnabled': isEnabled,
      };

  factory ScheduleConfig.fromJson(Map<String, dynamic> json) => ScheduleConfig(
        scheduleType: ScheduleType.values.firstWhere(
          (e) => e.name == json['scheduleType'],
          orElse: () => ScheduleType.manual,
        ),
        cronExpression: json['cronExpression'] as String?,
        lastRunTime: json['lastRunTime'] != null
            ? DateTime.tryParse(json['lastRunTime'] as String)
            : null,
        nextRunTime: json['nextRunTime'] != null
            ? DateTime.tryParse(json['nextRunTime'] as String)
            : null,
        isEnabled: json['isEnabled'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleConfig &&
        other.scheduleType == scheduleType &&
        other.cronExpression == cronExpression &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode => Object.hash(scheduleType, cronExpression, isEnabled);
}
