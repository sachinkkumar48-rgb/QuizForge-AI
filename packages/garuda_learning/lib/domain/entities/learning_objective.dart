/// Learning Objective domain model (TITAN-KO-017.0 P17).
///
/// Core immutable entity representing a single pedagogical learning objective
/// within the TITAN curriculum framework.
///
/// An objective explicitly answers:
/// - What should be learned? ([title], [description], [bloomLevel])
/// - How is it organized? ([unitId], [sequenceIndex])
/// - Which existing knowledge products support it? ([supportedProducts])
/// - Which prerequisites are explicitly declared? ([prerequisites])
/// - What is the static mastery threshold? ([masteryCriteria])
library;

import 'package:meta/meta.dart';

import 'bloom_taxonomy_level.dart';
import 'knowledge_product_mapping.dart';
import 'prerequisite_relationship.dart';
import 'static_mastery_criteria.dart';

@immutable
class LearningObjective {
  /// Canonical ID of the learning objective (e.g. 'lo_fr_art21').
  final String id;

  /// Canonical ID of the parent curriculum unit.
  final String unitId;

  /// Human-readable title of the learning objective.
  final String title;

  /// Comprehensive description of the objective's educational goal.
  final String description;

  /// Bloom's taxonomy cognitive level.
  final BloomTaxonomyLevel bloomLevel;

  /// Explicitly declared prerequisite relationships.
  final List<PrerequisiteRelationship> prerequisites;

  /// Mapped supporting P11–P16 Knowledge Products.
  final List<KnowledgeProductMapping> supportedProducts;

  /// Static mastery and coverage criteria.
  final StaticMasteryCriteria masteryCriteria;

  /// Deterministic sequence index within parent unit.
  final int sequenceIndex;

  /// Evidence/source provenance of the objective declaration.
  final String provenance;

  LearningObjective({
    required this.id,
    required this.unitId,
    required this.title,
    required this.description,
    this.bloomLevel = BloomTaxonomyLevel.understand,
    this.prerequisites = const [],
    this.supportedProducts = const [],
    this.masteryCriteria = const StaticMasteryCriteria(),
    this.sequenceIndex = 0,
    required this.provenance,
  })  : assert(id.trim().isNotEmpty, 'LearningObjective id cannot be empty'),
        assert(unitId.trim().isNotEmpty, 'unitId cannot be empty'),
        assert(title.trim().isNotEmpty, 'title cannot be empty'),
        assert(provenance.trim().isNotEmpty, 'provenance cannot be empty'),
        assert(sequenceIndex >= 0, 'sequenceIndex must be non-negative');

  /// List of canonical prerequisite objective IDs.
  List<String> get prerequisiteIds =>
      prerequisites.map((p) => p.prerequisiteObjectiveId).toList();

  /// Map to JSON serialization.
  Map<String, dynamic> toJson() => {
        'id': id,
        'unitId': unitId,
        'title': title,
        'description': description,
        'bloomLevel': bloomLevel.name,
        'prerequisites': prerequisites.map((p) => p.toJson()).toList(),
        'supportedProducts': supportedProducts.map((m) => m.toJson()).toList(),
        'masteryCriteria': masteryCriteria.toJson(),
        'sequenceIndex': sequenceIndex,
        'provenance': provenance,
      };

  /// Factory from JSON deserialization.
  factory LearningObjective.fromJson(Map<String, dynamic> json) =>
      LearningObjective(
        id: json['id'] as String? ?? '',
        unitId: json['unitId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        bloomLevel: BloomTaxonomyLevelExtension.fromName(
          json['bloomLevel'] as String?,
        ),
        prerequisites: (json['prerequisites'] as List<dynamic>? ?? const [])
            .map((e) =>
                PrerequisiteRelationship.fromJson(e as Map<String, dynamic>))
            .toList(),
        supportedProducts:
            (json['supportedProducts'] as List<dynamic>? ?? const [])
                .map((e) =>
                    KnowledgeProductMapping.fromJson(e as Map<String, dynamic>))
                .toList(),
        masteryCriteria: json['masteryCriteria'] != null
            ? StaticMasteryCriteria.fromJson(
                json['masteryCriteria'] as Map<String, dynamic>)
            : const StaticMasteryCriteria(),
        sequenceIndex: json['sequenceIndex'] as int? ?? 0,
        provenance: json['provenance'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningObjective &&
          id == other.id &&
          unitId == other.unitId &&
          title == other.title &&
          description == other.description &&
          bloomLevel == other.bloomLevel &&
          sequenceIndex == other.sequenceIndex &&
          provenance == other.provenance &&
          masteryCriteria == other.masteryCriteria &&
          _listEquals(prerequisites, other.prerequisites) &&
          _listEquals(supportedProducts, other.supportedProducts);

  @override
  int get hashCode => Object.hash(
        id,
        unitId,
        title,
        description,
        bloomLevel,
        sequenceIndex,
        provenance,
        masteryCriteria,
        Object.hashAll(prerequisites),
        Object.hashAll(supportedProducts),
      );

  @override
  String toString() =>
      'LearningObjective($id, title: "$title", products: ${supportedProducts.length}, prereqs: ${prerequisites.length})';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
