import 'package:meta/meta.dart';

/// Immutable entity representing a tag associated with knowledge objects.
@immutable
class KnowledgeTag {
  final String name;

  const KnowledgeTag(this.name);

  Map<String, dynamic> toJson() => {'name': name};

  factory KnowledgeTag.fromJson(Map<String, dynamic> json) {
    return KnowledgeTag(json['name'] as String? ?? '');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeTag &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}
