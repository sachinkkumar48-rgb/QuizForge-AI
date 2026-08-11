/// P14-local mapping validation (TITAN-KO-015.0 P14).
///
/// P14 performs its OWN mapping validation; it deliberately does not extend P7
/// (which validates the case-law corpus, not the pedagogical topic mapping). The
/// validator checks the P14 syllabus configuration against the validated corpus:
///
/// - every mapped topic is canonical;
/// - every membership topic ID is canonical;
/// - every referenced case exists in the corpus (no orphaned mapping);
/// - every membership cites a supported signal field;
/// - the cited signal value is genuinely present, verbatim, in the cited field
///   on the case (membership is evidence-bounded);
/// - the topic's syllabus area is present in the case's validated P4
///   `relatedSyllabusAreas` (a case grouped under GS Paper III must carry GS
///   Paper III in its own P4 data);
/// - no duplicate / conflicting mapping;
/// - deterministic ordering (topics sorted, member case IDs sorted);
/// - built products carry non-empty provenance and source references, and no
///   product references an unknown case.
///
/// Severity mirrors P7: `error` (genuine mapping defect that must fail the run),
/// `warning` (intentional or reviewable characteristic), `info` (informational).
library;

import 'package:meta/meta.dart';

import '../../domain/entities/case_knowledge_object.dart';
import '../domain/topic_membership.dart';
import '../service/topic_knowledge_product_service.dart';

/// Severity of a P14 mapping validation issue.
enum TopicMappingSeverity { error, warning, info }

/// A single P14 mapping validation issue.
@immutable
class TopicMappingValidationIssue {
  /// Stable machine-readable code (e.g. `orphan-case`, `unknown-signal-field`).
  final String code;

  /// Human-readable description.
  final String message;

  /// topic ID / case ID / doctrine ID / provision ID / signal field, or '' for
  /// config-global issues.
  final String subject;

  final TopicMappingSeverity severity;

  const TopicMappingValidationIssue({
    required this.code,
    required this.message,
    this.subject = '',
    this.severity = TopicMappingSeverity.error,
  });

  bool get isError => severity == TopicMappingSeverity.error;
  bool get isWarning => severity == TopicMappingSeverity.warning;
  bool get isInfo => severity == TopicMappingSeverity.info;

  @override
  String toString() =>
      '[${severity.name}] $code${subject.isEmpty ? '' : ' ($subject)'}: '
      '$message';
}

/// The P14 mapping validation result.
@immutable
class TopicMappingValidationResult {
  /// True when no `error`-severity issue was found.
  final bool isValid;

  final List<TopicMappingValidationIssue> issues;

  const TopicMappingValidationResult({
    required this.isValid,
    this.issues = const [],
  });

  factory TopicMappingValidationResult.success() =>
      const TopicMappingValidationResult(isValid: true);

  bool get hasErrors => issues.any((i) => i.isError);
  bool get hasWarnings => issues.any((i) => i.isWarning);

  List<TopicMappingValidationIssue> get errors =>
      issues.where((i) => i.isError).toList(growable: false);
  List<TopicMappingValidationIssue> get warnings =>
      issues.where((i) => i.isWarning).toList(growable: false);
  List<TopicMappingValidationIssue> get infos =>
      issues.where((i) => i.isInfo).toList(growable: false);
}

/// P14-local validator of the topic syllabus configuration against the corpus.
@immutable
class TopicMappingValidator {
  final TopicKnowledgeProductService service;

  /// Builds a validator over the shared corpus/services (defaults to the
  /// canonical offline corpus — deterministic and offline-first).
  factory TopicMappingValidator({TopicKnowledgeProductService? service}) =>
      TopicMappingValidator._(service ?? TopicKnowledgeProductService());

  const TopicMappingValidator._(this.service);

