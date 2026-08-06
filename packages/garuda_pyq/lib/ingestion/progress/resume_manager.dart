library;

class IngestionCheckpoint {
  final String batchId;
  final int lastProcessedQuestionNumber;
  final Set<String> importedQuestionIds;
  final DateTime timestamp;

  const IngestionCheckpoint({
    required this.batchId,
    required this.lastProcessedQuestionNumber,
    required this.importedQuestionIds,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'batchId': batchId,
        'lastProcessedQuestionNumber': lastProcessedQuestionNumber,
        'importedQuestionIds': importedQuestionIds.toList(),
        'timestamp': timestamp.toIso8601String(),
      };

  factory IngestionCheckpoint.fromJson(Map<String, dynamic> json) => IngestionCheckpoint(
        batchId: json['batchId'] as String,
        lastProcessedQuestionNumber: json['lastProcessedQuestionNumber'] as int,
        importedQuestionIds: Set<String>.from(json['importedQuestionIds'] ?? []),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class ResumeManager {
  final Map<String, IngestionCheckpoint> _checkpoints = {};

  void saveCheckpoint(IngestionCheckpoint checkpoint) {
    _checkpoints[checkpoint.batchId] = checkpoint;
  }

  IngestionCheckpoint? getCheckpoint(String batchId) => _checkpoints[batchId];

  void clearCheckpoint(String batchId) {
    _checkpoints.remove(batchId);
  }
}
