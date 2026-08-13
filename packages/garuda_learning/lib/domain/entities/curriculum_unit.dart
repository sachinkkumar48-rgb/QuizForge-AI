/// Curriculum Unit domain model (TITAN-KO-017.0 P17).
///
/// An immutable unit grouping related [LearningObjective]s within a [CurriculumDomain].
library;

import 'package:meta/meta.dart';

import 'learning_objective.dart';

@immutable
class CurriculumUnit {
  /// Canonical ID of the unit (e.g. 'unit_fundamental_rights').
  final String id;

  /// Parent domain ID (e.g. 'domain_constitutional_law').
  final String domainId;

  /// Display title of the unit.
  final String title;

  /// Unit description and scope statement.
  final String description;

  /// Ordered list of learning objectives contained in this unit.
  final List<LearningObjective> objectives;

  /// Deterministic sequence index within parent domain.
  final int sequenceIndex;

  /// Evidence/source provenance.
  final String provenance;

  CurriculumUnit({
    required this.id,
    required this.domainId,
    required this.title,
    required this.description,
    this.objectives = const [],
    this.sequenceIndex = 0,
    required this.provenance,
  })  : assert(id.trim().isNotEmpty, 'CurriculumUnit id cannot be empty'),
        assert(domainId.trim().isNotEmpty, 'domainId cannot be empty'),
        assert(title.trim().isNotEmpty, 'title cannot be empty'),
        assert(provenance.trim().isNotEmpty, 'provenance cannot be empty'),
        assert(sequenceIndex >= 0, 'sequenceIndex must be non-negative');

  Map<String, dynamic> toJson() => {
        'id': id,
        'domainId': domainId,
        'title': title,
        'description': description,
        'objectives': objectives.map((o) => o.toJson()).toList(),
        'sequenceIndex': sequenceIndex,
        'provenance': provenance,
      };

  factory CurriculumUnit.fromJson(Map<String, dynamic> json) => CurriculumUnit(
        id: json['id'] as String? ?? '',
        domainId: json['domainId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        objectives: (json['objectives'] as List<dynamic>? ?? const [])
            .map((e) => LearningObjective.fromJson(e as Map<String, dynamic>))
            .toList(),
        sequenceIndex: json['sequenceIndex'] as int? ?? 0,
        provenance: json['provenance'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurriculumUnit &&
          id == other.id &&
          domainId == other.domainId &&
          title == other.title &&
          description == other.description &&
          sequenceIndex == other.sequenceIndex &&
          provenance == other.provenance &&
          _listEquals(objectives, other.objectives);

  @override
  int get hashCode => Object.hash(
        id,
        domainId,
        title,
        description,
        sequenceIndex,
        provenance,
        Object.hashAll(objectives),
      );

  @override
  String toString() =>
      'CurriculumUnit($id, title: "$title", objectives: ${objectives.length})';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
