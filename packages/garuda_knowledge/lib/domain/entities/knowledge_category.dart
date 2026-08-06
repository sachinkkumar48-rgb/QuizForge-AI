import 'package:meta/meta.dart';

/// Immutable entity representing a taxonomy category for knowledge objects.
@immutable
class KnowledgeCategory {
  final String id;
  final String name;
  final String? parentCategoryId;

  const KnowledgeCategory({
    required this.id,
    required this.name,
    this.parentCategoryId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parentCategoryId': parentCategoryId,
      };

  factory KnowledgeCategory.fromJson(Map<String, dynamic> json) {
    return KnowledgeCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      parentCategoryId: json['parentCategoryId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}
