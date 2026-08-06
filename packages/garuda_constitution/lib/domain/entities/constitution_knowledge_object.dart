library;

import 'package:meta/meta.dart';
import 'constitution_enums.dart';

/// Immutable domain entity representing a Constitutional Knowledge Object.
@immutable
class ConstitutionKnowledgeObject {
  final String objectId;
  final String title;
  final String officialName;
  final String description;
  final String officialSource;
  final ConstitutionStatus status;
  final int version;
  final DateTime effectiveDate;
  final List<String> keywords;
  final List<String> aliases;
  final List<String> timeline;
  final List<String> crossReferences;
  final List<String> relatedParts;
  final List<String> relatedSchedules;
  final List<String> relatedArticles;
  final List<String> relatedAmendments;
  final List<String> relatedCases;
  final List<String> relatedActs;
  final List<String> relatedPYQs;
  final List<String> relatedCurrentAffairs;
  final String editorialStatus;
  final List<String> evidenceReferences;
  final List<String> knowledgeGraphLinks;

  const ConstitutionKnowledgeObject({
    required this.objectId,
    required this.title,
    required this.officialName,
    required this.description,
    this.officialSource = 'Legislative Department, Ministry of Law and Justice',
    this.status = ConstitutionStatus.active,
    this.version = 1,
    required this.effectiveDate,
    this.keywords = const [],
    this.aliases = const [],
    this.timeline = const [],
    this.crossReferences = const [],
    this.relatedParts = const [],
    this.relatedSchedules = const [],
    this.relatedArticles = const [],
    this.relatedAmendments = const [],
    this.relatedCases = const [],
    this.relatedActs = const [],
    this.relatedPYQs = const [],
    this.relatedCurrentAffairs = const [],
    this.editorialStatus = 'APPROVED',
    this.evidenceReferences = const [],
    this.knowledgeGraphLinks = const [],
  });

  /// Convenience aliases for amendments
  List<String> get affectedParts => relatedParts;
  List<String> get affectedArticles => relatedArticles;
  List<String> get affectedSchedules => relatedSchedules;

  ConstitutionKnowledgeObject copyWith({
    String? objectId,
    String? title,
    String? officialName,
    String? description,
    String? officialSource,
    ConstitutionStatus? status,
    int? version,
    DateTime? effectiveDate,
    List<String>? keywords,
    List<String>? aliases,
    List<String>? timeline,
    List<String>? crossReferences,
    List<String>? relatedParts,
    List<String>? relatedSchedules,
    List<String>? relatedArticles,
    List<String>? relatedAmendments,
    List<String>? relatedCases,
    List<String>? relatedActs,
    List<String>? relatedPYQs,
    List<String>? relatedCurrentAffairs,
    String? editorialStatus,
    List<String>? evidenceReferences,
    List<String>? knowledgeGraphLinks,
  }) {
    return ConstitutionKnowledgeObject(
      objectId: objectId ?? this.objectId,
      title: title ?? this.title,
      officialName: officialName ?? this.officialName,
      description: description ?? this.description,
      officialSource: officialSource ?? this.officialSource,
      status: status ?? this.status,
      version: version ?? this.version,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      keywords: keywords ?? List.from(this.keywords),
      aliases: aliases ?? List.from(this.aliases),
      timeline: timeline ?? List.from(this.timeline),
      crossReferences: crossReferences ?? List.from(this.crossReferences),
      relatedParts: relatedParts ?? List.from(this.relatedParts),
      relatedSchedules: relatedSchedules ?? List.from(this.relatedSchedules),
      relatedArticles: relatedArticles ?? List.from(this.relatedArticles),
      relatedAmendments: relatedAmendments ?? List.from(this.relatedAmendments),
      relatedCases: relatedCases ?? List.from(this.relatedCases),
      relatedActs: relatedActs ?? List.from(this.relatedActs),
      relatedPYQs: relatedPYQs ?? List.from(this.relatedPYQs),
      relatedCurrentAffairs: relatedCurrentAffairs ?? List.from(this.relatedCurrentAffairs),
      editorialStatus: editorialStatus ?? this.editorialStatus,
      evidenceReferences: evidenceReferences ?? List.from(this.evidenceReferences),
      knowledgeGraphLinks: knowledgeGraphLinks ?? List.from(this.knowledgeGraphLinks),
    );
  }

  Map<String, dynamic> toJson() => {
        'objectId': objectId,
        'title': title,
        'officialName': officialName,
        'description': description,
        'officialSource': officialSource,
        'status': status.name,
        'version': version,
        'effectiveDate': effectiveDate.toIso8601String(),
        'keywords': keywords,
        'aliases': aliases,
        'timeline': timeline,
        'crossReferences': crossReferences,
        'relatedParts': relatedParts,
        'relatedSchedules': relatedSchedules,
        'relatedArticles': relatedArticles,
        'relatedAmendments': relatedAmendments,
        'relatedCases': relatedCases,
        'relatedActs': relatedActs,
        'relatedPYQs': relatedPYQs,
        'relatedCurrentAffairs': relatedCurrentAffairs,
        'editorialStatus': editorialStatus,
        'evidenceReferences': evidenceReferences,
        'knowledgeGraphLinks': knowledgeGraphLinks,
      };

  factory ConstitutionKnowledgeObject.fromJson(Map<String, dynamic> json) =>
      ConstitutionKnowledgeObject(
        objectId: json['objectId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        officialName: json['officialName'] as String? ?? '',
        description: json['description'] as String? ?? '',
        officialSource: json['officialSource'] as String? ??
            'Legislative Department, Ministry of Law and Justice',
        status: ConstitutionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ConstitutionStatus.active,
        ),
        version: (json['version'] as num?)?.toInt() ?? 1,
        effectiveDate:
            DateTime.tryParse(json['effectiveDate'] as String? ?? '') ??
                DateTime(1950, 1, 26),
        keywords: (json['keywords'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        aliases: (json['aliases'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        timeline: (json['timeline'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        crossReferences: (json['crossReferences'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedParts: (json['relatedParts'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedSchedules: (json['relatedSchedules'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedArticles: (json['relatedArticles'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedAmendments: (json['relatedAmendments'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedCases: (json['relatedCases'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedActs: (json['relatedActs'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedPYQs: (json['relatedPYQs'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedCurrentAffairs: (json['relatedCurrentAffairs'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        editorialStatus: json['editorialStatus'] as String? ?? 'APPROVED',
        evidenceReferences: (json['evidenceReferences'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        knowledgeGraphLinks: (json['knowledgeGraphLinks'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConstitutionKnowledgeObject &&
        other.objectId == objectId &&
        other.version == version;
  }

  @override
  int get hashCode => Object.hash(objectId, version);
}
