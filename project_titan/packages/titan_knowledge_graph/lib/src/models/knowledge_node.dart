import 'package:meta/meta.dart';

/// Supported node types for entity nodes in the Knowledge Graph.
enum KnowledgeNodeType {
  subject,
  topic,
  subtopic,
  concept,
  pdf,
  pyq,
  currentAffairs,
  notes,
  revisionItem,
}

/// Immutable node model representing an entity in the Knowledge Graph.
@immutable
class KnowledgeNode {
  final String id;
  final String title;
  final KnowledgeNodeType type;
  final String? description;
  final String? subjectCategory;
  final double masteryWeight; // 0.0 to 1.0
  final Map<String, dynamic> metadata;

  KnowledgeNode({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    this.subjectCategory,
    this.masteryWeight = 0.5,
    Map<String, dynamic>? metadata,
  }) : metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {});

  KnowledgeNode copyWith({
    String? id,
    String? title,
    KnowledgeNodeType? type,
    String? description,
    String? subjectCategory,
    double? masteryWeight,
    Map<String, dynamic>? metadata,
  }) {
    return KnowledgeNode(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      subjectCategory: subjectCategory ?? this.subjectCategory,
      masteryWeight: masteryWeight ?? this.masteryWeight,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeNode &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          type == other.type &&
          description == other.description &&
          subjectCategory == other.subjectCategory &&
          masteryWeight == other.masteryWeight &&
          _mapEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        type,
        description,
        subjectCategory,
        masteryWeight,
        Object.hashAll(metadata.keys),
        Object.hashAll(metadata.values),
      );
}

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (a[key] != b[key]) return false;
  }
  return true;
}
