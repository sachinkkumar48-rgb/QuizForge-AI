import 'package:test/test.dart';
import 'package:titan_ai/titan_ai.dart';

void main() {
  group('TelemetryCollector Tests', () {
    late TelemetryCollector collector;

    setUp(() {
      collector = TelemetryCollector();
    });

    test('records telemetry entries and computes aggregate summary', () {
      collector.record(AITelemetryRecord(
        requestId: 'req_1',
        providerName: 'gemini',
        modelId: 'gemini-1.5-flash',
        latency: const Duration(milliseconds: 200),
        promptTokens: 10,
        completionTokens: 20,
        totalTokens: 30,
        retryAttempts: 0,
        isSuccess: true,
        timestamp: DateTime.now(),
      ));

      collector.record(AITelemetryRecord(
        requestId: 'req_2',
        providerName: 'gemini',
        modelId: 'gemini-1.5-flash',
        latency: const Duration(milliseconds: 400),
        promptTokens: 15,
        completionTokens: 25,
        totalTokens: 40,
        retryAttempts: 1,
        isSuccess: false,
        errorCode: 'NetworkException',
        timestamp: DateTime.now(),
      ));

      final summary = collector.computeSummary();
      expect(summary.totalRequests, equals(2));
      expect(summary.successfulRequests, equals(1));
      expect(summary.failedRequests, equals(1));
      expect(summary.successRate, equals(50.0));
      expect(summary.averageLatencyMs, equals(300.0));
      expect(summary.totalTokensConsumed, equals(70));
      expect(summary.totalRetries, equals(1));
      expect(summary.requestsPerProvider['gemini'], equals(2));
    });

    test('clears recorded telemetry history', () {
      collector.record(AITelemetryRecord(
        requestId: 'req_1',
        providerName: 'mock',
        modelId: 'mock',
        latency: const Duration(milliseconds: 100),
        promptTokens: 5,
        completionTokens: 5,
        totalTokens: 10,
        retryAttempts: 0,
        isSuccess: true,
        timestamp: DateTime.now(),
      ));

      collector.clear();
      expect(collector.records.isEmpty, isTrue);
      expect(collector.computeSummary().totalRequests, equals(0));
    });
  });
}
