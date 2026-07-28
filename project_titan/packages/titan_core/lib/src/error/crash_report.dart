import 'package:meta/meta.dart';

import 'titan_error.dart';

/// Immutable crash report entity aggregating crash stack traces, system metadata, and timestamps.
@immutable
class CrashReport {
  final String id;
  final String errorMessage;
  final String? stackTraceString;
  final String errorType;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  CrashReport({
    required this.id,
    required this.errorMessage,
    this.stackTraceString,
    this.errorType = 'uncaught',
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  })  : timestamp = timestamp ?? DateTime.now(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? {});

  factory CrashReport.fromTitanError(TitanError error) => CrashReport(
        id: 'crash_${DateTime.now().millisecondsSinceEpoch}',
        errorMessage: error.message,
        stackTraceString: error.stackTrace.toString(),
        errorType: error.errorType.name,
        timestamp: error.timestamp,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'errorMessage': errorMessage,
        'stackTraceString': stackTraceString,
        'errorType': errorType,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory CrashReport.fromJson(Map<String, dynamic> json) => CrashReport(
        id: json['id'] as String,
        errorMessage: json['errorMessage'] as String,
        stackTraceString: json['stackTraceString'] as String?,
        errorType: json['errorType'] as String? ?? 'uncaught',
        timestamp: DateTime.parse(json['timestamp'] as String),
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrashReport &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(id, errorMessage);
}
