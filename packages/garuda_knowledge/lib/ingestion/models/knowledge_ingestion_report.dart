import 'package:meta/meta.dart';
import 'knowledge_import_result.dart';
import 'knowledge_import_session.dart';
import 'knowledge_import_statistics.dart';

/// Comprehensive report generated at the end of an ingestion run.
@immutable
class KnowledgeIngestionReport {
  final KnowledgeImportSession session;
  final KnowledgeImportStatistics statistics;
  final List<KnowledgeImportResult> documentResults;
  final List<String> errorLogs;
  final DateTime completedTime;

  const KnowledgeIngestionReport({
    required this.session,
    required this.statistics,
    required this.documentResults,
    required this.errorLogs,
    required this.completedTime,
  });

  factory KnowledgeIngestionReport.generate({
    required KnowledgeImportSession session,
    required List<KnowledgeImportResult> results,
    required double totalDurationMs,
  }) {
    int created = 0;
    int updated = 0;
    int duplicates = 0;
    int failures = 0;
    int warningsCount = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final res in results) {
      warningsCount += res.warnings.length;
      switch (res.status) {
        case ImportStatus.success:
          created++;
          break;
        case ImportStatus.updated:
          updated++;
          break;
        case ImportStatus.duplicate:
          duplicates++;
          break;
        case ImportStatus.skipped:
          skipped++;
          break;
        case ImportStatus.failed:
          failures++;
          if (res.message != null) {
            errors.add('[Doc: ${res.documentId}] ${res.message}');
          }
          break;
      }
    }

    final stats = KnowledgeImportStatistics(
      totalProcessed: results.length,
      objectsCreated: created,
      objectsUpdated: updated,
      duplicates: duplicates,
      failures: failures,
      warnings: warningsCount,
      skippedRecords: skipped,
      processingTimeMs: totalDurationMs,
    );

    return KnowledgeIngestionReport(
      session: session,
      statistics: stats,
      documentResults: results,
      errorLogs: errors,
      completedTime: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': session.sessionId,
        'startTime': session.startTime.toIso8601String(),
        'completedTime': completedTime.toIso8601String(),
        'statistics': statistics.toJson(),
        'errorCount': errorLogs.length,
        'errors': errorLogs,
      };
}
