import 'package:meta/meta.dart';

/// Immutable model tracking metrics and statistics for an ingestion run.
@immutable
class KnowledgeImportStatistics {
  final int totalProcessed;
  final int objectsCreated;
  final int objectsUpdated;
  final int duplicates;
  final int failures;
  final int warnings;
  final int skippedRecords;
  final double processingTimeMs;

  const KnowledgeImportStatistics({
    this.totalProcessed = 0,
    this.objectsCreated = 0,
    this.objectsUpdated = 0,
    this.duplicates = 0,
    this.failures = 0,
    this.warnings = 0,
    this.skippedRecords = 0,
    this.processingTimeMs = 0.0,
  });

  KnowledgeImportStatistics copyWith({
    int? totalProcessed,
    int? objectsCreated,
    int? objectsUpdated,
    int? duplicates,
    int? failures,
    int? warnings,
    int? skippedRecords,
    double? processingTimeMs,
  }) {
    return KnowledgeImportStatistics(
      totalProcessed: totalProcessed ?? this.totalProcessed,
      objectsCreated: objectsCreated ?? this.objectsCreated,
      objectsUpdated: objectsUpdated ?? this.objectsUpdated,
      duplicates: duplicates ?? this.duplicates,
      failures: failures ?? this.failures,
      warnings: warnings ?? this.warnings,
      skippedRecords: skippedRecords ?? this.skippedRecords,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalProcessed': totalProcessed,
        'objectsCreated': objectsCreated,
        'objectsUpdated': objectsUpdated,
        'duplicates': duplicates,
        'failures': failures,
        'warnings': warnings,
        'skippedRecords': skippedRecords,
        'processingTimeMs': processingTimeMs,
      };

  factory KnowledgeImportStatistics.fromJson(Map<String, dynamic> json) {
    return KnowledgeImportStatistics(
      totalProcessed: json['totalProcessed'] as int? ?? 0,
      objectsCreated: json['objectsCreated'] as int? ?? 0,
      objectsUpdated: json['objectsUpdated'] as int? ?? 0,
      duplicates: json['duplicates'] as int? ?? 0,
      failures: json['failures'] as int? ?? 0,
      warnings: json['warnings'] as int? ?? 0,
      skippedRecords: json['skippedRecords'] as int? ?? 0,
      processingTimeMs: (json['processingTimeMs'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
