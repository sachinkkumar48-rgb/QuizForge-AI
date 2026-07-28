import 'dart:async';
import 'dart:math';

import 'ai_exception.dart';

/// Configurable retry manager performing exponential backoff with jitter
/// for transient AI service and network failures.
class RetryManager {
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffFactor;
  final bool enableJitter;
  final Random _random = Random();

  RetryManager({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    this.backoffFactor = 2.0,
    this.enableJitter = true,
  });

  /// Determines if an exception is transient and eligible for retry.
  bool isRetryable(Object error) {
    if (error is AIResponseException) {
      final code = error.statusCode;
      if (code == 429) {
        return true; // Rate limited
      }
      if (code != null && code >= 500 && code < 600) {
        return true; // Server error
      }
      return false;
    }
    if (error is AINetworkException || error is TimeoutException) {
      return true;
    }
    final str = error.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('connection refused') ||
        str.contains('network error') ||
        str.contains('timeout');
  }

  /// Calculates delay duration for attempt number [attempt] (1-indexed).
  Duration calculateDelay(int attempt) {
    if (attempt <= 0) return initialDelay;
    double delayMs = initialDelay.inMilliseconds.toDouble() *
        pow(backoffFactor, attempt - 1);
    if (delayMs > maxDelay.inMilliseconds) {
      delayMs = maxDelay.inMilliseconds.toDouble();
    }

    if (enableJitter) {
      final jitterFraction = _random.nextDouble() * 0.3; // ±30% jitter
      delayMs = delayMs * (0.85 + jitterFraction);
    }

    return Duration(milliseconds: delayMs.round());
  }

  /// Executes [action] retrying up to [maxRetries] times when retryable errors occur.
  Future<T> execute<T>(Future<T> Function(int attempt) action) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await action(attempt);
      } catch (e) {
        if (attempt > maxRetries || !isRetryable(e)) {
          rethrow;
        }
        final delay = calculateDelay(attempt);
        await Future<void>.delayed(delay);
      }
    }
  }
}
