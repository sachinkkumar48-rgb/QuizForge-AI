import 'network_exception.dart';

/// Contract for defining request retry logic in Project TITAN.
abstract class RetryPolicy {
  /// Evaluates whether a failed request should be retried based on [exception] and [attemptCount].
  bool shouldRetry(NetworkException exception, int attemptCount);
}

/// Default no-retry implementation of [RetryPolicy].
class NoRetryPolicy implements RetryPolicy {
  const NoRetryPolicy();

  @override
  bool shouldRetry(NetworkException exception, int attemptCount) => false;
}