  /// Validates the syllabus configuration against the corpus: topic identity,
  /// membership signals, case existence, area consistency, duplicates,
  /// determinism. Reports unmapped cases as informational.
  TopicMappingValidationResult validate() {
    final issues = <TopicMappingValidationIssue>[];
    final config = service.config;
    final caseById = {for (final c in service.cases) c.caseId: c};

    // --- Canonical topics --------------------------------------------------
    final topicIds = config.topicIds;
    final isSorted = List<String>.from(topicIds)..sort();
    if (topicIds.join(',') != isSorted.join(',')) {
      issues.add(const TopicMappingValidationIssue(
        code: 'unordered-topics',
        message: 'Topic IDs must be sorted for deterministic output.',
      ));
    }

    // --- Membership checks (iterate ALL memberships, not just canonical
    // topics, so a membership referencing an unknown topic is still examined)
    // ------------------------------------------------------------------------
    final seenMemberships = <String>{};
    final mappedCaseTopics = <String, Set<String>>{};

    for (final m in config.memberships) {
      final key = '${m.topicId}|${m.caseId}|${m.signalField}|${m.signalValue}';
      if (!seenMemberships.add(key)) {
        issues.add(TopicMappingValidationIssue(
          code: 'duplicate-membership',
          message: 'Duplicate membership (same topic, case, signal field and '
              'value).',
          subject: '${m.topicId}:${m.caseId}',
        ));
        continue;
      }
      final identity = config.identityFor(m.topicId);
      if (identity == null) {
        issues.add(TopicMappingValidationIssue(
          code: 'unknown-topic',
          message: 'Membership references a topic ID that does not resolve to '
              'a canonical topic.',
          subject: '${m.topicId}:${m.caseId}',
        ));
        continue;
      }
      final c = caseById[m.caseId];
      if (c == null) {
        issues.add(TopicMappingValidationIssue(
          code: 'orphan-case',
          message: 'Mapped case does not exist in the corpus.',
          subject: '${m.topicId}:${m.caseId}',
        ));
        continue;
      }
      if (!TopicSignalField.all.contains(m.signalField)) {
        issues.add(TopicMappingValidationIssue(
          code: 'unknown-signal-field',
          message: 'Membership cites an unsupported signal field.',
          subject: '${m.topicId}:${m.caseId} ${m.signalField}',
        ));
      } else if (!_signalPresent(c, m)) {
        issues.add(TopicMappingValidationIssue(
          code: 'missing-signal',
          message: 'Membership signal value is not present verbatim in the '
              'cited field on the case.',
          subject: '${m.topicId}:${m.caseId} '
              '(${m.signalField}: "${m.signalValue}")',
        ));
      }
      // Topic area must be present in the case's validated P4 syllabus areas
      // — but ONLY when the case carries area data. A case with no UPSC
      // intelligence at all (missing area data) is not a mismatch.
      final areas =
          c.judgmentIntelligence?.upscIntelligence?.relatedSyllabusAreas;
      final hasAreaData = areas != null && areas.isNotEmpty;
      if (hasAreaData && !areas.any((a) => a == identity.area)) {
        issues.add(TopicMappingValidationIssue(
          code: 'area-mismatch',
          message: 'Topic syllabus area (${identity.area.name}) is not '
              'present in the case\'s P4 relatedSyllabusAreas.',
          subject: '${m.topicId}:${m.caseId}',
        ));
      }
      mappedCaseTopics.putIfAbsent(m.caseId, () => <String>{}).add(m.topicId);
    }

    // --- Per-topic checks --------------------------------------------------
    for (final topicId in topicIds) {
      final memberships = config.membershipsForTopic(topicId);
      if (memberships.isEmpty) {
        issues.add(TopicMappingValidationIssue(
          code: 'empty-topic',
          message: 'Topic has no explicit membership.',
          subject: topicId,
          severity: TopicMappingSeverity.warning,
        ));
      }
      // Member case IDs must be sorted for deterministic output.
      final memberIds = config.memberCaseIdsFor(topicId);
      final sortedMemberIds = List<String>.from(memberIds)..sort();
      if (memberIds.join(',') != sortedMemberIds.join(',')) {
        issues.add(TopicMappingValidationIssue(
          code: 'unordered-members',
          message: 'Member case IDs must be sorted for deterministic output.',
          subject: topicId,
        ));
      }
    }

    // --- Unmapped cases (informational) ------------------------------------
    for (final c in service.cases) {
      if (!mappedCaseTopics.containsKey(c.caseId)) {
        issues.add(TopicMappingValidationIssue(
          code: 'unmapped-case',
          message: 'Case carries P4 UPSC data but is intentionally not mapped '
              'to any P14 topic.',
          subject: c.caseId,
          severity: TopicMappingSeverity.info,
        ));
      }
    }

    return TopicMappingValidationResult(
      isValid: issues.every((i) => !i.isError),
      issues: List.unmodifiable(issues),
    );
  }

