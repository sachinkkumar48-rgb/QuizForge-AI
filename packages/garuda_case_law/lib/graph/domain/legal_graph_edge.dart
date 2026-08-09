/// Edge model for the Precedent & Doctrine Graph (TITAN-KO-015.0 P5).
///
/// Every edge is evidence-backed: it records where the relationship is
/// established (provenance), the evidence references that support it, and a
/// confidence/verification posture. An edge is only present because the
/// verified corpus (or the canonical `garuda_doctrine` record) establishes it —
/// never to inflate graph density.
library;

import 'package:meta/meta.dart';

import '../../domain/entities/case_enums.dart' show PrecedentRelationshipType;
import 'doctrine_relationship_type.dart';
import 'legal_graph_node_type.dart';

/// Base class of a typed, evidence-backed edge in the legal graph.
///
/// Sealed so the graph can be exhaustive about which node types an edge may
/// connect:
/// - [PrecedentGraphEdge] connects a case node to another case node.
/// - [DoctrineGraphEdge] connects a case node to a doctrine node.
@immutable
sealed class LegalGraphEdge {
  /// Canonical ID of the source node.
  final String sourceId;

  /// Canonical ID of the target node.
  final String targetId;

  /// Evidence references supporting this relationship.
  ///
  /// Case edges resolve against the official-source registry
  /// (`ev_<caseId>_official`); doctrine edges additionally resolve against the
  /// doctrine record reference lists.
  final List<String> evidenceIds;

  /// Where the relationship is established, e.g. `corpus:precedentsFollowed`,
  /// `corpus:relatedCases` or `doctrine:BASIC_STRUCTURE.landmarkCases`.
  final String provenance;

  /// Confidence in the relationship, in `(0.0, 1.0]`.
  final double confidence;

  /// Whether the relationship traces to a registered, authoritative source.
  final bool verified;

  /// Optional justification / caveat.
  final String? note;

  const LegalGraphEdge({
    required this.sourceId,
    required this.targetId,
    required this.evidenceIds,
    required this.provenance,
    required this.confidence,
    required this.verified,
    this.note,
  });

  /// The kind of node this edge originates from.
  LegalGraphNodeType get sourceNodeType;

  /// The kind of node this edge points to.
  LegalGraphNodeType get targetNodeType;

  /// Stable, graph-unique label for the relationship type.
  String get typeLabel;

  /// Deterministic identity of the (source, type, target) triple. Used for
  /// duplicate-edge detection and de-duplication.
  String get tripleKey => '$sourceId|$typeLabel|$targetId';

  /// Stable identifier for this edge instance.
  String get edgeId => 'e:$tripleKey';

  /// Category tag used by serialization to reconstruct the concrete type.
  String get category;

  bool get isCaseCaseEdge => this is PrecedentGraphEdge;

  bool get isCaseDoctrineEdge => this is DoctrineGraphEdge;

  Map<String, dynamic> toJson() => {
        'edgeId': edgeId,
        'category': category,
        'sourceId': sourceId,
        'targetId': targetId,
        'typeLabel': typeLabel,
        'evidenceIds': evidenceIds,
        'provenance': provenance,
        'confidence': confidence,
        'verified': verified,
        if (note != null) 'note': note,
      };

  /// Reconstructs the correct concrete edge from its serialized form.
  static LegalGraphEdge fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String? ?? '';
    if (category == 'precedent') {
      return PrecedentGraphEdge(
        sourceId: json['sourceId'] as String? ?? '',
        targetId: json['targetId'] as String? ?? '',
        type: PrecedentRelationshipType.values.firstWhere(
          (e) => e.name == json['typeLabel'],
          orElse: () => PrecedentRelationshipType.followed,
        ),
        evidenceIds:
            (json['evidenceIds'] as List? ?? const []).cast<String>(),
        provenance: json['provenance'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
        verified: json['verified'] as bool? ?? false,
        note: json['note'] as String?,
      );
    }
    return DoctrineGraphEdge(
      sourceId: json['sourceId'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      type: DoctrineRelationshipType.values.firstWhere(
        (e) => e.name == json['typeLabel'],
        orElse: () => DoctrineRelationshipType.engages,
      ),
      evidenceIds: (json['evidenceIds'] as List? ?? const []).cast<String>(),
      provenance: json['provenance'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      verified: json['verified'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }
}

/// A case → case precedent edge (TITAN-KO-015.0 P5).
///
/// Reuses the existing legal vocabulary from
/// `PrecedentRelationshipType` (`followed`, `overruled`, `distinguished`,
/// `related`, `applied`, ...).
@immutable
class PrecedentGraphEdge extends LegalGraphEdge {
  final PrecedentRelationshipType type;

  const PrecedentGraphEdge({
    required super.sourceId,
    required super.targetId,
    required this.type,
    super.evidenceIds = const [],
    super.provenance = 'corpus:precedent',
    super.confidence = 1.0,
    super.verified = true,
    super.note,
  });

  @override
  LegalGraphNodeType get sourceNodeType => LegalGraphNodeType.caseLaw;

  @override
  LegalGraphNodeType get targetNodeType => LegalGraphNodeType.caseLaw;

  @override
  String get typeLabel => type.name;

  @override
  String get category => 'precedent';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrecedentGraphEdge &&
          sourceId == other.sourceId &&
          targetId == other.targetId &&
          type == other.type;

  @override
  int get hashCode => Object.hash(sourceId, targetId, type);
}

/// A case → doctrine edge (TITAN-KO-015.0 P5).
///
/// Uses the [DoctrineRelationshipType] vocabulary, with roles only recorded
/// where the case record or the canonical doctrine record establishes them.
@immutable
class DoctrineGraphEdge extends LegalGraphEdge {
  final DoctrineRelationshipType type;

  const DoctrineGraphEdge({
    required super.sourceId,
    required super.targetId,
    required this.type,
    super.evidenceIds = const [],
    super.provenance = 'corpus:doctrine',
    super.confidence = 1.0,
    super.verified = true,
    super.note,
  });

  @override
  LegalGraphNodeType get sourceNodeType => LegalGraphNodeType.caseLaw;

  @override
  LegalGraphNodeType get targetNodeType => LegalGraphNodeType.doctrine;

  @override
  String get typeLabel => type.name;

  @override
  String get category => 'doctrine';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctrineGraphEdge &&
          sourceId == other.sourceId &&
          targetId == other.targetId &&
          type == other.type;

  @override
  int get hashCode => Object.hash(sourceId, targetId, type);
}
