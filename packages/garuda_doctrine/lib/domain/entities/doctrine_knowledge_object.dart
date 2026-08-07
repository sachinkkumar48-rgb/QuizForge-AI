library;

import 'package:meta/meta.dart';
import 'doctrine_enums.dart';

/// Production-grade domain entity representing an Independent Constitutional Doctrine Knowledge Object.
@immutable
class DoctrineKnowledgeObject {
  final String objectId;
  final String doctrineId;
  final String name;
  final List<String> aliases;
  final DoctrineCategory category;
  final String origin;
  final DoctrineStatus currentStatus;
  final int version;

  // Definition
  final String officialDefinition;
  final String plainLanguageExplanation;
  final String purpose;
  final String scope;
  final List<String> limitations;

  // Origin
  final String originatingCase;
  final String historicalContext;
  final String evolution;
  final List<String> importantMilestones;

  // Legal Development
  final List<String> landmarkCases;
  final List<String> subsequentCases;
  final List<String> expandedBy;
  final List<String> limitedBy;
  final List<String> distinguishedIn;
  final String currentPosition;

  // Constitution Links
  final List<String> relatedArticles;
  final List<String> relatedParts;
  final List<String> relatedSchedules;
  final List<String> relatedAmendments;

  // Other Links
  final List<String> relatedActs;
  final List<String> relatedRules;
  final List<String> relatedCommittees;
  final List<String> relatedReports;
  final List<String> relatedCurrentAffairs;
  final List<String> pyqIds;
  final List<String> relatedLessons;
  final List<String> relatedRevisionNotes;
  final List<String> relatedFlashcards;
  final List<String> crossReferences;

  // Analytics
  final String examImportance;
  final int timesAsked;
  final int lastAskedYear;
  final String trend;
  final List<String> frequentlyConfusedDoctrines;
  final String difficulty;

  // Editorial
  final String garudaExplanation;
  final String oneLineSummary;
  final String detailedExplanation;
  final List<String> commonMistakes;
  final List<String> memoryTechniques;
  final List<String> frequentlyAskedAreas;

  // Evidence & Verification
  final String primarySource;
  final List<String> citations;
  final List<String> evidenceReferences;
  final String reviewerId;
  final String editorialStatus;

  const DoctrineKnowledgeObject({
    required this.objectId,
    required this.doctrineId,
    required this.name,
    this.aliases = const [],
    this.category = DoctrineCategory.constitutionalInterpretation,
    required this.origin,
    this.currentStatus = DoctrineStatus.settledLaw,
    this.version = 1,
    required this.officialDefinition,
    required this.plainLanguageExplanation,
    required this.purpose,
    required this.scope,
    this.limitations = const [],
    required this.originatingCase,
    required this.historicalContext,
    required this.evolution,
    this.importantMilestones = const [],
    this.landmarkCases = const [],
    this.subsequentCases = const [],
    this.expandedBy = const [],
    this.limitedBy = const [],
    this.distinguishedIn = const [],
    required this.currentPosition,
    this.relatedArticles = const [],
    this.relatedParts = const [],
    this.relatedSchedules = const [],
    this.relatedAmendments = const [],
    this.relatedActs = const [],
    this.relatedRules = const [],
    this.relatedCommittees = const [],
    this.relatedReports = const [],
    this.relatedCurrentAffairs = const [],
    this.pyqIds = const [],
    this.relatedLessons = const [],
    this.relatedRevisionNotes = const [],
    this.relatedFlashcards = const [],
    this.crossReferences = const [],
    this.examImportance = 'Critical',
    this.timesAsked = 0,
    this.lastAskedYear = 2024,
    this.trend = 'High Frequency',
    this.frequentlyConfusedDoctrines = const [],
    this.difficulty = 'High',
    this.garudaExplanation = '',
    required this.oneLineSummary,
    required this.detailedExplanation,
    this.commonMistakes = const [],
    this.memoryTechniques = const [],
    this.frequentlyAskedAreas = const [],
    this.primarySource = 'Supreme Court Reports (SCR) / Constitutional Jurisprudence',
    this.citations = const [],
    this.evidenceReferences = const [],
    this.reviewerId = 'CHIEF_DOCTRINE_ENGINEER',
    this.editorialStatus = 'APPROVED',
  });

  String get detailedSummary => detailedExplanation;

