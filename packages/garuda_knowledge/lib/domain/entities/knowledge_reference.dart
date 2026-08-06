import 'package:meta/meta.dart';
import '../value_objects/knowledge_object_id.dart';

/// Immutable entity representing a direct external or internal reference link.
@immutable
class KnowledgeReference {
  final KnowledgeObjectId targetId;
  final String label;
  final String? contextSnippet;

  const KnowledgeReference({
    required this.targetId,
    required this.label,
    this.contextSnippet,
  });

  Map<String, dynamic> toJson() => {
        'targetId': targetId.toJson(),
        'label': label,
        'contextSnippet': contextSnippet,
      };

  factory KnowledgeReference.fromJson(Map<String, dynamic> json) {
    return KnowledgeReference(
      targetId: KnowledgeObjectId.fromJson(json['targetId'] as String),
      label: json['label'] as String? ?? '',
      contextSnippet: json['contextSnippet'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeReference &&
          runtimeType == other.runtimeType &&
          targetId == other.targetId &&
          label == other.label;

  @override
  int get hashCode => Object.hash(targetId, label);
}
