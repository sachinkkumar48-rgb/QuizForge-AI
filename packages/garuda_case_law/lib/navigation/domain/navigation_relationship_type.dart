/// Relationship vocabulary for the Knowledge Product Navigator
/// (TITAN-KO-015.0 P16).
///
/// Every navigation edge P16 emits maps to one concrete, explainable
/// relationship kind backed by an existing validated source. There is no
/// generic "related" / "similar" / "connected" edge: each kind names exactly
/// where the relationship is established and preserves its semantics verbatim.
library;

import '../../domain/entities/case_enums.dart' show PrecedentRelationshipType;
import '../../graph/domain/doctrine_relationship_type.dart';

/// The concrete kinds of navigation relationship P16 may emit.
///
/// Each member records:
/// - whether it is a *legal* relationship (a P5 graph edge) or a *non-legal*
///   association (a provision reference, a pedagogical topic membership) — this
///   keeps legal precedent distinct from mere grouping;
/// - the provenance prefix that documents where the edge comes from.
enum NavigationRelationshipType {
  /// The queried entity's own knowledge product (the root of a result set).
  ///
  /// This is not a relationship between two different entities; it anchors a
  /// navigation result at the entity's primary product so that a result set
  /// always contains the entity's own product. Provenance names the product
  /// service that produced it.
  primary,

  /// A P5 case → case precedent edge (e.g. `followed`, `overruled`,
  /// `distinguished`, `related`).
  ///
  /// Direction, relationship type and edge identity/provenance are preserved
  /// verbatim from the P5 `PrecedentGraphEdge`. This IS a legal relationship.
  precedent,

  /// A P5 case ↔ doctrine edge (e.g. `establishes`, `applies`, `develops`,
  /// `engages`).
  ///
  /// Preserved verbatim from the P5 `DoctrineGraphEdge`. This IS a legal
  /// relationship.
  engagesDoctrine,

  /// A case's verified reference to a constitutional Article / Act / section.
  ///
  /// Sourced from the same validated P3/P13 provision-association mechanism the
  /// P13 `StatuteKnowledgeProductService` uses (`provisionRefMap`), never from
  /// a fabricated P5 edge. This is a provision association, not a precedent.
  referencesProvision,

  /// A case's explicit P14 pedagogical membership of a UPSC topic.
  ///
  /// Sourced verbatim from the validated P14 `TopicSyllabusConfig` memberships.
  /// Topic membership is a pedagogical grouping and is NOT a legal
  /// relationship; it is never confused with a P5 precedent.
  topicMembership,

  /// A P15 `QuestionKnowledgeProduct` re-presenting its validated source.
  ///
  /// Sourced from the P15 question product's own `sourceType` / `sourceId`.
  /// The direction is from the source entity to its question product.
  questionSource,
}

extension NavigationRelationshipTypeExtension on NavigationRelationshipType {
  /// Whether this edge expresses a legal relationship (a P5 graph edge).
  bool get isLegalRelationship => switch (this) {
        NavigationRelationshipType.precedent ||
        NavigationRelationshipType.engagesDoctrine =>
          true,
        _ => false,
      };

  /// Deterministic human-readable label for the relationship kind.
  String get displayTitle => switch (this) {
        NavigationRelationshipType.primary => 'Primary product',
        NavigationRelationshipType.precedent => 'Precedent',
        NavigationRelationshipType.engagesDoctrine => 'Engages doctrine',
        NavigationRelationshipType.referencesProvision =>
          'References provision',
        NavigationRelationshipType.topicMembership => 'Topic membership',
        NavigationRelationshipType.questionSource => 'Question source',
      };

  /// The stable provenance prefix recorded on references of this kind.
  String get provenancePrefix => switch (this) {
        NavigationRelationshipType.primary => 'p16:primary',
        NavigationRelationshipType.precedent => 'p5:precedentGraph',
        NavigationRelationshipType.engagesDoctrine => 'p5:doctrineGraph',
        NavigationRelationshipType.referencesProvision => 'p13:provisionRefMap',
        NavigationRelationshipType.topicMembership => 'p14:membership',
        NavigationRelationshipType.questionSource => 'p15:questionProduct',
      };

  /// Whether a `specificTypeLabel` is expected for references of this kind.
  bool get carriesSpecificType => switch (this) {
        NavigationRelationshipType.precedent ||
        NavigationRelationshipType.engagesDoctrine =>
          true,
        _ => false,
      };

  /// Parses a relationship type from its serialized enum name, defaulting to
  /// [NavigationRelationshipType.primary] for unknown values.
  static NavigationRelationshipType fromName(String? name) =>
      NavigationRelationshipType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => NavigationRelationshipType.primary,
      );
}

/// Constants describing the P5 relationship type names P16 preserves.
///
/// P16 does not define these; it only references the P5 vocabulary so that the
/// `specificTypeLabel` on references stays stable and auditable.
abstract final class P5RelationshipTypeLabel {
  /// A case → case precedent type name (e.g. `PrecedentRelationshipType.followed.name`).
  static String precedent(PrecedentRelationshipType t) => t.name;

  /// A case ↔ doctrine type name (e.g. `DoctrineRelationshipType.engages.name`).
  static String doctrine(DoctrineRelationshipType t) => t.name;
}
