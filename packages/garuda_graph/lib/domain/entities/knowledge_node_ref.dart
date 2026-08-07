library;

import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable reference descriptor to a node in the GARUDA Knowledge Graph.
@immutable
class KnowledgeNodeRef {
  final String id;
  final String name;
  final NodeType nodeType;
  final String category;
  final Map<String, dynamic> attributes;

  const KnowledgeNodeRef({
    required this.id,
    required this.name,
    required this.nodeType,
    this.category = 'General',
    this.attributes = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nodeType': nodeType.name,
        'category': category,
        'attributes': attributes,
      };

  factory KnowledgeNodeRef.fromJson(Map<String, dynamic> json) => KnowledgeNodeRef(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        nodeType: NodeType.values.firstWhere(
          (e) => e.name == json['nodeType'],
          orElse: () => NodeType.knowledgeObject,
        ),
        category: json['category'] as String? ?? 'General',
        attributes: Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KnowledgeNodeRef &&
        other.id == id &&
        other.name == name &&
        other.nodeType == nodeType;
  }

  @override
  int get hashCode => Object.hash(id, name, nodeType);

  @override
  String toString() => 'KnowledgeNodeRef(id: $id, name: $name, type: ${nodeType.name})';
}
