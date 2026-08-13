/// Static mastery criteria model (TITAN-KO-017.0 P17).
///
/// Defines static required knowledge product coverage criteria for an objective
/// (e.g. required product count, mandatory product IDs).
///
/// NOTE: This is a static curriculum specification model. It does NOT track
/// learner progress, scores, or user-specific mastery state.
library;

import 'package:meta/meta.dart';

@immutable
class StaticMasteryCriteria {
  /// Minimum number of supporting knowledge products required to achieve
  /// static coverage of the objective.
  final int minRequiredProducts;

  /// Specific product IDs that MUST be covered for complete coverage.
  final List<String> mandatoryProductIds;

  /// Qualitative coverage description (e.g. 'Requires leading case + constitutional article').
  final String description;

  const StaticMasteryCriteria({
    this.minRequiredProducts = 1,
    this.mandatoryProductIds = const [],
    this.description = '',
  }) : assert(
            minRequiredProducts >= 0, 'minRequiredProducts cannot be negative');

  Map<String, dynamic> toJson() => {
        'minRequiredProducts': minRequiredProducts,
        'mandatoryProductIds': mandatoryProductIds,
        if (description.isNotEmpty) 'description': description,
      };

  factory StaticMasteryCriteria.fromJson(Map<String, dynamic> json) =>
      StaticMasteryCriteria(
        minRequiredProducts: json['minRequiredProducts'] as int? ?? 1,
        mandatoryProductIds:
            (json['mandatoryProductIds'] as List<dynamic>? ?? const [])
                .cast<String>(),
        description: json['description'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticMasteryCriteria &&
          minRequiredProducts == other.minRequiredProducts &&
          description == other.description &&
          _listEquals(mandatoryProductIds, other.mandatoryProductIds);

  @override
  int get hashCode => Object.hash(
        minRequiredProducts,
        description,
        Object.hashAll(mandatoryProductIds),
      );

  @override
  String toString() =>
      'StaticMasteryCriteria(min: $minRequiredProducts, mandatory: $mandatoryProductIds)';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
