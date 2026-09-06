/// Checkpoint Frequency Policy Domain Entity (TITAN-KO-040.0 P40).
///
/// Injectable policy abstraction governing when session checkpoints should be
/// created and persisted during adaptive learning execution.
library;

import 'package:meta/meta.dart';

/// Strategy mode for checkpoint creation frequency.
enum CheckpointStrategy {
  /// Checkpoint after every successfully consolidated attempt.
  everyAttempt,

  /// Checkpoint periodically every N consolidated attempts.
  everyNAttempts,

  /// Checkpoint only upon explicit pause, background, or completion.
  onPauseOrComplete,

  /// Checkpoint only on explicit programmatic request.
  manualOnly;
}

/// Injectable policy governing session checkpointing frequency and triggers.
@immutable
class CheckpointPolicy {
  /// The active checkpointing strategy.
  final CheckpointStrategy strategy;

  /// Number of attempts between checkpoints when using [CheckpointStrategy.everyNAttempts].
  final int intervalN;

  const CheckpointPolicy._({
    required this.strategy,
    this.intervalN = 1,
  });

  /// Checkpoint after every single consolidated attempt (highest durability).
  const factory CheckpointPolicy.everyAttempt() = _EveryAttemptPolicy;

  /// Checkpoint periodically every [n] attempts (must be >= 1).
  factory CheckpointPolicy.everyNAttempts(int n) {
    if (n < 1) {
      throw ArgumentError('intervalN must be >= 1 (got $n)');
    }
    return CheckpointPolicy._(
      strategy: CheckpointStrategy.everyNAttempts,
      intervalN: n,
    );
  }

  /// Checkpoint only on pause, backgrounding, or session completion.
  const factory CheckpointPolicy.onPauseOrComplete() = _OnPauseOrCompletePolicy;

  /// Checkpoint only on explicit caller request.
  const factory CheckpointPolicy.manual() = _ManualPolicy;

  /// Evaluates whether a checkpoint should be captured given the current trigger context.
  bool shouldCheckpoint({
    required int attemptCount,
    bool isPaused = false,
    bool isCompleted = false,
    bool isExplicit = false,
  }) {
    if (isExplicit || isCompleted || isPaused) {
      return true;
    }

    return switch (strategy) {
      CheckpointStrategy.everyAttempt => attemptCount > 0,
      CheckpointStrategy.everyNAttempts =>
        attemptCount > 0 && (attemptCount % intervalN == 0),
      CheckpointStrategy.onPauseOrComplete => false,
      CheckpointStrategy.manualOnly => false,
    };
  }

  Map<String, dynamic> toJson() => {
        'strategy': strategy.name,
        'intervalN': intervalN,
      };

  factory CheckpointPolicy.fromJson(Map<String, dynamic> json) {
    final stratStr = json['strategy'] as String? ?? 'everyAttempt';
    final interval = json['intervalN'] as int? ?? 1;

    final strategy = CheckpointStrategy.values.firstWhere(
      (s) => s.name == stratStr,
      orElse: () => CheckpointStrategy.everyAttempt,
    );

    return switch (strategy) {
      CheckpointStrategy.everyAttempt => const CheckpointPolicy.everyAttempt(),
      CheckpointStrategy.everyNAttempts =>
        CheckpointPolicy.everyNAttempts(interval),
      CheckpointStrategy.onPauseOrComplete =>
        const CheckpointPolicy.onPauseOrComplete(),
      CheckpointStrategy.manualOnly => const CheckpointPolicy.manual(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckpointPolicy &&
          runtimeType == other.runtimeType &&
          strategy == other.strategy &&
          intervalN == other.intervalN;

  @override
  int get hashCode => Object.hash(strategy, intervalN);

  @override
  String toString() =>
      'CheckpointPolicy(${strategy.name}${strategy == CheckpointStrategy.everyNAttempts ? " [$intervalN]" : ""})';
}

class _EveryAttemptPolicy extends CheckpointPolicy {
  const _EveryAttemptPolicy()
      : super._(
          strategy: CheckpointStrategy.everyAttempt,
          intervalN: 1,
        );
}

class _OnPauseOrCompletePolicy extends CheckpointPolicy {
  const _OnPauseOrCompletePolicy()
      : super._(
          strategy: CheckpointStrategy.onPauseOrComplete,
          intervalN: 1,
        );
}

class _ManualPolicy extends CheckpointPolicy {
  const _ManualPolicy()
      : super._(
          strategy: CheckpointStrategy.manualOnly,
          intervalN: 1,
        );
}
