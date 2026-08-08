library;

import 'package:meta/meta.dart';

/// A distinct component / sub-scheme / vertical within a Scheme.
@immutable
class SchemeComponent {
  final String id;
  final String name;
  final String description;
  final String coverage;
  final List<String> relatedBenefitIds;

  const SchemeComponent({
    required this.id,
    required this.name,
    this.description = '',
    this.coverage = '',
    this.relatedBenefitIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'coverage': coverage,
        'relatedBenefitIds': relatedBenefitIds,
      };

  factory SchemeComponent.fromJson(Map<String, dynamic> json) => SchemeComponent(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        coverage: json['coverage'] as String? ?? '',
        relatedBenefitIds: (json['relatedBenefitIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}
