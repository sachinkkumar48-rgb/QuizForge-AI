library;

import 'package:meta/meta.dart';
import 'constitution_enums.dart';
import 'constitution_knowledge_object.dart';

/// Production-grade domain entity representing a Constitutional Amendment Knowledge Object.
@immutable
class AmendmentKnowledgeObject extends ConstitutionKnowledgeObject {
  final String amendmentNumber;
  final int year;
  final String reason;
  final String historicalContext;
  final List<String> articlesAffected;
  final List<String> schedulesAffected;

  const AmendmentKnowledgeObject({
    required this.amendmentNumber,
    required this.year,
    required super.objectId,
    required super.title,
    required super.officialName,
    required super.description,
    required this.reason,
    this.historicalContext = '',
    this.articlesAffected = const [],
    this.schedulesAffected = const [],
    super.officialSource = 'Legislative Department, Ministry of Law and Justice',
    super.status = ConstitutionStatus.active,
    super.version = 1,
    required super.effectiveDate,
    super.keywords = const [],
    super.aliases = const [],
    super.timeline = const [],
    super.crossReferences = const [],
    super.relatedParts = const [],
    super.relatedSchedules = const [],
    super.relatedArticles = const [],
    super.relatedAmendments = const [],
    super.relatedCases = const [],
    super.relatedActs = const [],
    super.relatedPYQs = const [],
    super.relatedCurrentAffairs = const [],
    super.editorialStatus = 'Editorial Review',
    super.evidenceReferences = const [],
    super.knowledgeGraphLinks = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    final base = super.toJson();
    base.addAll({
      'amendmentNumber': amendmentNumber,
      'year': year,
      'reason': reason,
      'historicalContext': historicalContext,
      'articlesAffected': articlesAffected,
      'schedulesAffected': schedulesAffected,
    });
    return base;
  }

  factory AmendmentKnowledgeObject.fromJson(Map<String, dynamic> json) {
    final base = ConstitutionKnowledgeObject.fromJson(json);

    return AmendmentKnowledgeObject(
      amendmentNumber: json['amendmentNumber'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 1951,
      objectId: base.objectId,
      title: base.title,
      officialName: base.officialName,
      description: base.description,
      reason: json['reason'] as String? ?? base.description,
      historicalContext: json['historicalContext'] as String? ?? '',
      articlesAffected: (json['articlesAffected'] as List?)?.map((e) => e.toString()).toList() ?? base.relatedArticles,
      schedulesAffected: (json['schedulesAffected'] as List?)?.map((e) => e.toString()).toList() ?? base.relatedSchedules,
      officialSource: base.officialSource,
      status: base.status,
      version: base.version,
      effectiveDate: base.effectiveDate,
      keywords: base.keywords,
      aliases: base.aliases,
      timeline: base.timeline,
      crossReferences: base.crossReferences,
      relatedParts: base.relatedParts,
      relatedSchedules: base.relatedSchedules,
      relatedArticles: base.relatedArticles,
      relatedAmendments: base.relatedAmendments,
      relatedCases: base.relatedCases,
      relatedActs: base.relatedActs,
      relatedPYQs: base.relatedPYQs,
      relatedCurrentAffairs: base.relatedCurrentAffairs,
      editorialStatus: base.editorialStatus,
      evidenceReferences: base.evidenceReferences,
      knowledgeGraphLinks: base.knowledgeGraphLinks,
    );
  }
}
