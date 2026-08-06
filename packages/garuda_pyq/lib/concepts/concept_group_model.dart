import 'package:meta/meta.dart';

@immutable
class ConceptGroup {
  final String id;
  final String name;
  final String description;
  final String subject;
  final List<String> conceptIds;

  const ConceptGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.subject,
    this.conceptIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'subject': subject,
        'conceptIds': conceptIds,
      };

  factory ConceptGroup.fromJson(Map<String, dynamic> json) => ConceptGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        subject: json['subject'] as String,
        conceptIds: List<String>.from(json['conceptIds'] ?? []),
      );
}
