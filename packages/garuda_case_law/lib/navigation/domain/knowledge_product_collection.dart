/// KnowledgeProductCollection for the Knowledge Product Navigator
/// (TITAN-KO-015.0 P16).
///
/// An immutable, deterministic collection of [KnowledgeProductReference]s for a
/// single origin product. References are de-duplicated (same logical destination
/// reached through the same relationship) and ordered by a stable documented
/// key, so identical inputs always produce byte-identical collections. No
/// ranking by legal importance, relevance or presumed authority is applied.
library;

import 'package:meta/meta.dart';

import 'knowledge_product_reference.dart';
import 'knowledge_product_type.dart';
import 'navigation_direction.dart';
import 'navigation_relationship_type.dart';

/// An immutable, deterministically ordered collection of navigation references.
@immutable
class KnowledgeProductCollection {
  /// Kind of the origin product the collection was built for.
  final KnowledgeProductType originProductType;

  /// Canonical ID of the origin product.
  final String originProductId;

  /// The de-duplicated, deterministically ordered references.
  final List<KnowledgeProductReference> references;

  KnowledgeProductCollection._({
    required this.originProductType,
    required this.originProductId,
    required List<KnowledgeProductReference> references,
  }) : references = List<KnowledgeProductReference>.unmodifiable(references);

  /// Builds a collection from [refs], de-duplicating and ordering them.
  ///
  /// Ordering key (documented in `P16_KNOWLEDGE_PRODUCT_NAVIGATOR.md`):
  /// 1. product type order (case → doctrine → provision → topic → question);
  /// 2. for case products, chronological publication year ascending;
  /// 3. for provision products, provision kind, then name;
  /// 4. canonical display name;
  /// 5. canonical ID.
  factory KnowledgeProductCollection.fromReferences({
    required KnowledgeProductType originProductType,
    required String originProductId,
    required Iterable<KnowledgeProductReference> refs,
  }) {
    final seen = <String>{};
    final unique = <KnowledgeProductReference>[];
    for (final r in refs) {
      if (seen.add(r.dedupKey)) unique.add(r);
    }
    unique.sort(_compare);
    return KnowledgeProductCollection._(
      originProductType: originProductType,
      originProductId: originProductId,
      references: unique,
    );
  }

  /// Number of references in this collection.
  int get length => references.length;

  /// Whether the collection carries no references.
  bool get isEmpty => references.isEmpty;

  /// The unique canonical destination IDs in this collection, in collection
  /// order.
  List<String> get destinationIds {
    final seen = <String>{};
    return [
      for (final r in references)
        if (seen.add(r.toProductId)) r.toProductId,
    ];
  }

  /// References whose destination kind is [type].
  Iterable<KnowledgeProductReference> ofType(KnowledgeProductType type) =>
      references.where((r) => r.toProductType == type);

  /// References whose relationship kind is [relationship].
  Iterable<KnowledgeProductReference> ofRelationship(
          NavigationRelationshipType relationship) =>
      references.where((r) => r.relationshipType == relationship);

  /// References whose traversal direction is [direction].
  Iterable<KnowledgeProductReference> withDirection(
          NavigationDirection direction) =>
      references.where((r) => r.direction == direction);

  /// References whose destination resolves to one of [ids] (canonical IDs).
  Iterable<KnowledgeProductReference> toAnyOf(Iterable<String> ids) {
    final s = ids.toSet();
    return references.where((r) => s.contains(r.toProductId));
  }

  /// Deterministic comparison used to order references within a collection.
  ///
  /// Group order is the [KnowledgeProductType] sort index; case products are
  /// then ordered chronologically by publication year; provision products by
  /// provision kind; finally by canonical display name then canonical ID. Ties
  /// that survive all keys are broken by the reference's dedup key so ordering
  /// is total and reproducible.
  static int _compare(
      KnowledgeProductReference a, KnowledgeProductReference b) {
    final byKind =
        a.toProductType.sortIndex.compareTo(b.toProductType.sortIndex);
    if (byKind != 0) return byKind;

    if (a.toProductType == KnowledgeProductType.caseLaw) {
      final aYear = a.toProductYear ?? 0x7fffffff;
      final bYear = b.toProductYear ?? 0x7fffffff;
      final byYear = aYear.compareTo(bYear);
      if (byYear != 0) return byYear;
    }

    if (a.toProductType == KnowledgeProductType.provision) {
      final aType = a.provisionType?.index ?? -1;
      final bType = b.provisionType?.index ?? -1;
      final byProvisionType = aType.compareTo(bType);
      if (byProvisionType != 0) return byProvisionType;
    }

    final byName = a.toProductName.compareTo(b.toProductName);
    if (byName != 0) return byName;

    final byId = a.toProductId.compareTo(b.toProductId);
    if (byId != 0) return byId;

    return a.dedupKey.compareTo(b.dedupKey);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeProductCollection &&
          originProductType == other.originProductType &&
          originProductId == other.originProductId &&
          _refsEquals(references, other.references);

  @override
  int get hashCode => Object.hash(
        originProductType,
        originProductId,
        Object.hashAll(references),
      );

  @override
  String toString() =>
      'KnowledgeProductCollection($originProductType:$originProductId, '
      '${references.length} references)';

  static bool _refsEquals(
      List<KnowledgeProductReference> a, List<KnowledgeProductReference> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
