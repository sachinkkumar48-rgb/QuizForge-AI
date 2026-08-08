library;

import 'package:meta/meta.dart';
import 'scheme_enums.dart';

/// A discrete benefit delivered to scheme beneficiaries.
@immutable
class SchemeBenefit {
  final String id;
  final String title;
  final String description;
  final SchemeBenefitType benefitType;
  final String quantum; // e.g. "₹6,000/year", "₹5 lakh cover", "100 days"
  final List<String> eligibleTargetGroupIds;

  const SchemeBenefit({
    required this.id,
    required this.title,
    this.description = '',
    this.benefitType = SchemeBenefitType.monetary,
    this.quantum = '',
    this.eligibleTargetGroupIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'benefitType': benefitType.name,
        'quantum': quantum,
        'eligibleTargetGroupIds': eligibleTargetGroupIds,
      };

  factory SchemeBenefit.fromJson(Map<String, dynamic> json) => SchemeBenefit(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        benefitType: SchemeBenefitType.values.firstWhere(
          (t) => t.name == json['benefitType'],
          orElse: () => SchemeBenefitType.monetary,
        ),
        quantum: json['quantum'] as String? ?? '',
        eligibleTargetGroupIds: (json['eligibleTargetGroupIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}
