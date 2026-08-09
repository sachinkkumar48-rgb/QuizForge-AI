/// Discovery reason model for P9 Case Discovery & Exploration
/// (TITAN-KO-015.0 P9).
///
/// Every discovered result is accompanied by reasons that explain WHY it was
/// returned. A reason always traces back to validated P3–P7 data:
///
/// - [DiscoveryReasonType.graphRelationship] — a direct, evidence-backed P5
///   case → case edge (a precedent relationship or a curated affinity).
/// - [DiscoveryReasonType.sharedDoctrine] — both cases engage the same
///   validated Constitutional Doctrine (P5 case ↔ doctrine edges).
/// - [DiscoveryReasonType.sharedArticle] — both cases reference the same
///   constitutional Article (P3 `relatedArticles`).
/// - [DiscoveryReasonType.sharedAct] — both cases reference the same Act
///   (P3 `relatedActs`).
///
/// P9 never invents reasons. Legal similarity, wording overlap, holdings
/// similarity and citations are NOT discovery reasons — there is no
/// [DiscoveryReasonType] for them and none is ever produced.
library;

import 'package:meta/meta.dart';

/// What kind of validated evidence establishes a related-case reason.
enum DiscoveryReasonType {
  /// A direct P5 case → case graph edge (precedent or curated affinity).
  graphRelationship,

  /// Both cases engage the same validated doctrine.
  sharedDoctrine,

  /// Both cases reference the same constitutional article.
  sharedArticle,

  /// Both cases reference the same Act.
  sharedAct,
}

/// An immutable, evidence-backed explanation of why a case was discovered.
@immutable
class DiscoveryReason {
  /// Kind of validated evidence behind this reason.
  final DiscoveryReasonType type;

  /// Short human-readable statement of the reason (e.g. `shared article: 21`).
  final String label;

  /// Canonical identifiers that establish the reason. Never empty. Content
  /// depends on [type]:
  ///
  /// - graph: `[edgeId, otherCaseId, relationshipTypeName]`
  /// - doctrine: `[doctrineId]`
  /// - article: `[normalizedArticleKey]`
  /// - act: `[normalizedActName]`
  final List<String> references;

  /// Provenance of the derivation — which validated corpus field or graph edge
  /// establishes it (e.g. `corpus:precedentsFollowed`,
  /// `corpus:relatedArticles`, `doctrine:BASIC_STRUCTURE.landmarkCases`).
  final String provenance;

  const DiscoveryReason({
    required this.type,
    required this.label,
    required this.references,
    required this.provenance,
  }) : assert(references.length > 0, 'a discovery reason needs references');

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'label': label,
        'references': references,
        'provenance': provenance,
      };

  factory DiscoveryReason.fromJson(Map<String, dynamic> json) =>
      DiscoveryReason(
        type: DiscoveryReasonType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => DiscoveryReasonType.graphRelationship,
        ),
        label: json['label'] as String? ?? '',
        references: (json['references'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        provenance: json['provenance'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveryReason &&
          type == other.type &&
          label == other.label &&
          provenance == other.provenance &&
          _listEquals(references, other.references);

  @override
  int get hashCode =>
      Object.hash(type, label, provenance, Object.hashAll(references));

  @override
  String toString() => '[$type] $label (provenance: $provenance)';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
