import 'dart:async';
import 'package:flutter/widgets.dart';

/// Phase execution result metric for startup optimization.
class StartupPhaseMetric {
  final String phaseName;
  final Duration duration;
  final bool success;

  StartupPhaseMetric({
    required this.phaseName,
    required this.duration,
    required this.success,
  });
}

/// Startup Optimizer for managing non-blocking, deferred, and phased application bootstrap.
class StartupOptimizer {
  final List<StartupPhaseMetric> _metrics = [];
  final Stopwatch _stopwatch = Stopwatch();

  StartupOptimizer();

  /// Total startup time elapsed.
  Duration get totalStartupDuration => _stopwatch.elapsed;

  /// Returns unmodifiable list of startup metrics per phase.
  List<StartupPhaseMetric> get metrics => List.unmodifiable(_metrics);

  /// Begins measuring startup initialization.
  void start() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  /// Runs a critical startup phase synchronously/asynchronously and records metrics.
  Future<T> runPhase<T>(String phaseName, FutureOr<T> Function() action) async {
    final phaseWatch = Stopwatch()..start();
    bool success = false;
    try {
      final result = await action();
      success = true;
      return result;
    } finally {
      phaseWatch.stop();
      _metrics.add(StartupPhaseMetric(
        phaseName: phaseName,
        duration: phaseWatch.elapsed,
        success: success,
      ));
    }
  }

  /// Defers non-critical initialization task after frame rendering.
  void deferTask(VoidCallback task) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduleMicrotask(task);
    });
  }

  /// Stops startup tracking stopwatch.
  void stop() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
    }
  }
}
