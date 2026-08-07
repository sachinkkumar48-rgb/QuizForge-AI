library;

import 'package:garuda_editor/garuda_editor.dart';
import '../domain/entities/current_affairs_knowledge_object.dart';

class ValidationIssue {
  final String field;
  final String message;
  final bool isBlocking;

  const ValidationIssue({
    required this.field,
    required this.message,
    this.isBlocking = true,
  });
}

class ValidationReport {
  final bool isValid;
  final List<ValidationIssue> issues;

  const ValidationReport({
    required this.isValid,
    required this.issues,
  });
}

class CurrentAffairsValidator {
  static ValidationReport validate(
    CurrentAffairsKnowledgeObject object, {
    List<CurrentAffairsKnowledgeObject> existingObjects = const [],
  }) {
    final issues = <ValidationIssue>[];

    // 1. Missing official source
    if (object.officialSource.trim().isEmpty) {
      issues.add(const ValidationIssue(
        field: 'officialSource',
        message: 'Validation Failed: Official government source citation is required.',
      ));
    }

    // 2. Missing evidence
    if (object.evidenceIds.isEmpty) {
      issues.add(const ValidationIssue(
        field: 'evidenceIds',
        message: 'Validation Failed: Evidence attachment is missing.',
      ));
    }

    // 3. Structural fields
    if (object.headline.trim().isEmpty) {
      issues.add(const ValidationIssue(
        field: 'headline',
        message: 'Validation Failed: Headline cannot be empty.',
      ));
    }

    if (object.summary.trim().isEmpty) {
      issues.add(const ValidationIssue(
        field: 'summary',
        message: 'Validation Failed: Summary cannot be empty.',
      ));
    }

    // 4. Duplicate event check
    for (final exist in existingObjects) {
      if (exist.id != object.id &&
          exist.headline.toLowerCase().trim() == object.headline.toLowerCase().trim() &&
          exist.publicationDate.year == object.publicationDate.year &&
          exist.publicationDate.month == object.publicationDate.month) {
        issues.add(ValidationIssue(
          field: 'duplicate',
          message: 'Validation Failed: Duplicate event detected with matching headline ("${exist.headline}").',
        ));

        break;
      }
    }

    // 5. Editorial approval check for publication
    if (object.editorialStatus == EditorialStatus.published &&
        object.editorialStatus != EditorialStatus.approved &&
        object.editorialStatus != EditorialStatus.seniorEditorialReview) {
      issues.add(const ValidationIssue(
        field: 'editorialStatus',
        message: 'Validation Failed: Cannot publish without editorial approval.',
      ));
    }

    return ValidationReport(
      isValid: issues.every((i) => !i.isBlocking),
      issues: issues,
    );
  }
}
