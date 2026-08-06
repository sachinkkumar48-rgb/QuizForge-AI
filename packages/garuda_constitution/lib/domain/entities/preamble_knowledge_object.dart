library;

import 'package:meta/meta.dart';
import 'constitution_enums.dart';
import 'constitution_knowledge_object.dart';

/// Production-grade domain entity representing the Preamble Knowledge Object.
@immutable
class PreambleKnowledgeObject extends ConstitutionKnowledgeObject {
  final String officialText;
  final List<String> objectives;
  final String historicalBackground;
  final List<String> constituentAssemblyReferences;
  final List<String> fortySecondAmendmentChanges;
  final List<String> relevantJudgments;
  final String editorialNotes;

  const PreambleKnowledgeObject({
    super.objectId = 'KO_CONST_PREAMBLE',
    super.title = 'Preamble to the Constitution of India',
    super.officialName = 'Preamble',
    required super.description,
    required this.officialText,
    required this.objectives,
    required this.historicalBackground,
    required this.constituentAssemblyReferences,
    required this.fortySecondAmendmentChanges,
    required this.relevantJudgments,
    required this.editorialNotes,
    super.officialSource = 'Constituent Assembly of India / Gazette of India / Ministry of Law and Justice',
    super.status = ConstitutionStatus.active,
    super.version = 1,
    required super.effectiveDate,
    super.keywords = const [],
    super.aliases = const ['Preamble', 'Identity Card of the Constitution', 'Key to the Constitution'],
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
    super.editorialStatus = 'APPROVED',
    super.evidenceReferences = const [],
    super.knowledgeGraphLinks = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    final base = super.toJson();
    base.addAll({
      'officialText': officialText,
      'objectives': objectives,
      'historicalBackground': historicalBackground,
      'constituentAssemblyReferences': constituentAssemblyReferences,
      'fortySecondAmendmentChanges': fortySecondAmendmentChanges,
      'relevantJudgments': relevantJudgments,
      'editorialNotes': editorialNotes,
    });
    return base;
  }

  factory PreambleKnowledgeObject.fromJson(Map<String, dynamic> json) {
    final base = ConstitutionKnowledgeObject.fromJson(json);
    return PreambleKnowledgeObject(
      objectId: base.objectId,
      title: base.title,
      officialName: base.officialName,
      description: base.description,
      officialText: json['officialText'] as String? ?? base.description,
      objectives: (json['objectives'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      historicalBackground: json['historicalBackground'] as String? ?? '',
      constituentAssemblyReferences:
          (json['constituentAssemblyReferences'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      fortySecondAmendmentChanges:
          (json['fortySecondAmendmentChanges'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      relevantJudgments: (json['relevantJudgments'] as List?)?.map((e) => e.toString()).toList() ?? base.relatedCases,
      editorialNotes: json['editorialNotes'] as String? ?? '',
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
