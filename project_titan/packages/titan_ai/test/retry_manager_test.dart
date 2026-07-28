import 'package:test/test.dart';
import 'package:titan_ai/titan_ai.dart';

void main() {
  group('RetryManager Tests', () {
    late RetryManager manager;

    setUp(() {
      manager = RetryManager(
        maxRetries: 2,
        initialDelay: const Duration(milliseconds: 10),
        enableJitter: false,
      );
    });

    test('classifies retryable errors correctly', () {
      expect(manager.isRetryable(const AINetworkException('Network drop')),
          isTrue);
      expect(manager.isRetryable(const AIResponseException('Rate limit', 429)),
          isTrue);
      expect(
          manager.isRetryable(const AIResponseException('Server error', 503)),
          isTrue);
      expect(manager.isRetryable(const AIResponseException('Bad request', 400)),
          isFalse);
    });

    test('retries transient failures up to maxRetries', () async {
      int attempts = 0;
      final result = await manager.execute((attempt) async {
        attempts = attempt;
        if (attempt < 2) {
          throw const AINetworkException('Temporary drop');
        }
        return 'success';
      });

      expect(result, equals('success'));
      expect(attempts, equals(2));
    });

    test('rethrows non-retryable error immediately', () async {
      int attempts = 0;
      expect(
        () => manager.execute((attempt) async {
          attempts = attempt;
          throw const AIResponseException('Unauthorized', 401);
        }),
        throwsA(isA<AIResponseException>()),
      );
      expect(attempts, equals(1));
    });
  });
}
