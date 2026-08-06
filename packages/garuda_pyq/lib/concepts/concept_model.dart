import 'package:meta/meta.dart';
import '../models/editorial_status.dart';

@immutable
class Concept {
  final String id;
  final String name;
  final List<String> aliases;
  final String description;
  final String subject;
  final String module;
  final String topic;
  final String? subtopic;
  final List<String> keywords;
  final String difficulty;
  final List<String> knowledgeObjectIds;
  final List<String> relatedConceptIds;
  final List<String> relatedEvidenceIds;
  final EditorialStatus editorialStatus;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Concept({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.description,
    required this.subject,
    required this.module,
    required this.topic,
    this.subtopic,
    this.keywords = const [],
    this.difficulty = 'Medium',
    this.knowledgeObjectIds = const [],
    this.relatedConceptIds = const [],
    this.relatedEvidenceIds = const [],
    this.editorialStatus = EditorialStatus.published,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'aliases': aliases,
        'description': description,
        'subject': subject,
        'module': module,
        'topic': topic,
        'subtopic': subtopic,
        'keywords': keywords,
        'difficulty': difficulty,
        'knowledgeObjectIds': knowledgeObjectIds,
        'relatedConceptIds': relatedConceptIds,
        'relatedEvidenceIds': relatedEvidenceIds,
        'editorialStatus': editorialStatus.name,
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Concept.fromJson(Map<String, dynamic> json) => Concept(
        id: json['id'] as String,
        name: json['name'] as String,
        aliases: List<String>.from(json['aliases'] ?? []),
        description: json['description'] as String? ?? '',
        subject: json['subject'] as String,
        module: json['module'] as String? ?? 'General',
        topic: json['topic'] as String,
        subtopic: json['subtopic'] as String?,
        keywords: List<String>.from(json['keywords'] ?? []),
        difficulty: json['difficulty'] as String? ?? 'Medium',
        knowledgeObjectIds:
            List<String>.from(json['knowledgeObjectIds'] ?? []),
        relatedConceptIds:
            List<String>.from(json['relatedConceptIds'] ?? []),
        relatedEvidenceIds:
            List<String>.from(json['relatedEvidenceIds'] ?? []),
        editorialStatus: EditorialStatus.values.firstWhere(
          (e) => e.name == json['editorialStatus'],
          orElse: () => EditorialStatus.published,
        ),
        version: (json['version'] as num?)?.toInt() ?? 1,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Concept copyWith({
    String? id,
    String? name,
    List<String>? aliases,
    String? description,
    String? subject,
    String? module,
    String? topic,
    String? subtopic,
    List<String>? keywords,
    String? difficulty,
    List<String>? knowledgeObjectIds,
    List<String>? relatedConceptIds,
    List<String>? relatedEvidenceIds,
    EditorialStatus? editorialStatus,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Concept(
      id: id ?? this.id,
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      module: module ?? this.module,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      keywords: keywords ?? this.keywords,
      difficulty: difficulty ?? this.difficulty,
      knowledgeObjectIds: knowledgeObjectIds ?? this.knowledgeObjectIds,
      relatedConceptIds: relatedConceptIds ?? this.relatedConceptIds,
      relatedEvidenceIds: relatedEvidenceIds ?? this.relatedEvidenceIds,
      editorialStatus: editorialStatus ?? this.editorialStatus,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
