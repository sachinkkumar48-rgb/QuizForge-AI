library;

import 'package:garuda_editor/garuda_editor.dart';

import '../domain/entities/index_knowledge_object.dart';
import '../domain/entities/indicator_knowledge_object.dart';
import '../domain/entities/report_knowledge_object.dart';
import '../domain/entities/survey_knowledge_object.dart';

class ReportValidationIssue {
  final String field;
  final String message;
  final bool isBlocking;

  const ReportValidationIssue({
    required this.field,
    required this.message,
    this.isBlocking = true,
  });
}

class ReportValidationReport {
  final bool isValid;
  final List<ReportValidationIssue> issues;

  const ReportValidationReport({
    required this.isValid,
    required this.issues,
  });
}

/// Validates a Report Knowledge Object for publication-readiness:
/// duplicate detection, broken references, missing evidence, missing official URL,
/// missing metadata and invalid relationships.
class ReportValidator {
  static ReportValidationReport validate(
    ReportKnowledgeObject object, {
    List<ReportKnowledgeObject> existingReports = const [],
    List<IndexKnowledgeObject> knownIndices = const [],
    List<SurveyKnowledgeObject> knownSurveys = const [],
    List<IndicatorKnowledgeObject> knownIndicators = const [],
  }) {
    final issues = <ReportValidationIssue>[];

    // 1. Mandatory metadata
    if (object.officialTitle.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'officialTitle',
        message: 'Validation Failed: Official Title cannot be empty.',
      ));
    }

    if (object.publishingOrganisation.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'publishingOrganisation',
        message: 'Validation Failed: Publishing Organisation is required.',
      ));
    }

    if (object.publicationYear <= 0) {
      issues.add(const ReportValidationIssue(
        field: 'publicationYear',
        message: 'Validation Failed: Publication Year is required.',
      ));
    }

    // 2. Missing official URL
    if (object.officialUrl.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'officialUrl',
        message:
            'Validation Failed: Missing official URL - every report requires an official source URL.',
      ));
    }

    // 3. Evidence attachment
    if (object.evidenceIds.isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'evidenceIds',
        message: 'Validation Failed: Evidence attachment is missing.',
      ));
    }

    // 4. Duplicate detection
    for (final exist in existingReports) {
      if (exist.id != object.id &&
          exist.officialTitle.toLowerCase().trim() ==
              object.officialTitle.toLowerCase().trim() &&
          exist.publicationYear == object.publicationYear) {
        issues.add(ReportValidationIssue(
          field: 'duplicate',
          message:
              'Validation Failed: Duplicate report detected with matching title ("${exist.officialTitle}") and year (${exist.publicationYear}).',
        ));
        break;
      }
    }

    // 5. Broken references - related indices
    if (knownIndices.isNotEmpty) {
      final knownIndexIds = knownIndices.map((i) => i.id).toSet();
      for (final ref in object.relatedIndexIds) {
        if (!knownIndexIds.contains(ref)) {
          issues.add(ReportValidationIssue(
            field: 'relatedIndexIds',
            message:
                'Validation Failed: Broken reference - Index "$ref" not found in the library.',
            isBlocking: false,
          ));
        }
      }
    }

    // 6. Invalid relationships
    for (final rel in object.relationships) {
      final sourceExists = existingReports.any((r) => r.id == rel.sourceId) ||
          knownIndices.any((i) => i.id == rel.sourceId) ||
          knownSurveys.any((s) => s.id == rel.sourceId);
      final targetExists = existingReports.any((r) => r.id == rel.targetId) ||
          knownIndices.any((i) => i.id == rel.targetId) ||
          knownSurveys.any((s) => s.id == rel.targetId);
      if (rel.sourceId.isNotEmpty && !sourceExists) {
        issues.add(ReportValidationIssue(
          field: 'relationships',
          message:
              'Validation Failed: Relationship source "${rel.sourceId}" does not exist.',
          isBlocking: false,
        ));
      }
      if (rel.targetId.isNotEmpty && !targetExists) {
        issues.add(ReportValidationIssue(
          field: 'relationships',
          message:
              'Validation Failed: Relationship target "${rel.targetId}" does not exist.',
          isBlocking: false,
        ));
      }
    }

    // 7. Editorial approval check for publication
    if (object.editorialStatus == EditorialStatus.published &&
        object.editorialStatus != EditorialStatus.approved &&
        object.editorialStatus != EditorialStatus.seniorEditorialReview) {
      issues.add(const ReportValidationIssue(
        field: 'editorialStatus',
        message:
            'Validation Failed: Cannot publish without editorial approval.',
      ));
    }

    return ReportValidationReport(
      isValid: issues.every((i) => !i.isBlocking),
      issues: issues,
    );
  }
}
