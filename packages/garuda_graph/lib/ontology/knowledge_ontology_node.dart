library;

import 'package:meta/meta.dart';
import '../domain/entities/enums.dart';

/// Immutable ontology node in the hierarchical knowledge tree (unlimited depth).
@immutable
class KnowledgeOntologyNode {
  final String id;
  final String title;
  final NodeType type;
  final String? parentId;
  final List<String> childrenIds;
  final int depth;
  final Map<String, dynamic> metadata;

  const KnowledgeOntologyNode({
    required this.id,
    required this.title,
    required this.type,
    this.parentId,
    this.childrenIds = const [],
    this.depth = 0,
    this.metadata = const {},
  });

  KnowledgeOntologyNode copyWith({
    String? id,
    String? title,
    NodeType? type,
    String? parentId,
    List<String>? childrenIds,
    int? depth,
    Map<String, dynamic>? metadata,
  }) {
    return KnowledgeOntologyNode(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      childrenIds: childrenIds ?? List.from(this.childrenIds),
      depth: depth ?? this.depth,
      metadata: metadata ?? Map<String, dynamic>.from(this.metadata),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'parentId': parentId,
        'childrenIds': childrenIds,
        'depth': depth,
        'metadata': metadata,
      };

  factory KnowledgeOntologyNode.fromJson(Map<String, dynamic> json) =>
      KnowledgeOntologyNode(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        type: NodeType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => NodeType.topic,
        ),
        parentId: json['parentId'] as String?,
        childrenIds: (json['childrenIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        depth: (json['depth'] as num?)?.toInt() ?? 0,
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KnowledgeOntologyNode &&
        other.id == id &&
        other.title == title &&
        other.depth == depth;
  }

  @override
  int get hashCode => Object.hash(id, title, depth);
}
