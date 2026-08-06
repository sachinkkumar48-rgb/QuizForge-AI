library;

import 'package:meta/meta.dart';
import 'constitution_enums.dart';
import 'constitution_knowledge_object.dart';

/// Structured DTO representing an Amendment record affecting an Article.
@immutable
class ArticleAmendmentRecord {
  final String amendmentName;
  final String beforeText;
  final String afterText;
  final String reason;
  final DateTime effectiveDate;

  ArticleAmendmentRecord({
    required this.amendmentName,
    required this.beforeText,
    required this.afterText,
    required this.reason,
    required this.effectiveDate,
  });


  Map<String, dynamic> toJson() => {
        'amendmentName': amendmentName,
        'beforeText': beforeText,
        'afterText': afterText,
        'reason': reason,
        'effectiveDate': effectiveDate.toIso8601String(),
      };

  factory ArticleAmendmentRecord.fromJson(Map<String, dynamic> json) =>
      ArticleAmendmentRecord(
        amendmentName: json['amendmentName'] as String? ?? '',
        beforeText: json['beforeText'] as String? ?? '',
        afterText: json['afterText'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        effectiveDate: DateTime.tryParse(json['effectiveDate'] as String? ?? '') ??
            DateTime(1950, 1, 26),
      );
}

/// Structured DTO representing a Case Law record relevant to an Article.
@immutable
class ArticleCaseLawRecord {
  final String caseName;
  final int year;
  final String bench;
  final String legalPrinciple;
  final String importance;
  final String status;

  const ArticleCaseLawRecord({
    required this.caseName,
    required this.year,
    required this.bench,
    required this.legalPrinciple,
    required this.importance,
    this.status = 'Landmark Precedent',
  });

  Map<String, dynamic> toJson() => {
        'caseName': caseName,
        'year': year,
        'bench': bench,
        'legalPrinciple': legalPrinciple,
        'importance': importance,
        'status': status,
      };

  factory ArticleCaseLawRecord.fromJson(Map<String, dynamic> json) =>
      ArticleCaseLawRecord(
        caseName: json['caseName'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? 1950,
        bench: json['bench'] as String? ?? 'Constitutional Bench',
        legalPrinciple: json['legalPrinciple'] as String? ?? '',
        importance: json['importance'] as String? ?? '',
        status: json['status'] as String? ?? 'Landmark Precedent',
      );
}

/// Production-grade domain entity representing an Article Knowledge Object.
@immutable
class ArticleKnowledgeObject extends ConstitutionKnowledgeObject {
  final String articleNumber;
  final String officialTitle;
  final String part;
  final String chapter;
  final String originalNumber;
  final String currentNumber;
  final List<String> searchKeywords;
  final String officialConstitutionalText;
  final bool languageSupportReady;
  final String originalGarudaExplanation;
  final List<String> keyTakeaways;
  final List<String> commonMisconceptions;
  final List<String> memoryAids;
  final String historicalBackground;
  final List<String> constituentAssemblyDebates;
  final List<String> objectivesResolutionLinks;
  final List<ArticleAmendmentRecord> amendmentHistory;
  final List<ArticleCaseLawRecord> caseLaw;
  final List<String> relatedRules;
  final List<String> relatedCommittees;
  final List<String> relatedReports;
  final List<String> relatedLessons;
  final List<String> relatedFlashcards;
  final List<String> relatedRevisionNotes;
  final List<String> pyqIds;
  final List<String> recentDevelopments;
  final List<String> pendingBills;
  final List<String> supremeCourtUpdates;
  final List<String> governmentNotifications;
  final String editorialNotes;
  final List<String> learningObjectives;
  final String difficulty;
  final String examImportance;
  final List<String> revisionPoints;
  final List<String> trapAreas;
  final List<String> frequentlyConfusedWith;
  final int timesAsked;
  final int lastAskedYear;
  final String trend;
  final Map<String, int> examDistribution;
  final Map<String, int> difficultyDistribution;
  final List<String> citations;
  final String reviewerId;

