/// Utility functions for session identifier generation and formatting.
abstract final class QuizSessionUtils {
  static int _counter = 0;

  /// Generates a unique session identifier.
  static String generateSessionId() {
    _counter++;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'session_${timestamp}_$_counter';
  }

  /// Formats a [Duration] into HH:MM:SS or MM:SS string representation.
  static String formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }
}
