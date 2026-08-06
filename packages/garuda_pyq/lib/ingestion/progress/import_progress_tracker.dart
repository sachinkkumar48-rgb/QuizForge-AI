library;

class ImportProgressTracker {
  final int totalExpected;
  int _processed = 0;
  int _succeeded = 0;
  int _failed = 0;
  int _duplicates = 0;
  final DateTime _startTime = DateTime.now();

  ImportProgressTracker({required this.totalExpected});

  int get processed => _processed;
  int get succeeded => _succeeded;
  int get failed => _failed;
  int get duplicates => _duplicates;

  double get progressPercentage => totalExpected > 0 ? (_processed / totalExpected) * 100.0 : 0.0;
  double get importSpeedPerSec {
    final elapsedSec = DateTime.now().difference(_startTime).inMilliseconds / 1000.0;
    return elapsedSec > 0 ? _processed / elapsedSec : 0.0;
  }

  void recordSuccess() {
    _processed++;
    _succeeded++;
  }

  void recordFailure() {
    _processed++;
    _failed++;
  }

  void recordDuplicate() {
    _processed++;
    _duplicates++;
  }
}
