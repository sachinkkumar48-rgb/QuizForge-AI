library;

import 'package:garuda_editor/garuda_editor.dart';

import '../domain/entities/international_enums.dart';
import '../domain/entities/international_knowledge_object.dart';

/// A single validation finding for an International Knowledge Object.
class InternationalValidationIssue {
  final String field;
  final String message;
  final bool isBlocking;

  const InternationalValidationIssue({
    required this.field,
    required this.message,
    this.isBlocking = true,
  });
}

/// Aggregate validation result for an International Knowledge Object.
class InternationalValidationReport {
  final bool isValid;
  final List<InternationalValidationIssue> issues;

  const InternationalValidationReport({
    required this.isValid,
    required this.issues,
  });
}

/// Validates an International Organisation Knowledge Object for
/// publication-readiness.
///
/// An organisation is **not** production-ready unless it carries a traceable
/// official source, mandatory evidence and a valid institutional classification.
/// The validator also detects duplicate IDs/organisations, missing identity and
/// type data, malformed/fabricated URLs, invalid membership data, contradictory
/// institutional metadata, invalid founding dates, broken treaty references,
/// broken cross-package relationships, invalid relationship references,
/// placeholder records and incomplete India relationship metadata.
class InternationalValidator {
  InternationalValidator._();

  static const List<String> _nonOfficialDomains = [
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
    'britannica.com',
  ];

