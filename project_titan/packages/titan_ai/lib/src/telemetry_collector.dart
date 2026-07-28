import 'package:meta/meta.dart';

/// Single telemetry entry representing a completed or failed AI request execution.
@immutable
class AITelemetryRecord {
  final String requestId;
  final String providerName;
  final String modelId;
  final Duration latency;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final int retryAttempts;
  final bool isSuccess;
  final String? errorCode;
  final DateTime timestamp;

  const AITelemetryRecord({
    required this.requestId,
    required this.providerName,
    required this.modelId,
    required this.latency,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.retryAttempts,
    required this.isSuccess,
    this.errorCode,
    required this.timestamp,
  });
}

/// Consolidated telemetry metrics summary.
@immutable
class AITelemetrySummary {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final double successRate;
  final double averageLatencyMs;
  final int totalTokensConsumed;
  final int totalRetries;
  final Map<String, int> requestsPerProvider;

  const AITelemetrySummary({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.successRate,
    required this.averageLatencyMs,
    required this.totalTokensConsumed,
    required this.totalRetries,
    required this.requestsPerProvider,
  });

  @override
  String toString() =>
      'AITelemetrySummary(total: $totalRequests, successRate: ${successRate.toStringAsFixed(1)}%, avgLatency: ${averageLatencyMs.toStringAsFixed(1)}ms, totalTokens: $totalTokensConsumed)';
}

/// Pure Dart telemetry collector recording performance, latency, tokens,
/// retries, and failure rates for Project TITAN.
class TelemetryCollector {
  final List<AITelemetryRecord> _records = [];
  final int maxHistory;

  TelemetryCollector({this.maxHistory = 500});

  /// Records an AI execution telemetry event.
  void record(AITelemetryRecord record) {
    _records.add(record);
    if (_records.length > maxHistory) {
      _records.removeAt(0);
    }
  }

  /// Returns unmodifiable list of collected records.
  List<AITelemetryRecord> get records => List.unmodifiable(_records);

  /// Computes summary metrics across collected telemetry history.
  AITelemetrySummary computeSummary() {
    if (_records.isEmpty) {
      return const AITelemetrySummary(
        totalRequests: 0,
        successfulRequests: 0,
        failedRequests: 0,
        successRate: 0.0,
        averageLatencyMs: 0.0,
        totalTokensConsumed: 0,
        totalRetries: 0,
        requestsPerProvider: {},
      );
    }

    int total = _records.length;
    int successCount = 0;
    int totalLatencyMs = 0;
    int totalTokens = 0;
    int totalRetries = 0;
    final providerCounts = <String, int>{};

    for (final r in _records) {
      if (r.isSuccess) successCount++;
      totalLatencyMs += r.latency.inMilliseconds;
      totalTokens += r.totalTokens;
      totalRetries += r.retryAttempts;
      providerCounts[r.providerName] =
          (providerCounts[r.providerName] ?? 0) + 1;
    }

    int failedCount = total - successCount;
    double successRate = (successCount / total) * 100.0;
    double avgLatency = totalLatencyMs / total;

    return AITelemetrySummary(
      totalRequests: total,
      successfulRequests: successCount,
      failedRequests: failedCount,
      successRate: successRate,
      averageLatencyMs: avgLatency,
      totalTokensConsumed: totalTokens,
      totalRetries: totalRetries,
      requestsPerProvider: Map.unmodifiable(providerCounts),
    );
  }

  /// Clears telemetry history.
  void clear() {
    _records.clear();
  }
}
