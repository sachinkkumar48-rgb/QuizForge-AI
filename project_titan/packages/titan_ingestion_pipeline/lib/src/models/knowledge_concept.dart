import 'package:meta/meta.dart';

/// Categorization of domain concepts detected in knowledge ingestion.
enum ConceptType {
  definition,
  fact,
  date,
  article,
  act,
  committee,
  scheme,
  person,
  place,
  event,
  formula,
  terminology,
}

/// Domain model for an extracted knowledge concept.
@immutable
class KnowledgeConcept {
  final String id;
  final String name;
  final ConceptType type;
  final String description;
  final String context;
  final Map<String, dynamic> attributes;

  KnowledgeConcept({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    this.context = '',
    Map<String, dynamic>? attributes,
  }) : attributes = Map.unmodifiable(attributes ?? {});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'description': description,
        'context': context,
        'attributes': attributes,
      };

  factory KnowledgeConcept.fromJson(Map<String, dynamic> json) =>
      KnowledgeConcept(
        id: json['id'] as String,
        name: json['name'] as String,
        type: ConceptType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ConceptType.terminology,
        ),
        description: json['description'] as String,
        context: json['context'] as String? ?? '',
        attributes: Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeConcept &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type;

  @override
  int get hashCode => Object.hash(id, name, type);
}
