library;

import 'package:meta/meta.dart';
import '../repositories/case_repository.dart';

@immutable
class CaseValidationError {
  final String code;
  final String message;
  final String caseId;

  const CaseValidationError({
    required this.code,
    required this.message,
    required this.caseId,
  });

  @override
  String toString() => '[$code] ($caseId): $message';
}

@immutable
class CaseValidationResult {
  final bool isValid;
  final List<CaseValidationError> errors;

  const CaseValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  factory CaseValidationResult.success() =>
      const CaseValidationResult(isValid: true);

  factory CaseValidationResult.failure(List<CaseValidationError> errors) =>
      CaseValidationResult(isValid: false, errors: errors);
}

/// Comprehensive Validation Engine for Case Law Knowledge Objects.
class CaseValidator {
  static Future<CaseValidationResult> validateRepository(
      CaseRepository repository) async {
    final errors = <CaseValidationError>[];
    final cases = await repository.getCases();

    final seenIds = <String>{};
    final seenCitations = <String>{};

    for (final c in cases) {
      // 1. Unique Object ID check
      if (c.objectId.trim().isEmpty) {
        errors.add(CaseValidationError(
          code: 'EMPTY_CASE_ID',
          message: 'Case object ID cannot be empty.',
          caseId: c.objectId,
        ));
      } else if (seenIds.contains(c.objectId)) {
        errors.add(CaseValidationError(
          code: 'DUPLICATE_CASE_ID',
          message: 'Duplicate Case objectId "${c.objectId}" detected.',
          caseId: c.objectId,
        ));
      } else {
        seenIds.add(c.objectId);
      }

      // 2. Duplicate Citation Check
      final cleanCitation = c.citation.trim().toUpperCase();
      if (cleanCitation.isNotEmpty) {
        if (seenCitations.contains(cleanCitation)) {
          errors.add(CaseValidationError(
            code: 'DUPLICATE_CITATION',
            message: 'Duplicate citation "${c.citation}" detected.',
            caseId: c.objectId,
          ));
        } else {
          seenCitations.add(cleanCitation);
        }
      } else {
        errors.add(CaseValidationError(
          code: 'MISSING_CITATION',
          message: 'Case citation cannot be empty.',
          caseId: c.objectId,
        ));
      }

      // 3. Metadata Completeness Check
      if (c.caseName.trim().isEmpty) {
        errors.add(CaseValidationError(
          code: 'MISSING_CASE_NAME',
          message: 'Case name cannot be empty.',
          caseId: c.objectId,
        ));
      }

      if (c.ratioDecidendi.isEmpty && c.oneLineSummary.trim().isEmpty) {
        errors.add(CaseValidationError(
          code: 'MISSING_RATIO_OR_SUMMARY',
          message: 'Case must contain ratio decidendi or one-line summary.',
          caseId: c.objectId,
        ));
      }

      // 4. Evidence References for Approved Cases
      if (c.editorialStatus == 'APPROVED' &&
          c.evidenceReferences.isEmpty &&
          c.citations.isEmpty &&
          c.primarySource.trim().isEmpty) {
        errors.add(CaseValidationError(
          code: 'MISSING_EVIDENCE',
          message: 'Approved Case Knowledge Object must contain citations or evidence references.',
          caseId: c.objectId,
        ));
      }
    }

    if (errors.isNotEmpty) {
      return CaseValidationResult.failure(errors);
    }

    return CaseValidationResult.success();
  }
}
