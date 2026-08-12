/// KnowledgeProductReference for the Knowledge Product Navigator
/// (TITAN-KO-015.0 P16).
///
/// An immutable value object representing one navigable edge from an origin
/// knowledge product to a destination knowledge product. Every reference
/// carries enough provenance to answer **why the navigation edge exists**: the
/// concrete [relationshipType], the [provenance] source, the [evidenceRefs]
/// (edge ID / provision key / membership signal) and the origin/destination
/// product identities. There is no generic "related" edge — every relationship
/// traces to an existing validated source.
///
/// P16 is a read/composition layer: a reference never mutates the P5 graph and
/// never invents a destination. A destination is emitted only when it resolves
/// to an existing knowledge product produced by the P11–P15 services.
library;

import 'package:meta/meta.dart';

import '../../domain/entities/case_enums.dart' show PrecedentRelationshipType;
import '../../graph/domain/doctrine_relationship_type.dart';
import '../../statute_product/domain/statute_product_enums.dart'
    show ProvisionType;
import 'knowledge_product_type.dart';
import 'navigation_direction.dart';
import 'navigation_relationship_type.dart';

/// An immutable, evidence-backed reference to a destination knowledge product.
@immutable
class KnowledgeProductReference {
  /// Kind of the origin product (the entity the query started from).
  final KnowledgeProductType originProductType;

  /// Canonical ID of the origin product (case ID, doctrine ID, provision key,
  /// topic ID or question product ID).
  final String originProductId;

  /// Kind of the destination product.
  final KnowledgeProductType toProductType;

  /// Canonical ID of the destination product (case ID, doctrine ID, provision
  /// key, topic ID or question product ID).
  final String toProductId;

  /// Display name of the destination product.
  final String toProductName;

  /// The provision kind, set only when [toProductType] is
  /// [KnowledgeProductType.provision]. A provision is identified by
  /// `(ProvisionType, provision key)`, so the key alone is not sufficient to
  /// resolve the product.
  final ProvisionType? provisionType;

  /// The concrete relationship kind of this navigation edge.
  final NavigationRelationshipType relationshipType;

  /// The exact P5 relationship type label (e.g. `followed`, `overruled`,
  /// `establishes`, `engages`), preserved verbatim. Empty when the
  /// relationship carries no P5 type.
  final String specificTypeLabel;

  /// Direction of the edge relative to the origin. Null for non-directional
  /// relationships (e.g. the primary product).
  final NavigationDirection? direction;

  /// Where the relationship is established (e.g.
  /// `p5:precedentGraph`, `p13:provisionRefMap`, `p14:membership`).
  final String provenance;

  /// Evidence references supporting the edge: a P5 edge ID, the provision key /
  /// raw reference, a P14 membership signal or a P15 product reference. May be
  /// empty only for the [NavigationRelationshipType.primary] root reference.
  final List<String> evidenceRefs;

  /// Publication year of a destination case product, used only for
  /// deterministic chronological ordering. Null for non-case products.
  final int? toProductYear;

  KnowledgeProductReference({
    required this.originProductType,
    required this.originProductId,
    required this.toProductType,
    required this.toProductId,
    required this.toProductName,
    this.provisionType,
    required this.relationshipType,
    this.specificTypeLabel = '',
    this.direction,
    required this.provenance,
    this.evidenceRefs = const [],
    this.toProductYear,
  })  : assert(toProductId.trim().isNotEmpty,
            'a reference needs a destination ID'),
        assert(provenance.trim().isNotEmpty, 'a reference needs provenance'),
        assert(
          toProductType != KnowledgeProductType.provision ||
              provisionType != null,
          'a provision reference needs a provisionType',
        ),
        assert(
          toProductType == KnowledgeProductType.provision ||
              provisionType == null,
          'provisionType is only valid for provision references',
        );

  /// Whether this is the root (primary) reference of a navigation result.
  bool get isPrimary => relationshipType == NavigationRelationshipType.primary;

