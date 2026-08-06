library;

import '../domain/entities/article_knowledge_object.dart';
import '../domain/entities/constitution_enums.dart';
import '../domain/entities/constitution_knowledge_object.dart';
import '../domain/entities/part_knowledge_object.dart';
import '../domain/entities/preamble_knowledge_object.dart';
import '../domain/entities/schedule_knowledge_object.dart';

/// Editorial Schema Templates for reusing standard structures across Preamble, Part, Schedule, Article, and Amendment creation.

class PreambleTemplate {
  static PreambleKnowledgeObject create({
    required String officialText,
    required List<String> objectives,
    required String historicalBackground,
    required List<String> constituentAssemblyReferences,
    required List<String> fortySecondAmendmentChanges,
    required List<String> relevantJudgments,
    required String editorialNotes,
    List<String> keywords = const [],
    List<String> aliases = const [],
    List<String> timeline = const [],
    List<String> crossReferences = const [],
    List<String> relatedArticles = const [],
    List<String> relatedAmendments = const [],
    List<String> relatedPYQs = const [],
    List<String> relatedCurrentAffairs = const [],
    List<String> evidenceReferences = const [],
    List<String> knowledgeGraphLinks = const [],
  }) {
    return PreambleKnowledgeObject(
      objectId: 'KO_CONST_PREAMBLE',
      title: 'Preamble to the Constitution of India',
      officialName: 'Preamble',
      description: officialText,
      officialText: officialText,
      objectives: objectives,
      historicalBackground: historicalBackground,
      constituentAssemblyReferences: constituentAssemblyReferences,
      fortySecondAmendmentChanges: fortySecondAmendmentChanges,
      relevantJudgments: relevantJudgments,
      editorialNotes: editorialNotes,
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      keywords: keywords,
      aliases: aliases,
      timeline: timeline,
      crossReferences: crossReferences,
      relatedArticles: relatedArticles,
      relatedAmendments: relatedAmendments,
      relatedCases: relevantJudgments,
      relatedPYQs: relatedPYQs,
      relatedCurrentAffairs: relatedCurrentAffairs,
      editorialStatus: 'APPROVED',
      evidenceReferences: evidenceReferences,
      knowledgeGraphLinks: knowledgeGraphLinks,
    );
  }
}

class PartTemplate {
  static PartKnowledgeObject create({
    required String partNumber,
    required String title,
    required String officialName,
    required String description,
    required List<String> articlesRange,
    PartType type = PartType.corePart,
    ConstitutionStatus status = ConstitutionStatus.active,
    List<String> keywords = const [],
    List<String> aliases = const [],
    List<String> timeline = const [],
    List<String> crossReferences = const [],
    List<String> relatedParts = const [],
    List<String> relatedSchedules = const [],
    List<String> relatedAmendments = const [],
    List<String> relatedCases = const [],
    List<String> relatedActs = const [],
    List<String> relatedPYQs = const [],
    List<String> evidenceReferences = const [],
    List<String> knowledgeGraphLinks = const [],
  }) {
    return PartKnowledgeObject(
      partNumber: partNumber,
      objectId: 'KO-PART-$partNumber',
      title: 'Part $partNumber: $title',
      officialName: officialName,
      description: description,
      purpose: description,
      articlesCovered: articlesRange,
      partType: type,
      status: status,
      effectiveDate: DateTime(1950, 1, 26),
      keywords: ['Part $partNumber', title, ...keywords],
      aliases: aliases,
      timeline: timeline,
      crossReferences: crossReferences,
      relatedArticles: articlesRange,
      relatedParts: relatedParts,
      relatedSchedules: relatedSchedules,
      relatedAmendments: relatedAmendments,
      relatedCases: relatedCases,
      relatedActs: relatedActs,
      relatedPYQs: relatedPYQs,
      editorialStatus: 'APPROVED',
      evidenceReferences: evidenceReferences,
      knowledgeGraphLinks: knowledgeGraphLinks,
    );
  }
}

