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
    Set<String> knownArticleIds = const {},
    Set<String> knownActIds = const {},
    Set<String> knownCommitteeIds = const {},
    Set<String> knownSchemeNames = const {},
    Set<String> knownBodyIds = const {},
    Set<String> knownInternationalIds = const {},
    Set<String> knownCurrentAffairsIds = const {},
    Set<String> knownPyqIds = const {},
    Set<String> knownCaseLawIds = const {},
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
    } else if (object.publicationYear > DateTime.now().year) {
      issues.add(const ReportValidationIssue(
        field: 'publicationYear',
        message: 'Validation Failed: Publication Year cannot be in the future.',
      ));
    }

    // 2. Missing official URL + URL format / fabricated-looking domains
    if (object.officialUrl.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'officialUrl',
        message:
            'Validation Failed: Missing official URL - every report requires an official source URL.',
      ));
    } else {
      final lower = object.officialUrl.toLowerCase().trim();
      final looksLikeUrl =
          lower.startsWith('http://') || lower.startsWith('https://');
      if (!looksLikeUrl) {
        issues.add(ReportValidationIssue(
          field: 'officialUrl',
          message:
              'Validation Failed: Official URL "${object.officialUrl}" is not a recognised URL.',
        ));
      } else {
        const nonOfficialDomains = [
          'example.com',
          'wikipedia.org',
          'facebook.com',
          'twitter.com',
          'blogspot.com',
          'wordpress.com',
          'quora.com',
          'reddit.com',
          'medium.com',
          'britannica.com',
        ];
        if (nonOfficialDomains.any((d) => lower.contains(d))) {
          issues.add(ReportValidationIssue(
            field: 'officialUrl',
            message:
                'Validation Failed: Official URL "${object.officialUrl}" is not a recognised official/authoritative source.',
          ));
        }
      }
    }

    // 2b. Contradictory metadata
    if (!object.indiaCoverage &&
        object.geographicalScope.toLowerCase().contains('india')) {
      issues.add(const ReportValidationIssue(
        field: 'indiaCoverage',
        message:
            'Validation Failed: Contradictory metadata - geographical scope is India but India coverage is marked false.',
      ));
    }

    // 2c. Impossible publication years
    if (object.publicationYear > 0 && object.publicationYear < 1800) {
      issues.add(ReportValidationIssue(
        field: 'publicationYear',
        message:
            'Validation Failed: Publication Year ${object.publicationYear} is implausible for an official report.',
        isBlocking: false,
      ));
    }

    // 2d. Malformed publication date
    if (object.publicationDate.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(object.publicationDate);
      if (parsed == null) {
        issues.add(ReportValidationIssue(
          field: 'publicationDate',
          message:
              'Validation Failed: Publication date "${object.publicationDate}" is not a valid ISO-8601 date.',
          isBlocking: false,
        ));
      }
    }

    // 2e. Placeholder / fabricated-looking content
    const placeholders = [
      'tbd',
      'todo',
      'lorem',
      'placeholder',
      'xxx',
      'na -',
      'not available',
      'sample text',
      'example.com',
    ];
    final titleLower = object.officialTitle.toLowerCase();
    final summaryLower = object.executiveSummary.toLowerCase();
    if (placeholders.any(titleLower.contains)) {
      issues.add(const ReportValidationIssue(
        field: 'officialTitle',
        message: 'Validation Failed: Title appears to contain placeholder content.',
      ));
    }
    if (placeholders.any(summaryLower.contains)) {
      issues.add(const ReportValidationIssue(
        field: 'executiveSummary',
        message:
            'Validation Failed: Summary appears to contain placeholder content.',
      ));
    }

    // 2f. Contradictory reporting period vs publication year
    if (object.reportingPeriod.trim().isNotEmpty &&
        object.publicationYear > 0) {
      final periodYears = RegExp(r'(19|20)\d{2}')
          .allMatches(object.reportingPeriod)
          .map((m) => int.parse(m.group(0)!))
          .toSet();
      if (periodYears.isNotEmpty &&
          periodYears.every((y) => y > object.publicationYear)) {
        issues.add(ReportValidationIssue(
          field: 'reportingPeriod',
          message:
              'Validation Failed: Reporting period "${object.reportingPeriod}" is later than publication year ${object.publicationYear}.',
          isBlocking: false,
        ));
      }
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

    // 5b. Broken cross-package references
    _checkBrokenReferences(
        object.relatedArticleIds, knownArticleIds, 'relatedArticleIds', issues);
    _checkBrokenReferences(
        object.relatedActIds, knownActIds, 'relatedActIds', issues);
    _checkBrokenReferences(object.relatedCommitteeIds, knownCommitteeIds,
        'relatedCommitteeIds', issues);
    _checkBrokenReferences(object.relatedSchemeNames, knownSchemeNames,
        'relatedSchemeNames', issues);
    _checkBrokenReferences(
        object.relatedBodies, knownBodyIds, 'relatedBodies', issues);
    _checkBrokenReferences(object.relatedInternationalOrganisations,
        knownInternationalIds, 'relatedInternationalOrganisations', issues);
    _checkBrokenReferences(object.relatedCurrentAffairsIds,
        knownCurrentAffairsIds, 'relatedCurrentAffairsIds', issues);
    _checkBrokenReferences(
        object.relatedPyqIds, knownPyqIds, 'relatedPyqIds', issues);
    _checkBrokenReferences(
        object.relatedCaseLawIds, knownCaseLawIds, 'relatedCaseLawIds', issues);

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

  /// Validates an Indicator Knowledge Object for publication-readiness.
  static ReportValidationReport validateIndicator(
    IndicatorKnowledgeObject object, {
    List<IndicatorKnowledgeObject> existingIndicators = const [],
    List<ReportKnowledgeObject> knownReports = const [],
  }) {
    final issues = <ReportValidationIssue>[];

    if (object.id.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'id',
        message: 'Validation Failed: Indicator ID cannot be empty.',
      ));
    }

    if (object.name.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'name',
        message: 'Validation Failed: Indicator name cannot be empty.',
      ));
    }

    if (object.value.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'value',
        message: 'Validation Failed: Indicator value is missing.',
      ));
    } else if (!_isPlausibleIndicatorValue(object.value)) {
      issues.add(ReportValidationIssue(
        field: 'value',
        message:
            'Validation Failed: Indicator value "${object.value}" is malformed - expected a numeric value.',
      ));
    }

    if (object.source.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'source',
        message:
            'Validation Failed: Missing official source - every indicator requires a traceable source.',
      ));
    }

    if (object.referenceYear <= 0) {
      issues.add(const ReportValidationIssue(
        field: 'referenceYear',
        message: 'Validation Failed: Reference year is required.',
      ));
    } else if (object.referenceYear > DateTime.now().year + 1) {
      issues.add(const ReportValidationIssue(
        field: 'referenceYear',
        message: 'Validation Failed: Reference year cannot be in the future.',
      ));
    }

    if (object.rank != null && object.rank! <= 0) {
      issues.add(const ReportValidationIssue(
        field: 'rank',
        message: 'Validation Failed: Indicator rank must be positive.',
      ));
    }

    // Duplicate indicators.
    for (final exist in existingIndicators) {
      if (exist.id == object.id) {
        issues.add(ReportValidationIssue(
          field: 'duplicate',
          message: 'Validation Failed: Duplicate indicator ID "${object.id}".',
        ));
        break;
      }
      if (exist.id != object.id &&
          exist.name.toLowerCase().trim() == object.name.toLowerCase().trim() &&
          exist.referenceYear == object.referenceYear) {
        issues.add(ReportValidationIssue(
          field: 'duplicate',
          message:
              'Validation Failed: Duplicate indicator "${exist.name}" for reference year ${exist.referenceYear}.',
        ));
        break;
      }
    }

    // Broken report references.
    if (knownReports.isNotEmpty) {
      final knownIds = knownReports.map((r) => r.id).toSet();
      for (final ref in object.relatedReportIds) {
        if (!knownIds.contains(ref)) {
          issues.add(ReportValidationIssue(
            field: 'relatedReportIds',
            message:
                'Validation Failed: Broken reference - Report "$ref" not found in the library.',
            isBlocking: false,
          ));
        }
      }
    }

    if (object.evidenceIds.isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'evidenceIds',
        message:
            'Validation Failed: Evidence attachment is missing for the indicator.',
      ));
    }

    return ReportValidationReport(
      isValid: issues.every((i) => !i.isBlocking),
      issues: issues,
    );
  }

  /// Validates an Index Knowledge Object for publication-readiness.
  static ReportValidationReport validateIndex(
    IndexKnowledgeObject object, {
    List<IndexKnowledgeObject> existingIndices = const [],
    List<ReportKnowledgeObject> knownReports = const [],
  }) {
    final issues = <ReportValidationIssue>[];

    if (object.id.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'id',
        message: 'Validation Failed: Index ID cannot be empty.',
      ));
    }

    if (object.indexName.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'indexName',
        message: 'Validation Failed: Index name cannot be empty.',
      ));
    }

    if (object.publisher.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'publisher',
        message: 'Validation Failed: Publisher is required.',
      ));
    }

    if (object.latestEditionYear <= 0) {
      issues.add(const ReportValidationIssue(
        field: 'latestEditionYear',
        message: 'Validation Failed: Latest edition year is required.',
      ));
    } else if (object.latestEditionYear > DateTime.now().year + 1) {
      issues.add(const ReportValidationIssue(
        field: 'latestEditionYear',
        message:
            'Validation Failed: Latest edition year cannot be in the future.',
      ));
    }

    if (object.officialUrl.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'officialUrl',
        message: 'Validation Failed: Missing official URL.',
      ));
    } else if (!(object.officialUrl.startsWith('http://') ||
        object.officialUrl.startsWith('https://'))) {
      issues.add(const ReportValidationIssue(
        field: 'officialUrl',
        message: 'Validation Failed: Official URL is not a recognised URL.',
      ));
    }

    // Duplicate detection.
    for (final exist in existingIndices) {
      if (exist.id != object.id && exist.indexName == object.indexName) {
        issues.add(ReportValidationIssue(
          field: 'duplicate',
          message:
              'Validation Failed: Duplicate index detected with matching name "${exist.indexName}".',
        ));
        break;
      }
    }

    // Broken report references.
    if (knownReports.isNotEmpty) {
      final knownIds = knownReports.map((r) => r.id).toSet();
      for (final ref in object.relatedReportIds) {
        if (!knownIds.contains(ref)) {
          issues.add(ReportValidationIssue(
            field: 'relatedReportIds',
            message:
                'Validation Failed: Broken reference - Report "$ref" not found in the library.',
            isBlocking: false,
          ));
        }
      }
    }

    if (object.evidenceIds.isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'evidenceIds',
        message: 'Validation Failed: Evidence attachment is missing for the index.',
      ));
    }

    return ReportValidationReport(
      isValid: issues.every((i) => !i.isBlocking),
      issues: issues,
    );
  }

  /// Validates a Survey Knowledge Object for publication-readiness.
  static ReportValidationReport validateSurvey(
    SurveyKnowledgeObject object, {
    List<SurveyKnowledgeObject> existingSurveys = const [],
    List<ReportKnowledgeObject> knownReports = const [],
  }) {
    final issues = <ReportValidationIssue>[];

    if (object.id.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'id',
        message: 'Validation Failed: Survey ID cannot be empty.',
      ));
    }

    if (object.officialTitle.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'officialTitle',
        message: 'Validation Failed: Survey title cannot be empty.',
      ));
    }

    if (object.publishingOrganisation.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'publishingOrganisation',
        message: 'Validation Failed: Publishing organisation is required.',
      ));
    }

    if (object.surveyYear <= 0) {
      issues.add(const ReportValidationIssue(
        field: 'surveyYear',
        message: 'Validation Failed: Survey year is required.',
      ));
    } else if (object.surveyYear > DateTime.now().year + 1) {
      issues.add(const ReportValidationIssue(
        field: 'surveyYear',
        message: 'Validation Failed: Survey year cannot be in the future.',
      ));
    }

    if (object.officialUrl.trim().isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'officialUrl',
        message: 'Validation Failed: Missing official URL.',
      ));
    } else if (!(object.officialUrl.startsWith('http://') ||
        object.officialUrl.startsWith('https://'))) {
      issues.add(const ReportValidationIssue(
        field: 'officialUrl',
        message: 'Validation Failed: Official URL is not a recognised URL.',
      ));
    }

    if (object.evidenceIds.isEmpty) {
      issues.add(const ReportValidationIssue(
        field: 'evidenceIds',
        message:
            'Validation Failed: Evidence attachment is missing for the survey.',
      ));
    }

    return ReportValidationReport(
      isValid: issues.every((i) => !i.isBlocking),
      issues: issues,
    );
  }

  /// Whether an indicator value is a plausible numeric figure. Accepts
  /// thousands separators and decimal points (e.g. "35.5", "3,773", "0.644").
  static bool _isPlausibleIndicatorValue(String value) {
    final cleaned = value.replaceAll(RegExp(r'[, ]'), '');
    return RegExp(r'^[+-]?\d+(\.\d+)?$').hasMatch(cleaned);
  }

  /// Adds a non-blocking issue for every reference not present in the known
  /// cross-package identifier set. An empty known set means the caller does not
  /// provide external-package data, so references are not checked.
  static void _checkBrokenReferences(
    List<String> references,
    Set<String> knownIds,
    String field,
    List<ReportValidationIssue> issues,
  ) {
    if (knownIds.isEmpty) return;
    for (final ref in references) {
      if (ref.trim().isNotEmpty && !knownIds.contains(ref.trim())) {
        issues.add(ReportValidationIssue(
          field: field,
          message:
              'Validation Failed: Broken reference - "$ref" not found in the GARUDA library.',
          isBlocking: false,
        ));
      }
    }
  }
}
