library;

import 'package:garuda_editor/garuda_editor.dart';

import '../domain/entities/scheme_knowledge_object.dart';

/// A single validation finding for a Scheme Knowledge Object.
class SchemeValidationIssue {
  final String field;
  final String message;
  final bool isBlocking;

  const SchemeValidationIssue({
    required this.field,
    required this.message,
    this.isBlocking = true,
  });
}

/// Aggregate validation result for a Scheme Knowledge Object.
class SchemeValidationReport {
  final bool isValid;
  final List<SchemeValidationIssue> issues;

  const SchemeValidationReport({
    required this.isValid,
    required this.issues,
  });
}

/// Validates a Government Scheme Knowledge Object for publication-readiness.
///
/// A Scheme is **not** production-ready unless it carries a traceable official
/// source and at least one evidence reference (mandatory evidence rule). The
/// validator also detects duplicate records, broken relationships, invalid
/// cross-package references, missing identity/beneficiary data, malformed
/// serialization and placeholder records.
class SchemeValidator {
  SchemeValidator._();

  static SchemeValidationReport validate(
    SchemeKnowledgeObject object, {
    List<SchemeKnowledgeObject> existingSchemes = const [],
    List<String> knownCommitteeIds = const [],
    List<String> knownReportIds = const [],
    List<String> knownPyqIds = const [],
    List<String> knownCurrentAffairsIds = const [],
  }) {
    final issues = <SchemeValidationIssue>[];

    // 1. Mandatory identity fields
    if (object.id.trim().isEmpty) {
      issues.add(const SchemeValidationIssue(
        field: 'id',
        message: 'Validation Failed: Scheme ID cannot be empty.',
      ));
    }

    if (object.officialName.trim().isEmpty) {
      issues.add(const SchemeValidationIssue(
        field: 'officialName',
        message: 'Validation Failed: Official Name cannot be empty.',
      ));
    }

    if (object.shortName.trim().isEmpty) {
      issues.add(const SchemeValidationIssue(
        field: 'shortName',
        message: 'Validation Failed: Short Name / acronym is required.',
      ));
    }

    // 2. Mandatory official source
    if (object.officialSource.trim().isEmpty) {
      issues.add(const SchemeValidationIssue(
        field: 'officialSource',
        message:
            'Validation Failed: Missing official source - every scheme requires a traceable official source.',
      ));
    } else {
      final lower = object.officialSource.toLowerCase().trim();
      final looksLikeUrl =
          lower.startsWith('http://') || lower.startsWith('https://');
      // Known non-official / user-generated domains that cannot serve as a
      // traceable official source.
      const nonOfficialDomains = [
        'example.com',
        'wikipedia.org',
        'facebook.com',
        'twitter.com',
        'instagram.com',
        'youtube.com',
        'blogspot.com',
        'wordpress.com',
        'quora.com',
        'reddit.com',
        'medium.com',
        'google.com',
      ];
      if (!looksLikeUrl) {
        issues.add(SchemeValidationIssue(
          field: 'officialSource',
          message:
              'Validation Failed: Official source "${object.officialSource}" is not a recognised official URL.',
        ));
      } else if (nonOfficialDomains.any((d) => lower.contains(d))) {
        issues.add(SchemeValidationIssue(
          field: 'officialSource',
          message:
              'Validation Failed: Official source "${object.officialSource}" is not a recognised official government source.',
        ));
      }
    }

    // 3. Mandatory evidence (production rule)
    if (object.evidenceIds.isEmpty) {
      issues.add(const SchemeValidationIssue(
        field: 'evidenceIds',
        message:
            'Validation Failed: Evidence attachment is missing - a scheme must not be production-ready without mandatory evidence.',
      ));
    }

    // 4. Last-verified date (if present, must be a valid ISO date)
    if (object.lastVerifiedDate.isNotEmpty) {
      final parsed = DateTime.tryParse(object.lastVerifiedDate);
      if (parsed == null) {
        issues.add(const SchemeValidationIssue(
          field: 'lastVerifiedDate',
          message: 'Validation Failed: Last verified date is malformed.',
        ));
      }
    }

    // 5. Launch date must not be in the future
    final now = DateTime.now();
    if (object.launchDate != null && object.launchDate!.isAfter(now)) {
      issues.add(const SchemeValidationIssue(
        field: 'launchDate',
        message: 'Validation Failed: Launch date cannot be in the future.',
      ));
    }

    // 6. Beneficiary information
    if (object.beneficiaries.isEmpty && object.targetBeneficiaries.isEmpty) {
      issues.add(const SchemeValidationIssue(
        field: 'beneficiaries',
        message:
            'Validation Failed: Beneficiary information is missing - at least one beneficiary group or target beneficiary is required.',
      ));
    }

    // 7. Duplicate detection
    for (final exist in existingSchemes) {
      if (exist.id == object.id) {
        issues.add(SchemeValidationIssue(
          field: 'duplicate',
          message: 'Validation Failed: Duplicate scheme ID "${object.id}".',
        ));
        break;
      }
      if (exist.id != object.id &&
          exist.officialName.toLowerCase().trim() ==
              object.officialName.toLowerCase().trim() &&
          exist.ministry == object.ministry) {
        issues.add(SchemeValidationIssue(
          field: 'duplicate',
          message:
              'Validation Failed: Duplicate scheme detected with matching official name ("${exist.officialName}") under the same ministry.',
        ));
        break;
      }
    }

    // 8. Broken explicit relationships (source/target must exist)
    final knownIds = existingSchemes.map((s) => s.id).toSet();
    for (final rel in object.relationships) {
      if (rel.sourceId.isNotEmpty && !knownIds.contains(rel.sourceId)) {
        issues.add(SchemeValidationIssue(
          field: 'relationships',
          message:
              'Validation Failed: Relationship source "${rel.sourceId}" does not exist.',
          isBlocking: false,
        ));
      }
      if (rel.targetId.isNotEmpty && !knownIds.contains(rel.targetId)) {
        issues.add(SchemeValidationIssue(
          field: 'relationships',
          message:
              'Validation Failed: Relationship target "${rel.targetId}" does not exist.',
          isBlocking: false,
        ));
      }
    }

    // 9. Cross-package references (non-blocking when known lists supplied)
    if (knownCommitteeIds.isNotEmpty) {
      final known = knownCommitteeIds.toSet();
      for (final ref in object.relatedCommitteeIds) {
        if (!known.contains(ref)) {
          issues.add(SchemeValidationIssue(
            field: 'relatedCommitteeIds',
            message:
                'Validation Failed: Broken reference - Committee "$ref" not found in the GARUDA Committees Library.',
            isBlocking: false,
          ));
        }
      }
    }
    if (knownReportIds.isNotEmpty) {
      final known = knownReportIds.toSet();
      for (final ref in object.relatedReportIds) {
        if (!known.contains(ref)) {
          issues.add(SchemeValidationIssue(
            field: 'relatedReportIds',
            message:
                'Validation Failed: Broken reference - Report "$ref" not found in the GARUDA Reports Library.',
            isBlocking: false,
          ));
        }
      }
    }
    if (knownPyqIds.isNotEmpty) {
      final known = knownPyqIds.toSet();
      for (final ref in object.relatedPyqIds) {
        if (!known.contains(ref)) {
          issues.add(SchemeValidationIssue(
            field: 'relatedPyqIds',
            message:
                'Validation Failed: Broken reference - PYQ "$ref" not found in the GARUDA PYQ corpus.',
            isBlocking: false,
          ));
        }
      }
    }
    if (knownCurrentAffairsIds.isNotEmpty) {
      final known = knownCurrentAffairsIds.toSet();
      for (final ref in object.relatedCurrentAffairsIds) {
        if (!known.contains(ref)) {
          issues.add(SchemeValidationIssue(
            field: 'relatedCurrentAffairsIds',
            message:
                'Validation Failed: Broken reference - Current Affair "$ref" not found.',
            isBlocking: false,
          ));
        }
      }
    }

    // 10. Serialization round-trip integrity
    final roundTripped = SchemeKnowledgeObject.fromJson(object.toJson());
    if (roundTripped.id != object.id ||
        roundTripped.officialName != object.officialName ||
        roundTripped.shortName != object.shortName ||
        roundTripped.ministry != object.ministry ||
        roundTripped.category != object.category) {
      issues.add(const SchemeValidationIssue(
        field: 'serialization',
        message:
            'Validation Failed: JSON round-trip is inconsistent - malformed serialization.',
      ));
    }

    // 11. Editorial gate for publication: published objects must carry evidence.
    if (object.editorialStatus == EditorialStatus.published &&
        object.evidenceIds.isEmpty) {
      issues.add(const SchemeValidationIssue(
        field: 'editorialStatus',
        message:
            'Validation Failed: Cannot publish a scheme without mandatory evidence.',
      ));
    }

    return SchemeValidationReport(
      isValid: issues.every((i) => !i.isBlocking),
      issues: issues,
    );
  }
}
