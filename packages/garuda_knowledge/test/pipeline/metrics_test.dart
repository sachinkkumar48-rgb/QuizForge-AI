import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('KnowledgePipelineMetrics', () {
    test('Accurately tracks registration success/failure rates and latency', () {
      final metrics = KnowledgePipelineMetrics();

      metrics.recordSuccess(10.0);
      metrics.recordSuccess(20.0);
      metrics.recordFailure(30.0, isValidation: true);

      expect(metrics.registrationCount, equals(3));
      expect(metrics.successCount, equals(2));
      expect(metrics.failureCount, equals(1));
      expect(metrics.validationFailureCount, equals(1));
      expect(metrics.averageProcessingTimeMs, equals(20.0));
      expect(metrics.successRate, closeTo(66.66, 0.1));
    });
  });
}
