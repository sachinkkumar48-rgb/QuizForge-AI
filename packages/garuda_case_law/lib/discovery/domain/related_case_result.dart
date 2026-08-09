/// Related-case result model for P9 Case Discovery & Exploration
/// (TITAN-KO-015.0 P9).
///
/// A case discovered as related to a source case. "Related" is a precise,
/// evidence-backed claim: the case shares at least one validated graph
/// relationship, doctrine, article or Act with the source case, and every
/// connection is recorded on [reasons]. P9 never claims legal similarity — see
/// `P9_CASE_DISCOVERY.md`.
library;

import 'package:meta/meta.dart';

import '../../domain/entities/case_knowledge_object.dart';
import 'discovery_reason.dart';

/// An immutable related-case discovery hit.
@immutable
class RelatedCaseResult {
  /// Canonical ID of the case the discovery started from.
  final String sourceCaseId;

  /// Canonical corpus ID of the discovered case.
  final String caseId;

  /// Display case name of the discovered case.
  final String caseName;

  /// Judgment year of the discovered case (used for deterministic ordering).
  final int year;

  /// Evidence-backed reasons this case was returned, in a fixed, deterministic
  /// order (graph relationships first, then shared doctrine, shared article,
  /// shared Act; lexicographic within each kind). Never empty.
  final List<DiscoveryReason> reasons;

  /// The full validated case record (never fabricated).
  final CaseKnowledgeObject caseObject;

  const RelatedCaseResult({
    required this.sourceCaseId,
    required this.caseId,
    required this.caseName,
    required this.year,
    required this.reasons,
    required this.caseObject,
  }) : assert(reasons.length > 0, 'a related result needs at least one reason');

  Map<String, dynamic> toJson() => {
        'sourceCaseId': sourceCaseId,
        'caseId': caseId,
        'caseName': caseName,
        'year': year,
        'reasons': reasons.map((r) => r.toJson()).toList(),
        'caseObject': caseObject.toJson(),
      };

  factory RelatedCaseResult.fromJson(Map<String, dynamic> json) =>
      RelatedCaseResult(
        sourceCaseId: json['sourceCaseId'] as String? ?? '',
        caseId: json['caseId'] as String? ?? '',
        caseName: json['caseName'] as String? ?? '',
        year: json['year'] as int? ?? 0,
        reasons: (json['reasons'] as List<dynamic>? ?? const [])
            .map((e) => DiscoveryReason.fromJson(e as Map<String, dynamic>))
            .toList(),
        caseObject: CaseKnowledgeObject.fromJson(
          json['caseObject'] as Map<String, dynamic>,
        ),
      );

  /// The distinct reason kinds on this result, in discovery priority order.
  List<DiscoveryReasonType> get reasonTypes =>
      reasons.map((r) => r.type).toSet().toList(growable: false);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelatedCaseResult &&
          sourceCaseId == other.sourceCaseId &&
          caseId == other.caseId;

  @override
  int get hashCode => Object.hash(sourceCaseId, caseId);

  @override
  String toString() =>
      'RelatedCaseResult($sourceCaseId -> $caseId, ${reasons.length} reason${reasons.length == 1 ? '' : 's'})';
}
