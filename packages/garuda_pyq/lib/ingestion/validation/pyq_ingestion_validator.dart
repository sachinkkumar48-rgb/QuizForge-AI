library;

import '../../models/question_model.dart';
import '../answer_keys/official_answer_key_merger.dart';
import '../pdf/official_paper_loader.dart';

enum IngestionValidationErrorType {
  corruptedDocument,
  checksumMismatch,
  missingMetadata,
  invalidNumbering,
  brokenOptions,
  missingAnswer,
  duplicateQuestion,
}

class IngestionValidationError {
  final int? questionNumber;
  final IngestionValidationErrorType errorType;
  final String message;

  const IngestionValidationError({
    this.questionNumber,
    required this.errorType,
    required this.message,
  });
}

class PYQIngestionValidator {
  /// Validates raw PaperDocumentBuffer.
  static List<IngestionValidationError> validateDocument(PaperDocumentBuffer document) {
    final errors = <IngestionValidationError>[];

    if (document.rawBytes.isEmpty || document.rawText.trim().isEmpty) {
      errors.add(const IngestionValidationError(
        errorType: IngestionValidationErrorType.corruptedDocument,
        message: 'Document buffer is corrupted or empty.',
      ));
    }

    return errors;
  }

  /// Validates MergedQuestionResult before final Question Knowledge Object creation.
  static List<IngestionValidationError> validateMergedResult(
    MergedQuestionResult result, {
    List<Question> existingRepositoryQuestions = const [],
  }) {
    final errors = <IngestionValidationError>[];
    final draft = result.draft;

    if (draft.questionNumber <= 0) {
      errors.add(IngestionValidationError(
        questionNumber: draft.questionNumber,
        errorType: IngestionValidationErrorType.invalidNumbering,
        message: 'Question number must be greater than zero.',
      ));
    }

    if (draft.originalQuestion.trim().isEmpty || draft.originalQuestion.length < 5) {
      errors.add(IngestionValidationError(
        questionNumber: draft.questionNumber,
        errorType: IngestionValidationErrorType.missingMetadata,
        message: 'Question text is missing or invalid.',
      ));
    }

    if (result.options.isEmpty || result.options.length < 2) {
      errors.add(IngestionValidationError(
        questionNumber: draft.questionNumber,
        errorType: IngestionValidationErrorType.brokenOptions,
        message: 'Question must have at least 2 options.',
      ));
    }

    if (!result.isAnswerVerified || result.answer.correctOptionKeys.isEmpty) {
      errors.add(IngestionValidationError(
        questionNumber: draft.questionNumber,
        errorType: IngestionValidationErrorType.missingAnswer,
        message: 'Official answer key is missing or unverified.',
      ));
    }

    // Duplicate detection check
    final isDup = existingRepositoryQuestions.any((existing) =>
        existing.year == draft.metadata.year &&
        existing.examId.toLowerCase() == draft.metadata.examId.toLowerCase() &&
        (existing.questionNumber == draft.questionNumber ||
            existing.originalQuestion.toLowerCase().trim() == draft.originalQuestion.toLowerCase().trim()));

    if (isDup) {
      errors.add(IngestionValidationError(
        questionNumber: draft.questionNumber,
        errorType: IngestionValidationErrorType.duplicateQuestion,
        message: 'Duplicate question detected for ${draft.metadata.examId} ${draft.metadata.year} Q${draft.questionNumber}.',
      ));
    }

    return errors;
  }
}
