/// Knowledge Product Mapping for Learning Objectives (TITAN-KO-017.0 P17).
///
/// Immutable value object binding a [LearningObjective] to a canonical
/// P11–P16 Knowledge Product.
///
/// Product references must resolve to an existing P11–P16 product:
/// - [KnowledgeProductType.caseLaw] -> `caseId` (P11)
/// - [KnowledgeProductType.doctrine] -> `doctrineId` (P12)
/// - [KnowledgeProductType.provision] -> `provisionKey` & `provisionType` (P13)
/// - [KnowledgeProductType.topic] -> `topicId` (P14)
/// - [KnowledgeProductType.question] -> `questionId` (P15)
library;

import 'package:garuda_case_law/garuda_case_law.dart'
    show KnowledgeProductType, KnowledgeProductTypeExtension, ProvisionType;
import 'package:meta/meta.dart';

@immutable
class KnowledgeProductMapping {
  /// Kind of the referenced knowledge product.
  final KnowledgeProductType productType;

  /// Canonical ID of the referenced product.
  final String productId;

  /// Display title or label for the product mapping.
  final String title;

  /// Provision kind (required when [productType] is [KnowledgeProductType.provision]).
  final ProvisionType? provisionType;

  /// Source provenance / justification for this mapping.
  final String provenance;

  /// Role of this knowledge product in supporting the objective
  /// (e.g. 'foundational_case', 'statutory_basis', 'doctrine_core', 'practice_question').
  final String role;

  KnowledgeProductMapping({
    required this.productType,
    required this.productId,
    required this.title,
    this.provisionType,
    required this.provenance,
    this.role = 'supporting',
  })  : assert(productId.trim().isNotEmpty, 'productId cannot be empty'),
        assert(provenance.trim().isNotEmpty, 'provenance cannot be empty'),
        assert(
          productType != KnowledgeProductType.provision ||
              provisionType != null,
          'provisionType is required when productType is provision',
        ),
        assert(
          productType == KnowledgeProductType.provision ||
              provisionType == null,
          'provisionType is only valid when productType is provision',
        );

  /// Global deduplication key.
  String get mappingKey =>
      '${productType.name}:$productId${provisionType != null ? ":${provisionType!.name}" : ""}';

  Map<String, dynamic> toJson() => {
        'productType': productType.name,
        'productId': productId,
        'title': title,
        if (provisionType != null) 'provisionType': provisionType!.name,
        'provenance': provenance,
        'role': role,
      };

  factory KnowledgeProductMapping.fromJson(Map<String, dynamic> json) =>
      KnowledgeProductMapping(
        productType: KnowledgeProductTypeExtension.fromName(
          json['productType'] as String?,
        ),
        productId: json['productId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        provisionType: json['provisionType'] == null
            ? null
            : ProvisionType.values.firstWhere(
                (e) => e.name == json['provisionType'],
              ),
        provenance: json['provenance'] as String? ?? '',
        role: json['role'] as String? ?? 'supporting',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeProductMapping &&
          productType == other.productType &&
          productId == other.productId &&
          title == other.title &&
          provisionType == other.provisionType &&
          provenance == other.provenance &&
          role == other.role;

  @override
  int get hashCode => Object.hash(
        productType,
        productId,
        title,
        provisionType,
        provenance,
        role,
      );

  @override
  String toString() =>
      'KnowledgeProductMapping($productType:$productId, role: $role)';
}