  static InternationalValidationReport validate(
    InternationalKnowledgeObject object, {
    List<InternationalKnowledgeObject> existingOrganisations = const [],
  }) {
    final issues = <InternationalValidationIssue>[];

    // 1. Mandatory identity
    if (object.id.trim().isEmpty) {
      issues.add(const InternationalValidationIssue(
        field: 'id',
        message: 'Validation Failed: Organisation ID cannot be empty.',
      ));
    }

    if (object.officialName.trim().isEmpty) {
      issues.add(const InternationalValidationIssue(
        field: 'officialName',
        message: 'Validation Failed: Official Name cannot be empty.',
      ));
    }

    if (object.acronym.trim().isEmpty) {
      issues.add(const InternationalValidationIssue(
        field: 'acronym',
        message: 'Validation Failed: Acronym is required.',
      ));
    }

    // 2. Institutional classification present
    final isDefaultFilled = object.bodyType == InternationalBodyType.organisation &&
        object.category == InternationalCategory.unitedNations &&
        object.establishedYear == 0 &&
        object.headquarters.isEmpty;
    if (isDefaultFilled) {
      issues.add(const InternationalValidationIssue(
        field: 'bodyType',
        message:
            'Validation Failed: Missing institutional type/classification - the record is default-filled.',
      ));
    }

    // 3. Mandatory official source + URL format
    if (object.officialSource.trim().isEmpty) {
      issues.add(const InternationalValidationIssue(
        field: 'officialSource',
        message:
            'Validation Failed: Missing official source - every organisation requires a traceable official source.',
      ));
    } else {
      final lower = object.officialSource.toLowerCase().trim();
      final looksLikeUrl =
          lower.startsWith('http://') || lower.startsWith('https://');
      if (!looksLikeUrl) {
        issues.add(InternationalValidationIssue(
          field: 'officialSource',
          message:
              'Validation Failed: Official source "${object.officialSource}" is not a recognised official URL.',
        ));
      } else if (_nonOfficialDomains.any((d) => lower.contains(d))) {
        issues.add(InternationalValidationIssue(
          field: 'officialSource',
          message:
              'Validation Failed: Official source "${object.officialSource}" is not a recognised official institution/authoritative source.',
        ));
      }
    }

    // 4. Mandatory evidence (publication rule)
    if (object.evidenceIds.isEmpty) {
      issues.add(const InternationalValidationIssue(
        field: 'evidenceIds',
        message:
            'Validation Failed: Evidence attachment is missing - an organisation must not be production-ready without mandatory evidence.',
      ));
    }

    // 5. Invalid founding dates
    if (object.establishedYear <= 0) {
      issues.add(const InternationalValidationIssue(
        field: 'establishedYear',
        message: 'Validation Failed: Founding year is required.',
      ));
    } else if (object.establishedYear > DateTime.now().year) {
      issues.add(const InternationalValidationIssue(
        field: 'establishedYear',
        message: 'Validation Failed: Founding year cannot be in the future.',
      ));
    }

    // 6. Contradictory treaty metadata
    if (object.treatyStatus != TreatyStatus.notApplicable &&
        object.foundingTreaty.trim().isEmpty) {
      issues.add(const InternationalValidationIssue(
        field: 'foundingTreaty',
        message:
            'Validation Failed: Treaty-based institution declared but founding treaty/agreement is missing.',
      ));
    }

    // 7. Invalid membership data
    if (object.membershipCount != null && object.membershipCount! <= 0) {
      issues.add(const InternationalValidationIssue(
        field: 'membershipCount',
        message:
            'Validation Failed: Invalid membership data - membership count must be positive when provided.',
      ));
    }

    // 8. Contradictory India relationship metadata
    if (object.indiaMembership == IndiaRelationshipStatus.nonMember &&
        object.indiaJoiningYear != null) {
      issues.add(const InternationalValidationIssue(
        field: 'indiaJoiningYear',
        message:
            'Validation Failed: Contradictory metadata - India is marked a non-member but a joining year is provided.',
      ));
    }
    if (object.indiaMembership == IndiaRelationshipStatus.notApplicable &&
        object.indiaJoiningYear != null) {
      issues.add(const InternationalValidationIssue(
        field: 'indiaJoiningYear',
        message:
            'Validation Failed: Contradictory metadata - India relationship is not applicable but a joining year is provided.',
      ));
    }

    // 9. Incomplete India metadata where applicable (non-blocking)
    if (object.indiaMembership == IndiaRelationshipStatus.foundingMember &&
        object.indiaJoiningYear == null) {
      issues.add(const InternationalValidationIssue(
        field: 'indiaJoiningYear',
        message:
            'Validation Failed: India is a founding member but the joining year is not recorded.',
        isBlocking: false,
      ));
    }
    if (object.upscRelevance == UpscRelevanceLevel.high &&
        object.indiaRelevance.trim().isEmpty) {
      issues.add(const InternationalValidationIssue(
        field: 'indiaRelevance',
        message:
            'Validation Failed: High-UPSC-relevance organisation should document India relevance.',
        isBlocking: false,
      ));
    }

    // 10. Placeholder detection
    if (object.mandate.trim().isEmpty) {
      issues.add(const InternationalValidationIssue(
        field: 'mandate',
        message:
            'Validation Failed: Mandate is missing - placeholder/uninformative organisation record.',
      ));
    }
    final lowerName = object.officialName.toLowerCase().trim();
    if (lowerName.contains('placeholder') ||
        lowerName.contains('lorem ipsum') ||
        lowerName == 'tbd' ||
        lowerName == 'sample' ||
        lowerName.contains('dummy org')) {
      issues.add(const InternationalValidationIssue(
        field: 'officialName',
        message:
            'Validation Failed: Placeholder organisation name detected - placeholder records are not production-ready.',
      ));
    }

    // 11. Broken treaty/convention references
    for (final convention in object.importantConventions) {
      if (convention.trim().length < 5) {
        issues.add(InternationalValidationIssue(
          field: 'importantConventions',
          message:
              'Validation Failed: Treaty/convention reference "$convention" is too short to be valid.',
          isBlocking: false,
        ));
      }
    }

    // 12. Duplicate detection
    for (final exist in existingOrganisations) {
      if (exist.id == object.id) {
        issues.add(InternationalValidationIssue(
          field: 'duplicate',
          message: 'Validation Failed: Duplicate organisation ID "${object.id}".',
        ));
        break;
      }
      if (exist.id != object.id &&
          exist.officialName.toLowerCase().trim() ==
              object.officialName.toLowerCase().trim()) {
        issues.add(InternationalValidationIssue(
          field: 'duplicate',
          message:
              'Validation Failed: Duplicate organisation detected with matching official name ("${exist.officialName}").',
        ));
        break;
      }
    }

    // 13. Invalid relationship references
    final knownIds = existingOrganisations.map((o) => o.id).toSet();
    for (final rel in object.relationships) {
      if (rel.sourceId.isNotEmpty && !knownIds.contains(rel.sourceId)) {
        issues.add(InternationalValidationIssue(
          field: 'relationships',
          message:
              'Validation Failed: Relationship source "${rel.sourceId}" does not exist.',
          isBlocking: false,
        ));
      }
      if (rel.targetId.isNotEmpty && !knownIds.contains(rel.targetId)) {
        issues.add(InternationalValidationIssue(
          field: 'relationships',
          message:
              'Validation Failed: Relationship target "${rel.targetId}" does not exist.',
          isBlocking: false,
        ));
      }
    }

    // 14. Serialization round-trip integrity
    final roundTripped = InternationalKnowledgeObject.fromJson(object.toJson());
    if (roundTripped.id != object.id ||
        roundTripped.officialName != object.officialName ||
        roundTripped.acronym != object.acronym ||
        roundTripped.establishedYear != object.establishedYear ||
        roundTripped.bodyType != object.bodyType) {
      issues.add(const InternationalValidationIssue(
        field: 'serialization',
        message:
            'Validation Failed: JSON round-trip is inconsistent - malformed serialization.',
      ));
    }

    // 15. Editorial gate for publication
    if (object.editorialStatus == EditorialStatus.published &&
        object.evidenceIds.isEmpty) {
      issues.add(const InternationalValidationIssue(
        field: 'editorialStatus',
        message:
            'Validation Failed: Cannot publish an organisation without mandatory evidence.',
      ));
    }

    return InternationalValidationReport(
      isValid: issues.every((i) => !i.isBlocking),
      issues: issues,
    );
  }
}
