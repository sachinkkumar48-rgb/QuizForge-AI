library;

import 'package:meta/meta.dart';
import 'case_enums.dart';

/// Production-grade domain entity representing a Landmark Constitutional Case Knowledge Object.
@immutable
class CaseKnowledgeObject {
  final String objectId;
  final String caseId;
  final String caseName;
  final String citation;
  final int year;
  final String court;
  final String bench;
  final List<String> judges;
  final CaseStatus status;
  final CourtLevel courtLevel;
  final List<String> keywords;
  final List<String> aliases;

  // Background
  final String historicalContext;
  final String facts;
  final List<String> issues;
  final List<String> petitionerArguments;
  final List<String> respondentArguments;

  // Judgment
  final String decision;
  final List<String> ratioDecidendi;
  final List<String> obiterDicta;
  final List<String> keyPrinciples;
  final String constitutionalSignificance;

  // Cross-Links & Knowledge Objects
  final List<String> relatedArticles;
  final List<String> relatedParts;
  final List<String> relatedSchedules;
  final List<String> relatedAmendments;
  final List<String> relatedActs;
  final List<String> relatedRules;
  final List<String> relatedCommittees;
  final List<String> relatedReports;
  final List<String> relatedCurrentAffairs;
  final List<String> pyqIds;
  final List<String> relatedLessons;
  final List<String> crossReferences;

  // Timeline
  final DateTime judgmentDate;
  final DateTime? filingDate;
  final List<String> timeline;
  final List<String> subsequentDevelopments;
  final String presentStatus;

  // Analytics
  final String examImportance;
  final int timesAsked;
  final int lastAskedYear;
  final String trend;
  final List<String> frequentlyConfusedCases;

  // Editorial
  final String garudaExplanation;
  final List<String> commonMistakes;
  final List<String> memoryTricks;
  final String oneLineSummary;
  final String detailedSummary;

  // Evidence & Verification
  final String primarySource;
  final List<String> citations;
  final List<String> evidenceReferences;
  final int version;
  final String reviewerId;
  final String editorialStatus;

  const CaseKnowledgeObject({
    required this.objectId,
    required this.caseId,
    required this.caseName,
    required this.citation,
    required this.year,
    this.court = 'Supreme Court of India',
    required this.bench,
    this.judges = const [],
    this.status = CaseStatus.landmarkPrecedent,
    this.courtLevel = CourtLevel.supremeCourt,
    this.keywords = const [],
    this.aliases = const [],
    required this.historicalContext,
    required this.facts,
    this.issues = const [],
    this.petitionerArguments = const [],
    this.respondentArguments = const [],
    required this.decision,
    this.ratioDecidendi = const [],
    this.obiterDicta = const [],
    this.keyPrinciples = const [],
    required this.constitutionalSignificance,
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
    this.crossReferences = const [],
    required this.judgmentDate,
    this.filingDate,
    this.timeline = const [],
    this.subsequentDevelopments = const [],
    this.presentStatus = 'Good Law / Active Precedent',
    this.examImportance = 'Critical',
    this.timesAsked = 0,
    this.lastAskedYear = 2024,
    this.trend = 'High Frequency',
    this.frequentlyConfusedCases = const [],
    required this.garudaExplanation,
    this.commonMistakes = const [],
    this.memoryTricks = const [],
    required this.oneLineSummary,
    required this.detailedSummary,
    this.primarySource = 'Supreme Court Reports (SCR) / All India Reporter (AIR)',
    this.citations = const [],
    this.evidenceReferences = const [],
    this.version = 1,
    this.reviewerId = 'CHIEF_JURISPRUDENCE_ENGINEER',
    this.editorialStatus = 'APPROVED',
  });

