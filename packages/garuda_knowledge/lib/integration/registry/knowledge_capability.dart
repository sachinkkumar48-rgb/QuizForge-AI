import 'package:meta/meta.dart';

/// Immutable value object representing a functional capability of a registered package.
@immutable
class KnowledgeCapability {
  final String id;
  final String name;
  final String description;

  const KnowledgeCapability({
    required this.id,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };

  factory KnowledgeCapability.fromJson(Map<String, dynamic> json) {
    return KnowledgeCapability(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeCapability &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$name ($id)';
}
