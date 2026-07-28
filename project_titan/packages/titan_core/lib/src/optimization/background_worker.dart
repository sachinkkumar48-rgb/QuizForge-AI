import 'dart:async';
import 'package:flutter/foundation.dart';

/// Background Worker abstraction for executing compute-heavy tasks off the UI thread via compute isolate or async batching.
class BackgroundWorker {
  BackgroundWorker();

  /// Executes [computation] function on an isolate pool (or fallback async task).
  static Future<R> run<Q, R>(
      ComputeCallback<Q, R> computation, Q message) async {
    return await compute(computation, message);
  }

  /// Batches a list of tasks into microtasks to prevent main UI thread blocking.
  static Future<List<R>> processBatch<T, R>({
    required List<T> items,
    required R Function(T item) worker,
    int chunkSize = 50,
  }) async {
    final List<R> results = [];
    for (var i = 0; i < items.length; i += chunkSize) {
      final chunk = items.sublist(
        i,
        (i + chunkSize > items.length) ? items.length : i + chunkSize,
      );
      for (final item in chunk) {
        results.add(worker(item));
      }
      // Yield to event loop to allow UI frames to render
      await Future<void>.delayed(Duration.zero);
    }
    return results;
  }
}
