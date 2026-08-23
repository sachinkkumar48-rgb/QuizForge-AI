import '../exceptions/quiz_generation_exception.dart';

/// Cancellation token to abort in-flight smart assessment generation workflows cleanly.
class AssessmentCancellationToken {
  bool _isCancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final listener in _listeners) {
      listener();
    }
    _listeners.clear();
  }

  void onCancel(void Function() listener) {
    if (_isCancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }

  /// Throws [AssessmentCancellationException] if cancellation has been triggered.
  void throwIfCancelled() {
    if (_isCancelled) {
      throw const AssessmentCancellationException(
          'Assessment generation was cancelled by user.');
    }
  }
}