  ArticleKnowledgeObject({
    required this.articleNumber,
    required this.officialTitle,
    this.part = 'Part III',
    this.chapter = 'Fundamental Rights',
    required this.originalNumber,
    required this.currentNumber,
    required this.officialConstitutionalText,
    required this.originalGarudaExplanation,
    this.historicalBackground = '',
    this.languageSupportReady = true,
    this.searchKeywords = const [],
    this.keyTakeaways = const [],
    this.commonMisconceptions = const [],
    this.memoryAids = const [],
    this.constituentAssemblyDebates = const [],
    this.objectivesResolutionLinks = const [],
    this.amendmentHistory = const [],
    this.caseLaw = const [],
    this.relatedRules = const [],
    this.relatedCommittees = const [],
    this.relatedReports = const [],
    this.relatedLessons = const [],
    this.relatedFlashcards = const [],
    this.relatedRevisionNotes = const [],
    this.pyqIds = const [],
    this.recentDevelopments = const [],
    this.pendingBills = const [],
    this.supremeCourtUpdates = const [],
    this.governmentNotifications = const [],
    this.editorialNotes = '',
    this.learningObjectives = const [],
    this.difficulty = 'High',
    this.examImportance = 'Critical',
    this.revisionPoints = const [],
    this.trapAreas = const [],
    this.frequentlyConfusedWith = const [],
    this.timesAsked = 0,
    this.lastAskedYear = 2024,
    this.trend = 'High Frequency',
    this.examDistribution = const {},
    this.difficultyDistribution = const {},
    this.citations = const [],
    this.reviewerId = 'CHIEF_CONSTITUTIONAL_ENGINEER',
    required super.objectId,
    required super.title,
    required super.officialName,
    required super.description,
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
    super.evidenceReferences = const ['Legislative Department, Ministry of Law and Justice, Government of India'],
    super.knowledgeGraphLinks = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    final base = super.toJson();
    base.addAll({
      'articleNumber': articleNumber,
      'officialTitle': officialTitle,
      'part': part,
      'chapter': chapter,
      'originalNumber': originalNumber,
      'currentNumber': currentNumber,
      'searchKeywords': searchKeywords,
      'officialConstitutionalText': officialConstitutionalText,
      'languageSupportReady': languageSupportReady,
      'originalGarudaExplanation': originalGarudaExplanation,
      'keyTakeaways': keyTakeaways,
      'commonMisconceptions': commonMisconceptions,
      'memoryAids': memoryAids,
      'historicalBackground': historicalBackground,
      'constituentAssemblyDebates': constituentAssemblyDebates,
      'objectivesResolutionLinks': objectivesResolutionLinks,
      'amendmentHistory': amendmentHistory.map((e) => e.toJson()).toList(),
      'caseLaw': caseLaw.map((e) => e.toJson()).toList(),
      'relatedRules': relatedRules,
      'relatedCommittees': relatedCommittees,
      'relatedReports': relatedReports,
      'relatedLessons': relatedLessons,
      'relatedFlashcards': relatedFlashcards,
      'relatedRevisionNotes': relatedRevisionNotes,
      'pyqIds': pyqIds,
      'recentDevelopments': recentDevelopments,
      'pendingBills': pendingBills,
      'supremeCourtUpdates': supremeCourtUpdates,
      'governmentNotifications': governmentNotifications,
      'editorialNotes': editorialNotes,
      'learningObjectives': learningObjectives,
      'difficulty': difficulty,
      'examImportance': examImportance,
      'revisionPoints': revisionPoints,
      'trapAreas': trapAreas,
      'frequentlyConfusedWith': frequentlyConfusedWith,
      'timesAsked': timesAsked,
      'lastAskedYear': lastAskedYear,
      'trend': trend,
      'examDistribution': examDistribution,
      'difficultyDistribution': difficultyDistribution,
      'citations': citations,
      'reviewerId': reviewerId,
    });
    return base;
  }

  factory ArticleKnowledgeObject.fromJson(Map<String, dynamic> json) {
    final base = ConstitutionKnowledgeObject.fromJson(json);
    return ArticleKnowledgeObject(
      objectId: base.objectId,
      title: base.title,
      officialName: base.officialName,
      description: base.description,
      articleNumber: json['articleNumber'] as String? ?? '',
      officialTitle: json['officialTitle'] as String? ?? '',
      part: json['part'] as String? ?? 'Part III',
      chapter: json['chapter'] as String? ?? 'Fundamental Rights',
      originalNumber: json['originalNumber'] as String? ?? '',
      currentNumber: json['currentNumber'] as String? ?? '',
      searchKeywords: (json['searchKeywords'] as List?)?.map((e) => e.toString()).toList() ?? base.keywords,
      officialConstitutionalText: json['officialConstitutionalText'] as String? ?? base.description,
      languageSupportReady: json['languageSupportReady'] as bool? ?? true,
      originalGarudaExplanation: json['originalGarudaExplanation'] as String? ?? '',
      keyTakeaways: (json['keyTakeaways'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      commonMisconceptions: (json['commonMisconceptions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      memoryAids: (json['memoryAids'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      historicalBackground: json['historicalBackground'] as String? ?? '',
      constituentAssemblyDebates: (json['constituentAssemblyDebates'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      objectivesResolutionLinks: (json['objectivesResolutionLinks'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      amendmentHistory: (json['amendmentHistory'] as List?)
              ?.map((e) => ArticleAmendmentRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      caseLaw: (json['caseLaw'] as List?)
              ?.map((e) => ArticleCaseLawRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      relatedRules: (json['relatedRules'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      relatedCommittees: (json['relatedCommittees'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      relatedReports: (json['relatedReports'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      relatedLessons: (json['relatedLessons'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      relatedFlashcards: (json['relatedFlashcards'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      relatedRevisionNotes: (json['relatedRevisionNotes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      pyqIds: (json['pyqIds'] as List?)?.map((e) => e.toString()).toList() ?? base.relatedPYQs,
      recentDevelopments: (json['recentDevelopments'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      pendingBills: (json['pendingBills'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      supremeCourtUpdates: (json['supremeCourtUpdates'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      governmentNotifications: (json['governmentNotifications'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      editorialNotes: json['editorialNotes'] as String? ?? '',
      learningObjectives: (json['learningObjectives'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      difficulty: json['difficulty'] as String? ?? 'High',
      examImportance: json['examImportance'] as String? ?? 'Critical',
      revisionPoints: (json['revisionPoints'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      trapAreas: (json['trapAreas'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      frequentlyConfusedWith: (json['frequentlyConfusedWith'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      timesAsked: (json['timesAsked'] as num?)?.toInt() ?? 0,
      lastAskedYear: (json['lastAskedYear'] as num?)?.toInt() ?? 2024,
      trend: json['trend'] as String? ?? 'High Frequency',
      examDistribution: (json['examDistribution'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? const {},
      difficultyDistribution: (json['difficultyDistribution'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? const {},
      citations: (json['citations'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      reviewerId: json['reviewerId'] as String? ?? 'CHIEF_CONSTITUTIONAL_ENGINEER',
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
