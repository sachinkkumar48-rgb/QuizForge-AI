import 'package:meta/meta.dart';

/// Health status enum for external evidence sources.
enum SourceHealthStatus {
  healthy,
  degraded,
  unavailable,
  unknown,
}

/// Immutable monitoring model for source health diagnostics.
@immutable
class SourceHealth {
  final String source;
  final bool enabled;
  final SourceHealthStatus status;
  final DateTime? lastSuccessfulSync;
  final DateTime? lastFailedSync;
  final int failureCount;
  final double averageProcessingTimeMs;
  final String? lastError;
  final double healthScore;

  const SourceHealth({
    required this.source,
    this.enabled = true,
    this.status = SourceHealthStatus.healthy,
    this.lastSuccessfulSync,
    this.lastFailedSync,
    this.failureCount = 0,
    this.averageProcessingTimeMs = 0.0,
    this.lastError,
    this.healthScore = 1.0,
  });

  SourceHealth copyWith({
    String? source,
    bool? enabled,
    SourceHealthStatus? status,
    DateTime? lastSuccessfulSync,
    DateTime? lastFailedSync,
    int? failureCount,
    double? averageProcessingTimeMs,
    String? lastError,
    double? healthScore,
  }) {
    return SourceHealth(
      source: source ?? this.source,
      enabled: enabled ?? this.enabled,
      status: status ?? this.status,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
      lastFailedSync: lastFailedSync ?? this.lastFailedSync,
      failureCount: failureCount ?? this.failureCount,
      averageProcessingTimeMs:
          averageProcessingTimeMs ?? this.averageProcessingTimeMs,
      lastError: lastError ?? this.lastError,
      healthScore: healthScore ?? this.healthScore,
    );
  }

  Map<String, dynamic> toJson() => {
        'source': source,
        'enabled': enabled,
        'status': status.name,
        'lastSuccessfulSync': lastSuccessfulSync?.toIso8601String(),
        'lastFailedSync': lastFailedSync?.toIso8601String(),
        'failureCount': failureCount,
        'averageProcessingTimeMs': averageProcessingTimeMs,
        'lastError': lastError,
        'healthScore': healthScore,
      };

  factory SourceHealth.fromJson(Map<String, dynamic> json) => SourceHealth(
        source: json['source'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
        status: SourceHealthStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SourceHealthStatus.unknown,
        ),
        lastSuccessfulSync: json['lastSuccessfulSync'] != null
            ? DateTime.tryParse(json['lastSuccessfulSync'] as String)
            : null,
        lastFailedSync: json['lastFailedSync'] != null
            ? DateTime.tryParse(json['lastFailedSync'] as String)
            : null,
        failureCount: (json['failureCount'] as num?)?.toInt() ?? 0,
        averageProcessingTimeMs:
            (json['averageProcessingTimeMs'] as num?)?.toDouble() ?? 0.0,
        lastError: json['lastError'] as String?,
        healthScore: (json['healthScore'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SourceHealth &&
        other.source == source &&
        other.enabled == enabled &&
        other.status == status &&
        other.healthScore == healthScore;
  }

  @override
  int get hashCode => Object.hash(source, enabled, status, healthScore);
}