  /// Validates the built topic products: every product resolves, every member
  /// case exists, no section is empty without cause, every statement carries
  /// non-empty source references and non-empty provenance, and no product
  /// references an unknown case.
  TopicMappingValidationResult validateProducts() {
    final issues = <TopicMappingValidationIssue>[];
    final corpusIds = {for (final c in service.cases) c.caseId};

    for (final p in service.buildAll()) {
      if (p.isEmpty) {
        issues.add(TopicMappingValidationIssue(
          code: 'empty-product',
          message: 'Topic product has no presentable sections.',
          subject: p.topicId,
        ));
      }
      for (final id in p.memberCaseIds) {
        if (!corpusIds.contains(id)) {
          issues.add(TopicMappingValidationIssue(
            code: 'product-unknown-case',
            message: 'Member case referenced by product is not in the corpus.',
            subject: '${p.topicId}:$id',
          ));
        }
      }
      for (final s in p.sections) {
        if (s.statements.isEmpty) {
          issues.add(TopicMappingValidationIssue(
            code: 'empty-section',
            message: 'Section has no statements (should be omitted).',
            subject: '${p.topicId}:${s.type.name}',
          ));
        }
        for (final st in s.statements) {
          if (st.sourceRefs.isEmpty) {
            issues.add(TopicMappingValidationIssue(
              code: 'missing-source-refs',
              message: 'Statement carries no source references.',
              subject: '${p.topicId}:${s.type.name}',
            ));
          }
          if (st.provenance.trim().isEmpty) {
            issues.add(TopicMappingValidationIssue(
              code: 'missing-provenance',
              message: 'Statement carries empty provenance.',
              subject: '${p.topicId}:${s.type.name}',
            ));
          }
        }
      }
    }

    return TopicMappingValidationResult(
      isValid: issues.every((i) => !i.isError),
      issues: List.unmodifiable(issues),
    );
  }

  /// Whether the cited [signalValue] is genuinely present, verbatim, in the
  /// cited [signalField] on [c]. Never matches partially and never falls back
  /// to inference.
  bool _signalPresent(CaseKnowledgeObject c, TopicMembership m) {
    final u = c.judgmentIntelligence?.upscIntelligence;
    switch (m.signalField) {
      case TopicSignalField.p3Themes:
        return c.themes.contains(m.signalValue);
      case TopicSignalField.p3Subjects:
        return c.subjects.contains(m.signalValue);
      case TopicSignalField.p4MainsThemes:
        return u?.mainsThemes.contains(m.signalValue) ?? false;
      case TopicSignalField.p4AnswerKeywords:
        return u?.answerKeywords.contains(m.signalValue) ?? false;
      case TopicSignalField.p4EssayThemes:
        return u?.essayThemes.contains(m.signalValue) ?? false;
      case TopicSignalField.p4SyllabusAreas:
        return u?.relatedSyllabusAreas.any((a) => a.name == m.signalValue) ??
            false;
      default:
        return false;
    }
  }
}
