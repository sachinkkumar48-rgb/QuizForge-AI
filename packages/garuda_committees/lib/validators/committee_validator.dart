library;

import 'package:garuda_editor/garuda_editor.dart';
import '../domain/entities/committee_knowledge_object.dart';

class CommitteeValidationIssue {
  final String field;
  final String message;
  final bool isBlocking;

  const CommitteeValidationIssue({
    required this.field,
    required this.message,
    this.isBlocking = true,
  });
}

class CommitteeValidationReport {
  final bool isValid;
  final List<CommitteeValidationIssue> issues;

  const CommitteeValidationReport({
    required this.isValid,
    required this.issues,
  });
}

class CommitteeValidator {
  static CommitteeValidationReport validate(
    CommitteeKnowledgeObject object, {
    List<CommitteeKnowledgeObject> existingCommittees = const [],
  }) {
    final issues = <CommitteeValidationIssue>[];

    // 1. Mandatory metadata
    if (object.officialName.trim().isEmpty) {
      issues.add(const CommitteeValidationIssue(
        field: 'officialName',
        message: 'Validation Failed: Official Name cannot be empty.',
      ));
    }

    if (object.constitutingAuthority.trim().isEmpty) {
      issues.add(const CommitteeValidationIssue(
        field: 'constitutingAuthority',
        message: 'Validation Failed: Constituting Authority citation is required.',
      ));
    }

    if (object.chairperson.name.trim().isEmpty) {
      issues.add(const CommitteeValidationIssue(
        field: 'chairperson',
        message: 'Validation Failed: Chairperson name is required.',
      ));
    }

    // 2. Evidence attachment
    if (object.evidenceIds.isEmpty) {
      issues.add(const CommitteeValidationIssue(
        field: 'evidenceIds',
        message: 'Validation Failed: Evidence attachment is missing.',
      ));
    }

    // 3. Duplicate check
    for (final exist in existingCommittees) {
      if (exist.id != object.id &&
          exist.officialName.toLowerCase().trim() == object.officialName.toLowerCase().trim() &&
          exist.yearConstituted == object.yearConstituted) {
        issues.add(CommitteeValidationIssue(
          field: 'duplicate',
          message:
              'Validation Failed: Duplicate committee detected with matching name ("${exist.officialName}") and year (${exist.yearConstituted}).',
        ));
        break;
      }
    }

    // 4. Missing terms of reference
    if (object.termsOfReference.description.trim().isEmpty) {
      issues.add(const CommitteeValidationIssue(
        field: 'termsOfReference',
        message: 'Validation Failed: Terms of Reference description cannot be empty.',
      ));
    }

    // 5. Editorial approval check for publication
    if (object.editorialStatus == EditorialStatus.published &&
        object.editorialStatus != EditorialStatus.approved &&
        object.editorialStatus != EditorialStatus.seniorEditorialReview) {
      issues.add(const CommitteeValidationIssue(
        field: 'editorialStatus',
        message: 'Validation Failed: Cannot publish without editorial approval.',
      ));
    }

    return CommitteeValidationReport(
      isValid: issues.every((i) => !i.isBlocking),
      issues: issues,
    );
  }
}
