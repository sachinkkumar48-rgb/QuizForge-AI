/// Topic identity for the Evidence-Bounded UPSC Topic Knowledge Product layer
/// (TITAN-KO-015.0 P14).
///
/// A `TopicIdentity` is the deterministic, versioned identity of one
/// pedagogical UPSC topic. It is NOT a legal identifier and does not carry any
/// legal meaning: it names a pedagogical grouping of existing validated
/// case-law knowledge for UPSC preparation.
///
/// The [area] reuses the normalized P4 `UpscSyllabusArea` enum (the repository's
/// source of syllabus-area truth); the [pedagogicalPath] is an editorial,
/// versioned mapping string (e.g. `GS Paper II → Constitutional Governance →
/// Basic Structure Doctrine`) that is explicitly NOT official UPSC syllabus
/// wording (see [TopicMappingKind] and the P14 documentation).
library;

import 'package:meta/meta.dart';

import '../../intelligence/domain/intelligence_enums.dart';
import 'topic_product_enums.dart';

/// Immutable, deterministic identity of one pedagogical UPSC topic.
@immutable
class TopicIdentity {
  /// Canonical deterministic topic ID (e.g. `amending_power_and_basic_structure`).
  final String id;

  /// Deterministic display name (e.g. `Amending Power & Basic Structure`).
  final String name;

  /// The normalized P4 syllabus area the topic is grouped under.
  final UpscSyllabusArea area;

  /// Editorial pedagogical path (e.g. `GS Paper II → Constitutional Governance
  /// → Basic Structure`). A pedagogical mapping, never a legal fact and never a
  /// claim of official syllabus wording.
  final String pedagogicalPath;

  /// The kind of taxonomy this topic belongs to (always
  /// [TopicMappingKind.pedagogicalMapping]).
  final TopicMappingKind mappingKind;

  /// Version of the P14 syllabus configuration that defined this topic.
  final String configVersion;

  const TopicIdentity({
    required this.id,
    required this.name,
    required this.area,
    required this.pedagogicalPath,
    required this.mappingKind,
    required this.configVersion,
  }) : assert(id.length > 0, 'a topic identity needs an id');

  /// Whether the mapping claims official UPSC syllabus status. Always false for
  /// the current syllabus configuration — the repository holds no authoritative
  /// UPSC syllabus source, so no P14 topic may claim to be official.
  bool get isOfficialSyllabus => false;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'area': area.name,
        'pedagogicalPath': pedagogicalPath,
        'mappingKind': mappingKind.name,
        'configVersion': configVersion,
        'isOfficialSyllabus': isOfficialSyllabus,
      };

  factory TopicIdentity.fromJson(Map<String, dynamic> json) => TopicIdentity(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        area: UpscSyllabusArea.values.firstWhere(
          (a) => a.name == json['area'],
          orElse: () => UpscSyllabusArea.gs2,
        ),
        pedagogicalPath: json['pedagogicalPath'] as String? ?? '',
        mappingKind: TopicMappingKind.values.firstWhere(
          (k) => k.name == json['mappingKind'],
          orElse: () => TopicMappingKind.pedagogicalMapping,
        ),
        configVersion: json['configVersion'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicIdentity &&
          id == other.id &&
          name == other.name &&
          area == other.area &&
          pedagogicalPath == other.pedagogicalPath &&
          mappingKind == other.mappingKind &&
          configVersion == other.configVersion;

  @override
  int get hashCode =>
      Object.hash(id, name, area, pedagogicalPath, mappingKind, configVersion);

  @override
  String toString() => 'TopicIdentity($id)';
}
