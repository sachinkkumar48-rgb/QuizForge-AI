/// Curriculum Domain model (TITAN-KO-017.0 P17).
///
/// High-level subject domain organizing [CurriculumUnit]s within a [CurriculumFramework].
library;

import 'package:meta/meta.dart';

import 'curriculum_unit.dart';

@immutable
class CurriculumDomain {
  /// Canonical ID of the domain (e.g. 'domain_constitutional_law').
  final String id;

  /// Display title of the domain.
  final String title;

  /// Comprehensive description of the domain scope.
  final String description;

  /// Ordered list of curriculum units in this domain.
  final List<CurriculumUnit> units;

  /// Deterministic sequence index within framework.
  final int sequenceIndex;

  /// Source provenance.
  final String provenance;

  CurriculumDomain({
    required this.id,
    required this.title,
    required this.description,
    this.units = const [],
    this.sequenceIndex = 0,
    required this.provenance,
  })  : assert(id.trim().isNotEmpty, 'CurriculumDomain id cannot be empty'),
        assert(title.trim().isNotEmpty, 'title cannot be empty'),
        assert(provenance.trim().isNotEmpty, 'provenance cannot be empty'),
        assert(sequenceIndex >= 0, 'sequenceIndex must be non-negative');

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'units': units.map((u) => u.toJson()).toList(),
        'sequenceIndex': sequenceIndex,
        'provenance': provenance,
      };

  factory CurriculumDomain.fromJson(Map<String, dynamic> json) =>
      CurriculumDomain(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        units: (json['units'] as List<dynamic>? ?? const [])
            .map((e) => CurriculumUnit.fromJson(e as Map<String, dynamic>))
            .toList(),
        sequenceIndex: json['sequenceIndex'] as int? ?? 0,
        provenance: json['provenance'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurriculumDomain &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          sequenceIndex == other.sequenceIndex &&
          provenance == other.provenance &&
          _listEquals(units, other.units);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        sequenceIndex,
        provenance,
        Object.hashAll(units),
      );

  @override
  String toString() =>
      'CurriculumDomain($id, title: "$title", units: ${units.length})';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
