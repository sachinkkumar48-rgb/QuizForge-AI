library;

import 'package:meta/meta.dart';
import 'constitution_enums.dart';
import 'constitution_knowledge_object.dart';

/// Production-grade domain entity representing a Constitutional Chapter Knowledge Object.
@immutable
class ChapterKnowledgeObject extends ConstitutionKnowledgeObject {
  final String chapterNumber;
  final String partNumber;
  final List<String> articlesCovered;

  const ChapterKnowledgeObject({
    required this.chapterNumber,
    required this.partNumber,
    required super.objectId,
    required super.title,
    required super.officialName,
    required super.description,
    required this.articlesCovered,
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
      'chapterNumber': chapterNumber,
      'partNumber': partNumber,
      'articlesCovered': articlesCovered,
    });
    return base;
  }

  factory ChapterKnowledgeObject.fromJson(Map<String, dynamic> json) {
    final base = ConstitutionKnowledgeObject.fromJson(json);

    return ChapterKnowledgeObject(
      chapterNumber: json['chapterNumber'] as String? ?? '',
      partNumber: json['partNumber'] as String? ?? '',
      objectId: base.objectId,
      title: base.title,
      officialName: base.officialName,
      description: base.description,
      articlesCovered: (json['articlesCovered'] as List?)?.map((e) => e.toString()).toList() ?? base.relatedArticles,
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