  Map<String, dynamic> toJson() => {
        'objectId': objectId,
        'caseId': caseId,
        'caseName': caseName,
        'citation': citation,
        'year': year,
        'court': court,
        'bench': bench,
        'judges': judges,
        'status': status.name,
        'courtLevel': courtLevel.name,
        'keywords': keywords,
        'aliases': aliases,
        'historicalContext': historicalContext,
        'facts': facts,
        'issues': issues,
        'petitionerArguments': petitionerArguments,
        'respondentArguments': respondentArguments,
        'decision': decision,
        'ratioDecidendi': ratioDecidendi,
        'obiterDicta': obiterDicta,
        'keyPrinciples': keyPrinciples,
        'constitutionalSignificance': constitutionalSignificance,
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
        'crossReferences': crossReferences,
        'judgmentDate': judgmentDate.toIso8601String(),
        'filingDate': filingDate?.toIso8601String(),
        'timeline': timeline,
        'subsequentDevelopments': subsequentDevelopments,
        'presentStatus': presentStatus,
        'examImportance': examImportance,
        'timesAsked': timesAsked,
        'lastAskedYear': lastAskedYear,
        'trend': trend,
        'frequentlyConfusedCases': frequentlyConfusedCases,
        'garudaExplanation': garudaExplanation,
        'commonMistakes': commonMistakes,
        'memoryTricks': memoryTricks,
        'oneLineSummary': oneLineSummary,
        'detailedSummary': detailedSummary,
        'primarySource': primarySource,
        'citations': citations,
        'evidenceReferences': evidenceReferences,
        'version': version,
        'reviewerId': reviewerId,
        'editorialStatus': editorialStatus,
      };

  factory CaseKnowledgeObject.fromJson(Map<String, dynamic> json) =>
      CaseKnowledgeObject(
        objectId: json['objectId'] as String? ?? '',
        caseId: json['caseId'] as String? ?? '',
        caseName: json['caseName'] as String? ?? '',
        citation: json['citation'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? 1950,
        court: json['court'] as String? ?? 'Supreme Court of India',
        bench: json['bench'] as String? ?? 'Constitution Bench',
        judges: (json['judges'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        status: CaseStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => CaseStatus.landmarkPrecedent,
        ),
        courtLevel: CourtLevel.values.firstWhere(
          (e) => e.name == json['courtLevel'],
          orElse: () => CourtLevel.supremeCourt,
        ),
        keywords: (json['keywords'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        aliases: (json['aliases'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        historicalContext: json['historicalContext'] as String? ?? '',
        facts: json['facts'] as String? ?? '',
        issues: (json['issues'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        petitionerArguments: (json['petitionerArguments'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        respondentArguments: (json['respondentArguments'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        decision: json['decision'] as String? ?? '',
        ratioDecidendi: (json['ratioDecidendi'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        obiterDicta: (json['obiterDicta'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        keyPrinciples: (json['keyPrinciples'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        constitutionalSignificance: json['constitutionalSignificance'] as String? ?? '',
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
        crossReferences: (json['crossReferences'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        judgmentDate: DateTime.tryParse(json['judgmentDate'] as String? ?? '') ?? DateTime(1950, 1, 26),
        filingDate: DateTime.tryParse(json['filingDate'] as String? ?? ''),
        timeline: (json['timeline'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        subsequentDevelopments: (json['subsequentDevelopments'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        presentStatus: json['presentStatus'] as String? ?? 'Good Law / Active Precedent',
        examImportance: json['examImportance'] as String? ?? 'Critical',
        timesAsked: (json['timesAsked'] as num?)?.toInt() ?? 0,
        lastAskedYear: (json['lastAskedYear'] as num?)?.toInt() ?? 2024,
        trend: json['trend'] as String? ?? 'High Frequency',
        frequentlyConfusedCases: (json['frequentlyConfusedCases'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        garudaExplanation: json['garudaExplanation'] as String? ?? '',
        commonMistakes: (json['commonMistakes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        memoryTricks: (json['memoryTricks'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        oneLineSummary: json['oneLineSummary'] as String? ?? '',
        detailedSummary: json['detailedSummary'] as String? ?? '',
        primarySource: json['primarySource'] as String? ?? 'Supreme Court Reports (SCR) / All India Reporter (AIR)',
        citations: (json['citations'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        evidenceReferences: (json['evidenceReferences'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        version: (json['version'] as num?)?.toInt() ?? 1,
        reviewerId: json['reviewerId'] as String? ?? 'CHIEF_JURISPRUDENCE_ENGINEER',
        editorialStatus: json['editorialStatus'] as String? ?? 'APPROVED',
      );
}
