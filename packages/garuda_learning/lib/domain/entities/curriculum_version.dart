/// Curriculum Versioning metadata (TITAN-KO-017.0 P17).
///
/// Immutable semantic version descriptor for a [CurriculumFramework].
library;

import 'package:meta/meta.dart';

@immutable
class CurriculumVersion {
  /// Semantic version string (e.g. '1.0.0').
  final String version;

  /// Schema version string (e.g. '1.0').
  final String schemaVersion;

  /// ISO-8601 effective date string (e.g. '2026-08-15').
  final String effectiveDate;

  /// Provenance / specification authority for this version.
  final String provenance;

  /// Brief change notes or scope summary.
  final String releaseNotes;

  CurriculumVersion({
    required this.version,
    this.schemaVersion = '1.0',
    required this.effectiveDate,
    required this.provenance,
    this.releaseNotes = '',
  })  : assert(version.trim().isNotEmpty, 'version cannot be empty'),
        assert(
            effectiveDate.trim().isNotEmpty, 'effectiveDate cannot be empty'),
        assert(provenance.trim().isNotEmpty, 'provenance cannot be empty');

  Map<String, dynamic> toJson() => {
        'version': version,
        'schemaVersion': schemaVersion,
        'effectiveDate': effectiveDate,
        'provenance': provenance,
        if (releaseNotes.isNotEmpty) 'releaseNotes': releaseNotes,
      };

  factory CurriculumVersion.fromJson(Map<String, dynamic> json) =>
      CurriculumVersion(
        version: json['version'] as String? ?? '1.0.0',
        schemaVersion: json['schemaVersion'] as String? ?? '1.0',
        effectiveDate: json['effectiveDate'] as String? ?? '2026-01-01',
        provenance: json['provenance'] as String? ?? 'TITAN Curriculum Spec',
        releaseNotes: json['releaseNotes'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurriculumVersion &&
          version == other.version &&
          schemaVersion == other.schemaVersion &&
          effectiveDate == other.effectiveDate &&
          provenance == other.provenance &&
          releaseNotes == other.releaseNotes;

  @override
  int get hashCode => Object.hash(
        version,
        schemaVersion,
        effectiveDate,
        provenance,
        releaseNotes,
      );

  @override
  String toString() => 'CurriculumVersion(v$version, schema: $schemaVersion)';
}