class ScheduleTemplate {
  static ScheduleKnowledgeObject create({
    required String scheduleNumber,
    required String title,
    required String officialName,
    required String description,
    required ScheduleType type,
    ConstitutionStatus status = ConstitutionStatus.active,
    List<String> keywords = const [],
    List<String> aliases = const [],
    List<String> timeline = const [],
    List<String> crossReferences = const [],
    List<String> relatedArticles = const [],
    List<String> relatedParts = const [],
    List<String> relatedAmendments = const [],
    List<String> relatedCases = const [],
    List<String> relatedActs = const [],
    List<String> relatedPYQs = const [],
    List<String> evidenceReferences = const [],
    List<String> knowledgeGraphLinks = const [],
  }) {
    return ScheduleKnowledgeObject(
      scheduleNumber: scheduleNumber,
      objectId: 'KO-SCHED-$scheduleNumber',
      title: 'Schedule $scheduleNumber: $title',
      officialName: officialName,
      description: description,
      purpose: description,
      scheduleType: type,
      status: status,
      effectiveDate: DateTime(1950, 1, 26),
      keywords: ['Schedule $scheduleNumber', title, ...keywords],
      aliases: aliases,
      timeline: timeline,
      crossReferences: crossReferences,
      relatedArticles: relatedArticles,
      relatedParts: relatedParts,
      relatedAmendments: relatedAmendments,
      relatedCases: relatedCases,
      relatedActs: relatedActs,
      relatedPYQs: relatedPYQs,
      editorialStatus: 'APPROVED',
      evidenceReferences: evidenceReferences,
      knowledgeGraphLinks: knowledgeGraphLinks,
    );
  }
}

class ArticleTemplate {
  static ArticleKnowledgeObject create({
    required String articleNumber,
    required String title,
    required String officialText,
    String garudaExplanation = '',
    String historicalBackground = '',
    String partId = 'KO-PART-III',
    ConstitutionStatus status = ConstitutionStatus.active,
    List<String> keywords = const [],
    List<String> aliases = const [],
    List<String> keyTakeaways = const [],
    List<String> commonMisconceptions = const [],
    List<String> memoryAids = const [],
    List<String> constituentAssemblyDebates = const [],
    List<ArticleAmendmentRecord> amendmentHistory = const [],
    List<ArticleCaseLawRecord> caseLaw = const [],
    List<String> relatedArticles = const [],
    List<String> relatedAmendments = const [],
    List<String> relatedCases = const [],
    List<String> relatedActs = const [],
    List<String> relatedPYQs = const [],
    List<String> learningObjectives = const [],
    List<String> revisionPoints = const [],
    List<String> trapAreas = const [],
    List<String> evidenceReferences = const [],
    List<String> knowledgeGraphLinks = const [],
    String editorialStatus = 'TEMPLATE_DRAFT',
  }) {
    return ArticleKnowledgeObject(
      articleNumber: articleNumber,
      officialTitle: title,
      originalNumber: articleNumber,
      currentNumber: articleNumber,
      objectId: 'KO-ART-$articleNumber',
      title: 'Article $articleNumber: $title',
      officialName: 'Article $articleNumber',
      description: officialText,
      officialConstitutionalText: officialText,
      originalGarudaExplanation: garudaExplanation.isEmpty ? officialText : garudaExplanation,
      historicalBackground: historicalBackground,
      status: status,
      effectiveDate: DateTime(1950, 1, 26),
      keywords: ['Article $articleNumber', title, ...keywords],
      aliases: aliases,
      keyTakeaways: keyTakeaways,
      commonMisconceptions: commonMisconceptions,
      memoryAids: memoryAids,
      constituentAssemblyDebates: constituentAssemblyDebates,
      amendmentHistory: amendmentHistory,
      caseLaw: caseLaw,
      relatedParts: [partId],
      relatedArticles: relatedArticles,
      relatedAmendments: relatedAmendments,
      relatedCases: relatedCases,
      relatedActs: relatedActs,
      relatedPYQs: relatedPYQs,
      pyqIds: relatedPYQs,
      learningObjectives: learningObjectives,
      revisionPoints: revisionPoints,
      trapAreas: trapAreas,
      editorialStatus: editorialStatus,
      evidenceReferences: evidenceReferences,
      knowledgeGraphLinks: knowledgeGraphLinks,
    );
  }
}

class AmendmentTemplate {
  static ConstitutionKnowledgeObject create({
    required String amendmentNumber,
    required String actTitle,
    required DateTime dateEnacted,
    required String summary,
    List<String> affectedArticles = const [],
    List<String> affectedParts = const [],
    List<String> affectedSchedules = const [],
  }) {
    return ConstitutionKnowledgeObject(
      objectId: 'KO-AMD-$amendmentNumber',
      title: '$amendmentNumber Amendment Act',
      officialName: actTitle,
      description: summary,
      status: ConstitutionStatus.active,
      effectiveDate: dateEnacted,
      keywords: ['$amendmentNumber Amendment', actTitle],
      relatedArticles: affectedArticles,
      relatedParts: affectedParts,
      relatedSchedules: affectedSchedules,
      editorialStatus: 'TEMPLATE_DRAFT',
    );
  }
}