  /// The deduplication key of this edge: the same logical destination reached
  /// through the same relationship is a duplicate.
  String get dedupKey =>
      '${toProductType.name}|$toProductId|${provisionType?.name ?? ''}|'
      '${relationshipType.name}|$specificTypeLabel|${direction?.name ?? ''}';

  /// The concrete P5 precedent type, when [relationshipType] is
  /// [NavigationRelationshipType.precedent].
  PrecedentRelationshipType? get precedentType =>
      relationshipType == NavigationRelationshipType.precedent &&
              specificTypeLabel.isNotEmpty
          ? PrecedentRelationshipType.values.firstWhere(
              (t) => t.name == specificTypeLabel,
              orElse: () => PrecedentRelationshipType.related,
            )
          : null;

  /// The concrete P5 doctrine role, when [relationshipType] is
  /// [NavigationRelationshipType.engagesDoctrine].
  DoctrineRelationshipType? get doctrineType =>
      relationshipType == NavigationRelationshipType.engagesDoctrine &&
              specificTypeLabel.isNotEmpty
          ? DoctrineRelationshipType.values.firstWhere(
              (t) => t.name == specificTypeLabel,
              orElse: () => DoctrineRelationshipType.engages,
            )
          : null;

  Map<String, dynamic> toJson() => {
        'originProductType': originProductType.name,
        'originProductId': originProductId,
        'toProductType': toProductType.name,
        'toProductId': toProductId,
        'toProductName': toProductName,
        if (provisionType != null) 'provisionType': provisionType!.name,
        'relationshipType': relationshipType.name,
        if (specificTypeLabel.isNotEmpty)
          'specificTypeLabel': specificTypeLabel,
        if (direction != null) 'direction': direction!.name,
        'provenance': provenance,
        'evidenceRefs': evidenceRefs,
        if (toProductYear != null) 'toProductYear': toProductYear,
      };

  factory KnowledgeProductReference.fromJson(Map<String, dynamic> json) =>
      KnowledgeProductReference(
        originProductType: KnowledgeProductTypeExtension.fromName(
            json['originProductType'] as String?),
        originProductId: json['originProductId'] as String? ?? '',
        toProductType: KnowledgeProductTypeExtension.fromName(
            json['toProductType'] as String?),
        toProductId: json['toProductId'] as String? ?? '',
        toProductName: json['toProductName'] as String? ?? '',
        provisionType: json['provisionType'] == null
            ? null
            : ProvisionType.values.firstWhere(
                (e) => e.name == json['provisionType'],
              ),
        relationshipType: NavigationRelationshipTypeExtension.fromName(
            json['relationshipType'] as String?),
        specificTypeLabel: json['specificTypeLabel'] as String? ?? '',
        direction: json['direction'] == null
            ? null
            : NavigationDirectionExtension.fromName(
                json['direction'] as String?),
        provenance: json['provenance'] as String? ?? '',
        evidenceRefs:
            (json['evidenceRefs'] as List<dynamic>? ?? const []).cast<String>(),
        toProductYear: json['toProductYear'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeProductReference &&
          originProductType == other.originProductType &&
          originProductId == other.originProductId &&
          toProductType == other.toProductType &&
          toProductId == other.toProductId &&
          toProductName == other.toProductName &&
          provisionType == other.provisionType &&
          relationshipType == other.relationshipType &&
          specificTypeLabel == other.specificTypeLabel &&
          direction == other.direction &&
          provenance == other.provenance &&
          _listEquals(evidenceRefs, other.evidenceRefs) &&
          toProductYear == other.toProductYear;

  @override
  int get hashCode => Object.hash(
        originProductType,
        originProductId,
        toProductType,
        toProductId,
        toProductName,
        provisionType,
        relationshipType,
        specificTypeLabel,
        direction,
        provenance,
        Object.hashAll(evidenceRefs),
        toProductYear,
      );

  @override
  String toString() =>
      'KnowledgeProductReference($originProductType:$originProductId '
      '--$relationshipType${specificTypeLabel.isEmpty ? '' : '/$specificTypeLabel'}'
      '${direction == null ? '' : '/${direction!.name}'}--> '
      '$toProductType:$toProductId [$provenance])';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
