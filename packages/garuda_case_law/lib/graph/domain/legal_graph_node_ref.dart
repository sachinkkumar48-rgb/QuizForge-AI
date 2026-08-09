/// Node reference model for the Precedent & Doctrine Graph
/// (TITAN-KO-015.0 P5).
///
/// A node is a canonical, evidence-backed reference: case nodes use the corpus
/// `caseId`, doctrine nodes use the `garuda_doctrine` `doctrineId`. Node
/// identity is the canonical ID — no graph-local aliases are introduced.
library;

import 'package:meta/meta.dart';

import 'legal_graph_node_type.dart';

/// Immutable reference to a node in the legal graph.
@immutable
class LegalGraphNodeRef {
  /// Canonical node identifier.
  ///
  /// For case nodes this is the corpus `caseId` (e.g. `KESAVANANDA`); for
  /// doctrine nodes this is the canonical `garuda_doctrine` `doctrineId`
  /// (e.g. `BASIC_STRUCTURE`).
  final String id;

  /// Human-readable node name (case name / doctrine name).
  final String name;

  /// Kind of node (case or doctrine).
  final LegalGraphNodeType nodeType;

  /// Optional display attributes (year, citation, category) used by the UI.
  final Map<String, dynamic> attributes;

  const LegalGraphNodeRef({
    required this.id,
    required this.name,
    required this.nodeType,
    this.attributes = const {},
  });

  /// The unique key for this node across the whole graph.
  String get nodeKey => nodeType.name == LegalGraphNodeType.caseLaw.name
      ? 'case:$id'
      : 'doctrine:$id';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nodeType': nodeType.name,
        'attributes': attributes,
      };

  factory LegalGraphNodeRef.fromJson(Map<String, dynamic> json) =>
      LegalGraphNodeRef(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        nodeType: LegalGraphNodeType.values.firstWhere(
          (e) => e.name == json['nodeType'],
          orElse: () => LegalGraphNodeType.caseLaw,
        ),
        attributes:
            Map<String, dynamic>.from(json['attributes'] as Map? ?? const {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegalGraphNodeRef &&
          id == other.id &&
          nodeType == other.nodeType;

  @override
  int get hashCode => Object.hash(id, nodeType);

  @override
  String toString() => 'LegalGraphNodeRef(${nodeType.name}:$id)';
}
