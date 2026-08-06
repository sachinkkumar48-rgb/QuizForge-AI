library;

import '../validation/pyq_ingestion_validator.dart';

class ImportReport {
  final String batchId;
  final int questionsExpected;
  final int questionsImported;
  final int questionsFailed;
  final int duplicatesCount;
  final int missingAnswersCount;
  final double coveragePercentage;
  final Duration processingTime;
  final List<IngestionValidationError> validationErrors;

  const ImportReport({
    required this.batchId,
    required this.questionsExpected,
    required this.questionsImported,
    required this.questionsFailed,
    required this.duplicatesCount,
    required this.missingAnswersCount,
    required this.coveragePercentage,
    required this.processingTime,
    required this.validationErrors,
  });

  Map<String, dynamic> toJson() => {
        'batchId': batchId,
        'questionsExpected': questionsExpected,
        'questionsImported': questionsImported,
        'questionsFailed': questionsFailed,
        'duplicatesCount': duplicatesCount,
        'missingAnswersCount': missingAnswersCount,
        'coveragePercentage': coveragePercentage,
        'processingTimeMs': processingTime.inMilliseconds,
        'errorCount': validationErrors.length,
      };
}
