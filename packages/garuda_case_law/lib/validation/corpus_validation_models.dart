/// Corpus-level validation models (TITAN-KO-015.0 P7).
///
/// Value-oriented, immutable models shared by the CorpusValidator and its
/// callers. Severity is three-valued (error / warning / info) so that genuine
/// corpus defects fail validation while characteristics that are intentional or
/// caused by partial cross-package coverage surface without failing the run.
library;

import 'package:meta/meta.dart';

/// Severity of a corpus validation issue.
enum CorpusValidationSeverity { error, warning, info }

/// Which layer of corpus integrity an issue concerns.
enum CorpusValidationCategory {
  identity,
  evidence,
  intelligence,
  article,
  act,
  doctrine,
  precedent,
  graph,
  serialization,
}

@immutable
class CorpusValidationIssue {
  final String code;
  final String message;

  /// Case ID, graph edge triple, or '' for corpus-global issues.
  final String subject;
  final CorpusValidationSeverity severity;
  final CorpusValidationCategory category;

  const CorpusValidationIssue({
    required this.code,
    required this.message,
    this.subject = '',
    this.severity = CorpusValidationSeverity.error,
    this.category = CorpusValidationCategory.identity,
  });

  bool get isError => severity == CorpusValidationSeverity.error;
  bool get isWarning => severity == CorpusValidationSeverity.warning;
  bool get isInfo => severity == CorpusValidationSeverity.info;

  @override
  String toString() =>
      '[${severity.name}] $code${subject.isEmpty ? '' : ' ($subject)'}: $message';
}

@immutable
class CorpusValidationResult {
  final bool isValid;
  final List<CorpusValidationIssue> issues;

  const CorpusValidationResult({required this.isValid, this.issues = const []});

  factory CorpusValidationResult.success() =>
      const CorpusValidationResult(isValid: true);

  factory CorpusValidationResult.failure(List<CorpusValidationIssue> issues) =>
      CorpusValidationResult(isValid: false, issues: issues);

  List<CorpusValidationIssue> get errors =>
      issues.where((i) => i.isError).toList(growable: false);

  List<CorpusValidationIssue> get warnings =>
      issues.where((i) => i.isWarning).toList(growable: false);

  List<CorpusValidationIssue> get infos =>
      issues.where((i) => i.isInfo).toList(growable: false);

  int get errorCount => errors.length;
  int get warningCount => warnings.length;
  int get infoCount => infos.length;

  /// Issues not resolved by the existing intelligence validator (i.e. the
  /// corpus-level evidence/intelligence subset checks).
  bool get hasEvidenceSubsetViolations => issues.any((i) =>
      i.code == 'INTEL_EVIDENCE_NOT_IN_CASE' ||
      i.code == 'INTEL_EVIDENCE_UNRESOLVED' ||
      i.code == 'EVIDENCE_UNRESOLVED');
}

/// Machine-readable corpus validation report. Prefer [CorpusValidationResult]
/// for programmatic consumers; this report is the human/CI-facing summary.
@immutable
class CorpusValidationReport {
  final int totalCases;
  final int validCases;
  final int invalidCases;
  final int errorCount;
  final int warningCount;
  final int infoCount;
  final List<CorpusValidationIssue> issues;

  /// Fraction of cases with a registered official evidence record (0..1).
  final double evidenceCoverage;

  /// Number of broken cross-package references found
  /// (article / act / doctrine / precedent / evidence).
  final int brokenReferenceCount;

  /// Whether the graph is a consistent, deterministic projection of the corpus.
  final bool graphConsistent;

  /// Whether every case's serialization round-trip was lossless.
  final bool serializationLossless;

  const CorpusValidationReport({
    required this.totalCases,
    required this.validCases,
    required this.invalidCases,
    required this.errorCount,
    required this.warningCount,
    required this.infoCount,
    required this.issues,
    required this.evidenceCoverage,
    required this.brokenReferenceCount,
    required this.graphConsistent,
    required this.serializationLossless,
  });

  bool get isValid => errorCount == 0;

  Map<String, dynamic> toJson() => {
        'totalCases': totalCases,
        'validCases': validCases,
        'invalidCases': invalidCases,
        'errorCount': errorCount,
        'warningCount': warningCount,
        'infoCount': infoCount,
        'issues': [
          for (final i in issues)
            {
              'code': i.code,
              'message': i.message,
              'subject': i.subject,
              'severity': i.severity.name,
              'category': i.category.name,
            },
        ],
        'evidenceCoverage': evidenceCoverage,
        'brokenReferenceCount': brokenReferenceCount,
        'graphConsistent': graphConsistent,
        'serializationLossless': serializationLossless,
        'isValid': isValid,
      };

  factory CorpusValidationReport.fromResult(
    CorpusValidationResult result, {
    required int totalCases,
    required double evidenceCoverage,
    required bool graphConsistent,
    required bool serializationLossless,
  }) {
    final invalidSubjects = result.errors
        .map((i) => i.subject)
        .where((s) => s.isNotEmpty)
        .toSet();
    return CorpusValidationReport(
      totalCases: totalCases,
      validCases: totalCases - invalidSubjects.length,
      invalidCases: invalidSubjects.length,
      errorCount: result.errorCount,
      warningCount: result.warningCount,
      infoCount: result.infoCount,
      issues: result.issues,
      evidenceCoverage: evidenceCoverage,
      brokenReferenceCount: result.issues
          .where((i) =>
              i.category == CorpusValidationCategory.article ||
              i.category == CorpusValidationCategory.act ||
              i.category == CorpusValidationCategory.doctrine ||
              i.category == CorpusValidationCategory.precedent ||
              (i.category == CorpusValidationCategory.evidence &&
                  i.code == 'EVIDENCE_UNRESOLVED'))
          .where((i) => i.isError)
          .length,
      graphConsistent: graphConsistent,
      serializationLossless: serializationLossless,
    );
  }
}
