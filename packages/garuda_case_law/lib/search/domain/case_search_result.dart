/// Case Law search result model (TITAN-KO-015.0 P6).
///
/// One ranked hit for a single case. It carries everything a future UI needs
/// to render a result without re-querying the corpus: the full case record,
/// the deterministic relevance score, the fields that matched, a small
/// matched-text context map, and the record's evidence posture. `case` is a
/// Dart reserved word, so the record is exposed as [caseObject].
library;

import 'package:meta/meta.dart';

import '../../domain/entities/case_knowledge_object.dart';
import 'case_search_enums.dart';

/// A ranked search hit for one landmark case.
@immutable
class CaseSearchResult {
  /// Canonical corpus case ID (e.g. `KESAVANANDA`).
  final String caseId;

  /// Display case name (e.g. `Kesavananda Bharati v. State of Kerala`).
  final String caseName;

  /// Deterministic relevance score (higher = more relevant). The exact number
  /// depends on which fields matched; see the engine docs for the weights.
  final double score;

  /// Names of the fields that matched, sorted and de-duplicated
  /// (e.g. `caseName`, `article`, `upsc`).
  final List<String> matchedFields;

  /// Matched text by field name, capped per field, used to render context.
  final Map<String, List<String>> matchedContext;

  /// Evidence posture of the record (never fabricated by search).
  final SearchEvidenceStatus evidenceStatus;

  /// The full underlying case record.
  final CaseKnowledgeObject caseObject;

  const CaseSearchResult({
    required this.caseId,
    required this.caseName,
    required this.score,
    required this.matchedFields,
    required this.matchedContext,
    required this.evidenceStatus,
    required this.caseObject,
  });

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'caseName': caseName,
        'score': score,
        'matchedFields': matchedFields,
        'matchedContext': matchedContext,
        'evidenceStatus': evidenceStatus.name,
        'caseObject': caseObject.toJson(),
      };

  factory CaseSearchResult.fromJson(Map<String, dynamic> json) =>
      CaseSearchResult(
        caseId: json['caseId'] as String? ?? '',
        caseName: json['caseName'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        matchedFields:
            (json['matchedFields'] as List? ?? const []).cast<String>(),
        matchedContext: (json['matchedContext'] as Map? ?? const {})
            .map((k, v) => MapEntry(
                k as String, (v as List).cast<String>())),
        evidenceStatus: SearchEvidenceStatus.values.firstWhere(
          (e) => e.name == json['evidenceStatus'],
          orElse: () => SearchEvidenceStatus.unverified,
        ),
        caseObject: CaseKnowledgeObject.fromJson(
            json['caseObject'] as Map<String, dynamic>),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseSearchResult && caseId == other.caseId;

  @override
  int get hashCode => caseId.hashCode;

  @override
  String toString() =>
      'CaseSearchResult($caseId, score: ${score.toStringAsFixed(2)})';
}
