library;

import 'package:garuda_editor/garuda_editor.dart';

import '../domain/entities/body_enums.dart';
import '../domain/entities/body_knowledge_object.dart';

/// A single validation finding for a Body Knowledge Object.
class BodyValidationIssue {
  final String field;
  final String message;
  final bool isBlocking;

  const BodyValidationIssue({
    required this.field,
    required this.message,
    this.isBlocking = true,
  });
}

/// Aggregate validation result for a Body Knowledge Object.
class BodyValidationReport {
  final bool isValid;
  final List<BodyValidationIssue> issues;

  const BodyValidationReport({
    required this.isValid,
    required this.issues,
  });
}

/// Validates a Government Body Knowledge Object for publication-readiness.
///
/// A Body is **not** production-ready unless it carries a traceable official
/// source, mandatory evidence and a legal (constitutional/statutory) basis. The
/// validator also detects duplicate IDs/bodies, missing identity/type/basis
/// data, malformed article references, broken act references, invalid
/// relationship references, malformed URLs, placeholder records, contradictory
/// metadata and incomplete appointment/tenure data.
class BodyValidator {
  BodyValidator._();

  static final RegExp _articlePattern =
      RegExp(r'^Article [0-9]+[A-Z]*(\(\w+\))*$');

  /// Known non-official / user-generated domains that cannot serve as a
  /// traceable official source.
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
  ];

  static BodyValidationReport validate(
    BodyKnowledgeObject object, {
    List<BodyKnowledgeObject> existingBodies = const [],
  }) {
    final issues = <BodyValidationIssue>[];

    // 1. Mandatory identity
    if (object.id.trim().isEmpty) {
      issues.add(const BodyValidationIssue(
        field: 'id',
        message: 'Validation Failed: Body ID cannot be empty.',
      ));
    }

    if (object.officialName.trim().isEmpty) {
      issues.add(const BodyValidationIssue(
        field: 'officialName',
        message: 'Validation Failed: Official Name cannot be empty.',
      ));
    }

    if (object.shortName.trim().isEmpty) {
      issues.add(const BodyValidationIssue(
        field: 'shortName',
        message: 'Validation Failed: Short Name / acronym is required.',
      ));
    }

    // 2. Legal basis must be present
    final hasBasis = object.establishingArticleIds.isNotEmpty ||
        object.establishingActIds.isNotEmpty;
    if (!hasBasis) {
      issues.add(const BodyValidationIssue(
        field: 'legalBasis',
        message:
            'Validation Failed: Missing constitutional/statutory basis - every body requires an establishing Article or Act.',
      ));
    }

    // 3. Contradictory metadata around constitutional basis
    if (object.constitutionalBasis == ConstitutionalBasis.none &&
        object.establishingArticleIds.isNotEmpty) {
      issues.add(const BodyValidationIssue(
        field: 'constitutionalBasis',
        message:
            'Validation Failed: Contradictory metadata - establishing Articles present but constitutional basis marked "none".',
      ));
    }
    if (object.constitutionalBasis != ConstitutionalBasis.none &&
        object.establishingArticleIds.isEmpty) {
      issues.add(const BodyValidationIssue(
        field: 'constitutionalBasis',
        message:
            'Validation Failed: Contradictory metadata - constitutional basis declared but no establishing Article provided.',
      ));
    }

    // 4. Malformed article references
    for (final article in object.establishingArticleIds) {
      if (!_articlePattern.hasMatch(article.trim())) {
        issues.add(BodyValidationIssue(
          field: 'establishingArticleIds',
          message:
              'Validation Failed: Malformed Article reference "$article". Expected format like "Article 324" or "Article 15(3)".',
        ));
      }
    }

    // 5. Broken / malformed Act references
    for (final act in [...object.establishingActIds, ...object.relatedActIds]) {
      if (act.trim().isEmpty) {
        issues.add(const BodyValidationIssue(
          field: 'establishingActIds',
          message: 'Validation Failed: Empty Act reference is not allowed.',
        ));
      } else if (act.trim().length < 6 &&
          !act.contains('Act') &&
          !act.contains('Code') &&
          !act.contains('Ordinance')) {
        issues.add(BodyValidationIssue(
          field: 'establishingActIds',
          message: 'Validation Failed: Act reference "$act" looks malformed.',
          isBlocking: false,
        ));
      }
    }

    // 6. Mandatory official source + URL format
    if (object.officialSource.trim().isEmpty) {
      issues.add(const BodyValidationIssue(
        field: 'officialSource',
        message:
            'Validation Failed: Missing official source - every body requires a traceable official source.',
      ));
    } else {
      final lower = object.officialSource.toLowerCase().trim();
      final looksLikeUrl =
          lower.startsWith('http://') || lower.startsWith('https://');
      if (!looksLikeUrl) {
        issues.add(BodyValidationIssue(
          field: 'officialSource',
          message:
              'Validation Failed: Official source "${object.officialSource}" is not a recognised official URL.',
        ));
      } else if (_nonOfficialDomains.any((d) => lower.contains(d))) {
        issues.add(BodyValidationIssue(
          field: 'officialSource',
          message:
              'Validation Failed: Official source "${object.officialSource}" is not a recognised official government source.',
        ));
      }
    }

    // 7. Mandatory evidence (publication rule)
    if (object.evidenceIds.isEmpty) {
      issues.add(const BodyValidationIssue(
        field: 'evidenceIds',
        message:
            'Validation Failed: Evidence attachment is missing - a body must not be production-ready without mandatory evidence.',
      ));
    }

    // 8. Placeholder detection
    if (object.mandate.trim().isEmpty) {
      issues.add(const BodyValidationIssue(
        field: 'mandate',
        message:
            'Validation Failed: Mandate is missing - placeholder/uninformative body record.',
      ));
    }
    final lowerName = object.officialName.toLowerCase().trim();
    if (lowerName.contains('placeholder') ||
        lowerName.contains('lorem ipsum') ||
        lowerName == 'tbd' ||
        lowerName == 'sample' ||
        lowerName.contains('xxx body') ||
        lowerName.contains('dummy body')) {
      issues.add(const BodyValidationIssue(
        field: 'officialName',
        message:
            'Validation Failed: Placeholder body name detected - placeholder records are not production-ready.',
      ));
    }

    // 9. Incomplete appointment/tenure data for constitutional bodies
    if (object.bodyType == BodyType.constitutional) {
      if (object.appointmentMechanism.trim().isEmpty) {
        issues.add(const BodyValidationIssue(
          field: 'appointmentMechanism',
          message:
              'Validation Failed: Appointment mechanism is required for a constitutional body.',
        ));
      }
      if (object.tenure.trim().isEmpty) {
        issues.add(const BodyValidationIssue(
          field: 'tenure',
          message: 'Validation Failed: Tenure is required for a constitutional body.',
        ));
      }
      if (object.removalMechanism.trim().isEmpty) {
        issues.add(const BodyValidationIssue(
          field: 'removalMechanism',
          message:
              'Validation Failed: Removal mechanism is required for a constitutional body.',
        ));
      }
    } else if (object.appointmentMechanism.trim().isEmpty) {
      issues.add(const BodyValidationIssue(
        field: 'appointmentMechanism',
        message:
            'Validation Failed: Appointment mechanism is missing for a statutory/regulatory body.',
        isBlocking: false,
      ));
    }

    // 10. Year established
    if (object.yearEstablished <= 0) {
      issues.add(const BodyValidationIssue(
        field: 'yearEstablished',
        message: 'Validation Failed: Year established is required.',
      ));
    }

    // 11. Duplicate detection
    for (final exist in existingBodies) {
      if (exist.id == object.id) {
        issues.add(BodyValidationIssue(
          field: 'duplicate',
          message: 'Validation Failed: Duplicate body ID "${object.id}".',
        ));
        break;
      }
      if (exist.id != object.id &&
          exist.officialName.toLowerCase().trim() ==
              object.officialName.toLowerCase().trim()) {
        issues.add(BodyValidationIssue(
          field: 'duplicate',
          message:
              'Validation Failed: Duplicate body detected with matching official name ("${exist.officialName}").',
        ));
        break;
      }
    }

    // 12. Invalid relationship references
    final knownIds = existingBodies.map((b) => b.id).toSet();
    for (final rel in object.relationships) {
      if (rel.sourceId.isNotEmpty && !knownIds.contains(rel.sourceId)) {
        issues.add(BodyValidationIssue(
          field: 'relationships',
          message:
              'Validation Failed: Relationship source "${rel.sourceId}" does not exist.',
          isBlocking: false,
        ));
      }
      if (rel.targetId.isNotEmpty && !knownIds.contains(rel.targetId)) {
        issues.add(BodyValidationIssue(
          field: 'relationships',
          message:
              'Validation Failed: Relationship target "${rel.targetId}" does not exist.',
          isBlocking: false,
        ));
      }
    }

    // 13. Serialization round-trip integrity
    final roundTripped = BodyKnowledgeObject.fromJson(object.toJson());
    if (roundTripped.id != object.id ||
        roundTripped.officialName != object.officialName ||
        roundTripped.shortName != object.shortName ||
        roundTripped.bodyType != object.bodyType ||
        roundTripped.yearEstablished != object.yearEstablished) {
      issues.add(const BodyValidationIssue(
        field: 'serialization',
        message:
            'Validation Failed: JSON round-trip is inconsistent - malformed serialization.',
      ));
    }

    // 14. Editorial gate for publication
    if (object.editorialStatus == EditorialStatus.published &&
        object.evidenceIds.isEmpty) {
      issues.add(const BodyValidationIssue(
        field: 'editorialStatus',
        message:
            'Validation Failed: Cannot publish a body without mandatory evidence.',
      ));
    }

    return BodyValidationReport(
      isValid: issues.every((i) => !i.isBlocking),
      issues: issues,
    );
  }
}
