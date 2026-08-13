/// Curriculum Framework aggregate root (TITAN-KO-017.0 P17).
///
/// Root aggregate model representing the complete versioned curriculum tree.
library;

import 'package:meta/meta.dart';

import 'curriculum_domain.dart';
import 'curriculum_unit.dart';
import 'curriculum_version.dart';
import 'learning_objective.dart';

@immutable
class CurriculumFramework {
  /// Canonical framework identifier (e.g. 'titan_upsc_legal_curriculum').
  final String id;

  /// Display title of the curriculum framework.
  final String title;

  /// Comprehensive framework description.
  final String description;

  /// Version descriptor.
  final CurriculumVersion version;

  /// High-level domains constituting the curriculum.
  final List<CurriculumDomain> domains;

  /// Evidence / spec provenance.
  final String provenance;

  CurriculumFramework({
    required this.id,
    required this.title,
    required this.description,
    required this.version,
    this.domains = const [],
    required this.provenance,
  })  : assert(id.trim().isNotEmpty, 'CurriculumFramework id cannot be empty'),
        assert(title.trim().isNotEmpty, 'title cannot be empty'),
        assert(provenance.trim().isNotEmpty, 'provenance cannot be empty');

  /// Flattened list of all curriculum units across all domains.
  List<CurriculumUnit> get allUnits => domains.expand((d) => d.units).toList();

  /// Flattened list of all learning objectives across all units and domains.
  List<LearningObjective> get allObjectives =>
      allUnits.expand((u) => u.objectives).toList();

  /// Map of learning objective ID -> objective.
  Map<String, LearningObjective> get objectiveMap => {
        for (final obj in allObjectives) obj.id: obj,
      };

  /// Map of unit ID -> unit.
  Map<String, CurriculumUnit> get unitMap => {
        for (final unit in allUnits) unit.id: unit,
      };

  /// Map of domain ID -> domain.
  Map<String, CurriculumDomain> get domainMap => {
        for (final domain in domains) domain.id: domain,
      };

  /// Total count of learning objectives in framework.
  int get objectiveCount => allObjectives.length;

  /// Total count of supporting knowledge product mappings.
  int get totalMappingCount => allObjectives.fold(
        0,
        (sum, obj) => sum + obj.supportedProducts.length,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'version': version.toJson(),
        'domains': domains.map((d) => d.toJson()).toList(),
        'provenance': provenance,
      };

  factory CurriculumFramework.fromJson(Map<String, dynamic> json) =>
      CurriculumFramework(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        version: json['version'] != null
            ? CurriculumVersion.fromJson(
                json['version'] as Map<String, dynamic>)
            : CurriculumVersion(
                version: '1.0.0',
                effectiveDate: '2026-01-01',
                provenance: 'Default Framework Version',
              ),
        domains: (json['domains'] as List<dynamic>? ?? const [])
            .map((e) => CurriculumDomain.fromJson(e as Map<String, dynamic>))
            .toList(),
        provenance: json['provenance'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurriculumFramework &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          version == other.version &&
          provenance == other.provenance &&
          _listEquals(domains, other.domains);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        version,
        provenance,
        Object.hashAll(domains),
      );

  @override
  String toString() =>
      'CurriculumFramework($id, v${version.version}, domains: ${domains.length}, objectives: $objectiveCount)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