  Map<String, dynamic> toJson() => {
        'objectId': objectId,
        'doctrineId': doctrineId,
        'name': name,
        'aliases': aliases,
        'category': category.name,
        'origin': origin,
        'currentStatus': currentStatus.name,
        'version': version,
        'officialDefinition': officialDefinition,
        'plainLanguageExplanation': plainLanguageExplanation,
        'purpose': purpose,
        'scope': scope,
        'limitations': limitations,
        'originatingCase': originatingCase,
        'historicalContext': historicalContext,
        'evolution': evolution,
        'importantMilestones': importantMilestones,
        'landmarkCases': landmarkCases,
        'subsequentCases': subsequentCases,
        'expandedBy': expandedBy,
        'limitedBy': limitedBy,
        'distinguishedIn': distinguishedIn,
        'currentPosition': currentPosition,
        'relatedArticles': relatedArticles,
        'relatedParts': relatedParts,
        'relatedSchedules': relatedSchedules,
        'relatedAmendments': relatedAmendments,
        'relatedActs': relatedActs,
        'relatedRules': relatedRules,
        'relatedCommittees': relatedCommittees,
        'relatedReports': relatedReports,
        'relatedCurrentAffairs': relatedCurrentAffairs,
        'pyqIds': pyqIds,
        'relatedLessons': relatedLessons,
        'relatedRevisionNotes': relatedRevisionNotes,
        'relatedFlashcards': relatedFlashcards,
        'crossReferences': crossReferences,
        'examImportance': examImportance,
        'timesAsked': timesAsked,
        'lastAskedYear': lastAskedYear,
        'trend': trend,
        'frequentlyConfusedDoctrines': frequentlyConfusedDoctrines,
        'difficulty': difficulty,
        'garudaExplanation': garudaExplanation,
        'oneLineSummary': oneLineSummary,
        'detailedExplanation': detailedExplanation,
        'commonMistakes': commonMistakes,
        'memoryTechniques': memoryTechniques,
        'frequentlyAskedAreas': frequentlyAskedAreas,
        'primarySource': primarySource,
        'citations': citations,
        'evidenceReferences': evidenceReferences,
        'reviewerId': reviewerId,
        'editorialStatus': editorialStatus,
      };

  factory DoctrineKnowledgeObject.fromJson(Map<String, dynamic> json) =>
      DoctrineKnowledgeObject(
        objectId: json['objectId'] as String? ?? '',
        doctrineId: json['doctrineId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        aliases: (json['aliases'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        category: DoctrineCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => DoctrineCategory.constitutionalInterpretation,
        ),
        origin: json['origin'] as String? ?? '',
        currentStatus: DoctrineStatus.values.firstWhere(
          (e) => e.name == json['currentStatus'],
          orElse: () => DoctrineStatus.settledLaw,
        ),
        version: (json['version'] as num?)?.toInt() ?? 1,
        officialDefinition: json['officialDefinition'] as String? ?? '',
        plainLanguageExplanation: json['plainLanguageExplanation'] as String? ?? '',
        purpose: json['purpose'] as String? ?? '',
        scope: json['scope'] as String? ?? '',
        limitations: (json['limitations'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        originatingCase: json['originatingCase'] as String? ?? '',
        historicalContext: json['historicalContext'] as String? ?? '',
        evolution: json['evolution'] as String? ?? '',
        importantMilestones: (json['importantMilestones'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        landmarkCases: (json['landmarkCases'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        subsequentCases: (json['subsequentCases'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        expandedBy: (json['expandedBy'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        limitedBy: (json['limitedBy'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        distinguishedIn: (json['distinguishedIn'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        currentPosition: json['currentPosition'] as String? ?? '',
        relatedArticles: (json['relatedArticles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedParts: (json['relatedParts'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedSchedules: (json['relatedSchedules'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedAmendments: (json['relatedAmendments'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedActs: (json['relatedActs'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedRules: (json['relatedRules'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedCommittees: (json['relatedCommittees'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedReports: (json['relatedReports'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedCurrentAffairs: (json['relatedCurrentAffairs'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        pyqIds: (json['pyqIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedLessons: (json['relatedLessons'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedRevisionNotes: (json['relatedRevisionNotes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedFlashcards: (json['relatedFlashcards'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        crossReferences: (json['crossReferences'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        examImportance: json['examImportance'] as String? ?? 'Critical',
        timesAsked: (json['timesAsked'] as num?)?.toInt() ?? 0,
        lastAskedYear: (json['lastAskedYear'] as num?)?.toInt() ?? 2024,
        trend: json['trend'] as String? ?? 'High Frequency',
        frequentlyConfusedDoctrines: (json['frequentlyConfusedDoctrines'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        difficulty: json['difficulty'] as String? ?? 'High',
        garudaExplanation: json['garudaExplanation'] as String? ?? '',
        oneLineSummary: json['oneLineSummary'] as String? ?? '',
        detailedExplanation: json['detailedExplanation'] as String? ?? json['detailedSummary'] as String? ?? '',
        commonMistakes: (json['commonMistakes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        memoryTechniques: (json['memoryTechniques'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        frequentlyAskedAreas: (json['frequentlyAskedAreas'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        primarySource: json['primarySource'] as String? ?? 'Supreme Court Reports (SCR)',
        citations: (json['citations'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        evidenceReferences: (json['evidenceReferences'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        reviewerId: json['reviewerId'] as String? ?? 'CHIEF_DOCTRINE_ENGINEER',
        editorialStatus: json['editorialStatus'] as String? ?? 'APPROVED',
      );
}
