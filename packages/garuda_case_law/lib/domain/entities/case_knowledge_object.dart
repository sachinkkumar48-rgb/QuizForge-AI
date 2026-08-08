library;

import 'package:garuda_editor/garuda_editor.dart' show EditorialStatus, KnowledgeObject;
import 'package:meta/meta.dart';
import 'case_enums.dart';
import 'precedent_relationship.dart';

/// Production-grade domain entity representing a Landmark Case Knowledge Object.
/// Every judgment is a first-class, evidence-backed, searchable Knowledge
/// Object connected to the Constitution, Acts, Doctrines, Committees, Reports,
/// Bodies, Schemes, International Organisations, Current Affairs and PYQs.
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

  // ---------------------------------------------------------------------------
  // TITAN-KO-015.0 expansion
  // ---------------------------------------------------------------------------

  /// Neutral citation, e.g. "(1973) 4 SCC 225".
  final String neutralCitation;

  /// Reporter citation alias (SCR / AIR / SCC).
  final String reporterCitation;

  /// Number of judges on the bench (0 when unstated).
  final int benchStrength;

  /// Title of the judgment as reported.
  final String judgmentTitle;

  /// Named parties (e.g. ["Kesavananda Bharati", "State of Kerala"]).
  final List<String> parties;

  /// Short petitioner label.
  final String petitioner;

  /// Short respondent label.
  final String respondent;

  /// Judge who authored the leading opinion.
  final String authoringJudge;

  /// Broad legal domain (analytics/search key).
  final CaseType? caseType;

  /// Jurisdiction / forum context, e.g. "India", "Constitutional".
  final String jurisdiction;

  /// Questions of constitutional law framed by the court.
  final List<String> constitutionalQuestions;

  /// Questions of ordinary law framed by the court.
  final List<String> legalQuestions;

  /// Statutes considered (by name, e.g. "Passports Act, 1967").
  final List<String> statutes;

  /// Statutory sections construed (e.g. "Section 124A IPC").
  final List<String> sections;

  /// Cases this judgment explicitly followed / approved.
  final List<String> precedentsFollowed;

  /// Cases this judgment explicitly overruled.
  final List<String> precedentsOverruled;

  /// Cases this judgment explicitly distinguished.
  final List<String> precedentsDistinguished;

  /// Related cases (same doctrinal field, not necessarily cited in judgment).
  final List<String> relatedCases;

  /// Related GARUDA bodies (garuda_bodies IDs, e.g. "bod_cag").
  final List<String> relatedBodies;

  /// Related schemes (names, e.g. "POSHAN Abhiyaan").
  final List<String> relatedSchemes;

  /// Related international organisations (garuda_international IDs).
  final List<String> relatedInternationalOrganisations;

  /// Related SDG goals.
  final List<String> sdgGoals;

  /// Themes (UPSC-relevant thematic clusters).
  final List<String> themes;

  /// Subjects (subject-level classification).
  final List<String> subjects;

  /// Relevance to UPSC Prelims.
  final RelevanceLevel prelimsRelevance;

  /// Relevance to UPSC Mains (GS papers).
  final RelevanceLevel mainsRelevance;

  /// Relevance to UPSC Essay.
  final RelevanceLevel essayRelevance;

  /// Relevance to UPSC Interview.
  final RelevanceLevel interviewRelevance;

  /// Common prelims traps / misconception pointers.
  final List<String> prelimsTraps;

  /// Mains answer themes this case anchors.
  final List<String> mainsThemes;

  /// Interview angles / contemporary discussion points.
  final List<String> interviewAngles;

  /// Constitutional interpretation advanced by the court.
  final String constitutionalInterpretation;

  /// One-line legal principle distilled from the ratio.
  final String legalPrinciple;

  /// Majority opinion summary.
  final String majorityOpinion;

  /// Minority opinion summary.
  final String minorityOpinion;

  /// Dissenting opinion summary.
  final String dissent;

  /// GARUDA doctrine IDs this case engages (garuda_doctrine IDs).
  final List<String> doctrines;

  /// Structured precedent relationships (source = this case).
  final List<PrecedentRelationship> precedentRelationships;

  /// Official source URL (e.g. sci.gov.in judgment link).
  final String officialSource;

  /// Publication date (ISO-8601 string) of the reported judgment.
  final String publicationDate;

  /// Date this record was last verified against its official source.
  final String lastVerifiedDate;

  /// Evidence IDs resolving against the case-law official-source registry.
  final List<String> evidenceIds;

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
    this.neutralCitation = '',
    this.reporterCitation = '',
    this.benchStrength = 0,
    this.judgmentTitle = '',
    this.parties = const [],
    this.petitioner = '',
    this.respondent = '',
    this.authoringJudge = '',
    this.caseType,
    this.jurisdiction = 'India',
    this.constitutionalQuestions = const [],
    this.legalQuestions = const [],
    this.statutes = const [],
    this.sections = const [],
    this.precedentsFollowed = const [],
    this.precedentsOverruled = const [],
    this.precedentsDistinguished = const [],
    this.relatedCases = const [],
    this.relatedBodies = const [],
    this.relatedSchemes = const [],
    this.relatedInternationalOrganisations = const [],
    this.sdgGoals = const [],
    this.themes = const [],
    this.subjects = const [],
    this.prelimsRelevance = RelevanceLevel.high,
    this.mainsRelevance = RelevanceLevel.high,
    this.essayRelevance = RelevanceLevel.medium,
    this.interviewRelevance = RelevanceLevel.medium,
    this.prelimsTraps = const [],
    this.mainsThemes = const [],
    this.interviewAngles = const [],
    this.constitutionalInterpretation = '',
    this.legalPrinciple = '',
    this.majorityOpinion = '',
    this.minorityOpinion = '',
    this.dissent = '',
    this.doctrines = const [],
    this.precedentRelationships = const [],
    this.officialSource = '',
    this.publicationDate = '',
    this.lastVerifiedDate = '',
    this.evidenceIds = const [],
  });

  /// Backwards-compatible alias for UPSC PYQ links.
  List<String> get relatedPYQs => pyqIds;

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
        'neutralCitation': neutralCitation,
        'reporterCitation': reporterCitation,
        'benchStrength': benchStrength,
        'judgmentTitle': judgmentTitle,
        'parties': parties,
        'petitioner': petitioner,
        'respondent': respondent,
        'authoringJudge': authoringJudge,
        'caseType': caseType?.name,
        'jurisdiction': jurisdiction,
        'constitutionalQuestions': constitutionalQuestions,
        'legalQuestions': legalQuestions,
        'statutes': statutes,
        'sections': sections,
        'precedentsFollowed': precedentsFollowed,
        'precedentsOverruled': precedentsOverruled,
        'precedentsDistinguished': precedentsDistinguished,
        'relatedCases': relatedCases,
        'relatedBodies': relatedBodies,
        'relatedSchemes': relatedSchemes,
        'relatedInternationalOrganisations': relatedInternationalOrganisations,
        'sdgGoals': sdgGoals,
        'themes': themes,
        'subjects': subjects,
        'prelimsRelevance': prelimsRelevance.name,
        'mainsRelevance': mainsRelevance.name,
        'essayRelevance': essayRelevance.name,
        'interviewRelevance': interviewRelevance.name,
        'prelimsTraps': prelimsTraps,
        'mainsThemes': mainsThemes,
        'interviewAngles': interviewAngles,
        'constitutionalInterpretation': constitutionalInterpretation,
        'legalPrinciple': legalPrinciple,
        'majorityOpinion': majorityOpinion,
        'minorityOpinion': minorityOpinion,
        'dissent': dissent,
        'doctrines': doctrines,
        'precedentRelationships':
            precedentRelationships.map((r) => r.toJson()).toList(),
        'officialSource': officialSource,
        'publicationDate': publicationDate,
        'lastVerifiedDate': lastVerifiedDate,
        'evidenceIds': evidenceIds,
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
        judgmentDate: DateTime.tryParse(json['judgmentDate'] as String? ?? '') ??
            DateTime(1950),
        filingDate: json['filingDate'] != null
            ? DateTime.tryParse(json['filingDate'] as String)
            : null,
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
        primarySource: json['primarySource'] as String? ?? '',
        citations: (json['citations'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        evidenceReferences: (json['evidenceReferences'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        version: (json['version'] as num?)?.toInt() ?? 1,
        reviewerId: json['reviewerId'] as String? ?? 'CHIEF_JURISPRUDENCE_ENGINEER',
        editorialStatus: json['editorialStatus'] as String? ?? 'APPROVED',
        neutralCitation: json['neutralCitation'] as String? ?? '',
        reporterCitation: json['reporterCitation'] as String? ?? '',
        benchStrength: (json['benchStrength'] as num?)?.toInt() ?? 0,
        judgmentTitle: json['judgmentTitle'] as String? ?? '',
        parties: (json['parties'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        petitioner: json['petitioner'] as String? ?? '',
        respondent: json['respondent'] as String? ?? '',
        authoringJudge: json['authoringJudge'] as String? ?? '',
        caseType: json['caseType'] != null
            ? CaseType.values.firstWhere(
                (e) => e.name == json['caseType'],
                orElse: () => CaseType.other,
              )
            : null,
        jurisdiction: json['jurisdiction'] as String? ?? 'India',
        constitutionalQuestions:
            (json['constitutionalQuestions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        legalQuestions: (json['legalQuestions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        statutes: (json['statutes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        sections: (json['sections'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        precedentsFollowed: (json['precedentsFollowed'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        precedentsOverruled: (json['precedentsOverruled'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        precedentsDistinguished: (json['precedentsDistinguished'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedCases: (json['relatedCases'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedBodies: (json['relatedBodies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedSchemes: (json['relatedSchemes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedInternationalOrganisations: (json['relatedInternationalOrganisations'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        sdgGoals: (json['sdgGoals'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        themes: (json['themes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        subjects: (json['subjects'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        prelimsRelevance: RelevanceLevel.values.firstWhere(
          (e) => e.name == json['prelimsRelevance'],
          orElse: () => RelevanceLevel.high,
        ),
        mainsRelevance: RelevanceLevel.values.firstWhere(
          (e) => e.name == json['mainsRelevance'],
          orElse: () => RelevanceLevel.high,
        ),
        essayRelevance: RelevanceLevel.values.firstWhere(
          (e) => e.name == json['essayRelevance'],
          orElse: () => RelevanceLevel.medium,
        ),
        interviewRelevance: RelevanceLevel.values.firstWhere(
          (e) => e.name == json['interviewRelevance'],
          orElse: () => RelevanceLevel.medium,
        ),
        prelimsTraps: (json['prelimsTraps'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        mainsThemes: (json['mainsThemes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        interviewAngles: (json['interviewAngles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        constitutionalInterpretation:
            json['constitutionalInterpretation'] as String? ?? '',
        legalPrinciple: json['legalPrinciple'] as String? ?? '',
        majorityOpinion: json['majorityOpinion'] as String? ?? '',
        minorityOpinion: json['minorityOpinion'] as String? ?? '',
        dissent: json['dissent'] as String? ?? '',
        doctrines: (json['doctrines'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        precedentRelationships: (json['precedentRelationships'] as List?)
                ?.map((e) => PrecedentRelationship.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        officialSource: json['officialSource'] as String? ?? '',
        publicationDate: json['publicationDate'] as String? ?? '',
        lastVerifiedDate: json['lastVerifiedDate'] as String? ?? '',
        evidenceIds: (json['evidenceIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );

  /// Returns a copy of this object with the given fields replaced.
  CaseKnowledgeObject copyWith({
    String? objectId,
    String? caseId,
    String? caseName,
    String? citation,
    int? year,
    String? court,
    String? bench,
    List<String>? judges,
    CaseStatus? status,
    CourtLevel? courtLevel,
    List<String>? keywords,
    List<String>? aliases,
    String? historicalContext,
    String? facts,
    List<String>? issues,
    List<String>? petitionerArguments,
    List<String>? respondentArguments,
    String? decision,
    List<String>? ratioDecidendi,
    List<String>? obiterDicta,
    List<String>? keyPrinciples,
    String? constitutionalSignificance,
    List<String>? relatedArticles,
    List<String>? relatedParts,
    List<String>? relatedSchedules,
    List<String>? relatedAmendments,
    List<String>? relatedActs,
    List<String>? relatedRules,
    List<String>? relatedCommittees,
    List<String>? relatedReports,
    List<String>? relatedCurrentAffairs,
    List<String>? pyqIds,
    List<String>? crossReferences,
    DateTime? judgmentDate,
    String? presentStatus,
    String? examImportance,
    String? trend,
    List<String>? frequentlyConfusedCases,
    String? garudaExplanation,
    String? primarySource,
    String? oneLineSummary,
    String? detailedSummary,
    List<String>? citations,
    List<String>? evidenceReferences,
    int? version,
    String? editorialStatus,
    String? neutralCitation,
    String? reporterCitation,
    int? benchStrength,
    String? judgmentTitle,
    List<String>? parties,
    String? petitioner,
    String? respondent,
    String? authoringJudge,
    CaseType? caseType,
    String? jurisdiction,
    List<String>? constitutionalQuestions,
    List<String>? legalQuestions,
    List<String>? statutes,
    List<String>? sections,
    List<String>? precedentsFollowed,
    List<String>? precedentsOverruled,
    List<String>? precedentsDistinguished,
    List<String>? relatedCases,
    List<String>? relatedBodies,
    List<String>? relatedSchemes,
    List<String>? relatedInternationalOrganisations,
    List<String>? sdgGoals,
    List<String>? themes,
    List<String>? subjects,
    RelevanceLevel? prelimsRelevance,
    RelevanceLevel? mainsRelevance,
    RelevanceLevel? essayRelevance,
    RelevanceLevel? interviewRelevance,
    List<String>? prelimsTraps,
    List<String>? mainsThemes,
    List<String>? interviewAngles,
    String? constitutionalInterpretation,
    String? legalPrinciple,
    String? majorityOpinion,
    String? minorityOpinion,
    String? dissent,
    List<String>? doctrines,
    List<PrecedentRelationship>? precedentRelationships,
    String? officialSource,
    String? publicationDate,
    String? lastVerifiedDate,
    List<String>? evidenceIds,
  }) {
    return CaseKnowledgeObject(
      objectId: objectId ?? this.objectId,
      caseId: caseId ?? this.caseId,
      caseName: caseName ?? this.caseName,
      citation: citation ?? this.citation,
      year: year ?? this.year,
      court: court ?? this.court,
      bench: bench ?? this.bench,
      judges: judges ?? this.judges,
      status: status ?? this.status,
      courtLevel: courtLevel ?? this.courtLevel,
      keywords: keywords ?? this.keywords,
      aliases: aliases ?? this.aliases,
      historicalContext: historicalContext ?? this.historicalContext,
      facts: facts ?? this.facts,
      issues: issues ?? this.issues,
      petitionerArguments: petitionerArguments ?? this.petitionerArguments,
      respondentArguments: respondentArguments ?? this.respondentArguments,
      decision: decision ?? this.decision,
      ratioDecidendi: ratioDecidendi ?? this.ratioDecidendi,
      obiterDicta: obiterDicta ?? this.obiterDicta,
      keyPrinciples: keyPrinciples ?? this.keyPrinciples,
      constitutionalSignificance:
          constitutionalSignificance ?? this.constitutionalSignificance,
      relatedArticles: relatedArticles ?? this.relatedArticles,
      relatedParts: relatedParts ?? this.relatedParts,
      relatedSchedules: relatedSchedules ?? this.relatedSchedules,
      relatedAmendments: relatedAmendments ?? this.relatedAmendments,
      relatedActs: relatedActs ?? this.relatedActs,
      relatedRules: relatedRules ?? this.relatedRules,
      relatedCommittees: relatedCommittees ?? this.relatedCommittees,
      relatedReports: relatedReports ?? this.relatedReports,
      relatedCurrentAffairs:
          relatedCurrentAffairs ?? this.relatedCurrentAffairs,
      pyqIds: pyqIds ?? this.pyqIds,
      relatedLessons: relatedLessons,
      crossReferences: crossReferences ?? this.crossReferences,
      judgmentDate: judgmentDate ?? this.judgmentDate,
      filingDate: filingDate,
      timeline: timeline,
      subsequentDevelopments: subsequentDevelopments,
      presentStatus: presentStatus ?? this.presentStatus,
      examImportance: examImportance ?? this.examImportance,
      timesAsked: timesAsked,
      lastAskedYear: lastAskedYear,
      trend: trend ?? this.trend,
      frequentlyConfusedCases: frequentlyConfusedCases ?? this.frequentlyConfusedCases,
      garudaExplanation: garudaExplanation ?? this.garudaExplanation,
      commonMistakes: commonMistakes,
      memoryTricks: memoryTricks,
      oneLineSummary: oneLineSummary ?? this.oneLineSummary,
      detailedSummary: detailedSummary ?? this.detailedSummary,
      primarySource: primarySource ?? this.primarySource,
      citations: citations ?? this.citations,
      evidenceReferences: evidenceReferences ?? this.evidenceReferences,
      version: version ?? this.version,
      reviewerId: reviewerId,
      editorialStatus: editorialStatus ?? this.editorialStatus,
      neutralCitation: neutralCitation ?? this.neutralCitation,
      reporterCitation: reporterCitation ?? this.reporterCitation,
      benchStrength: benchStrength ?? this.benchStrength,
      judgmentTitle: judgmentTitle ?? this.judgmentTitle,
      parties: parties ?? this.parties,
      petitioner: petitioner ?? this.petitioner,
      respondent: respondent ?? this.respondent,
      authoringJudge: authoringJudge ?? this.authoringJudge,
      caseType: caseType ?? this.caseType,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      constitutionalQuestions:
          constitutionalQuestions ?? this.constitutionalQuestions,
      legalQuestions: legalQuestions ?? this.legalQuestions,
      statutes: statutes ?? this.statutes,
      sections: sections ?? this.sections,
      precedentsFollowed: precedentsFollowed ?? this.precedentsFollowed,
      precedentsOverruled: precedentsOverruled ?? this.precedentsOverruled,
      precedentsDistinguished:
          precedentsDistinguished ?? this.precedentsDistinguished,
      relatedCases: relatedCases ?? this.relatedCases,
      relatedBodies: relatedBodies ?? this.relatedBodies,
      relatedSchemes: relatedSchemes ?? this.relatedSchemes,
      relatedInternationalOrganisations:
          relatedInternationalOrganisations ?? this.relatedInternationalOrganisations,
      sdgGoals: sdgGoals ?? this.sdgGoals,
      themes: themes ?? this.themes,
      subjects: subjects ?? this.subjects,
      prelimsRelevance: prelimsRelevance ?? this.prelimsRelevance,
      mainsRelevance: mainsRelevance ?? this.mainsRelevance,
      essayRelevance: essayRelevance ?? this.essayRelevance,
      interviewRelevance: interviewRelevance ?? this.interviewRelevance,
      prelimsTraps: prelimsTraps ?? this.prelimsTraps,
      mainsThemes: mainsThemes ?? this.mainsThemes,
      interviewAngles: interviewAngles ?? this.interviewAngles,
      constitutionalInterpretation:
          constitutionalInterpretation ?? this.constitutionalInterpretation,
      legalPrinciple: legalPrinciple ?? this.legalPrinciple,
      majorityOpinion: majorityOpinion ?? this.majorityOpinion,
      minorityOpinion: minorityOpinion ?? this.minorityOpinion,
      dissent: dissent ?? this.dissent,
      doctrines: doctrines ?? this.doctrines,
      precedentRelationships:
          precedentRelationships ?? this.precedentRelationships,
      officialSource: officialSource ?? this.officialSource,
      publicationDate: publicationDate ?? this.publicationDate,
      lastVerifiedDate: lastVerifiedDate ?? this.lastVerifiedDate,
      evidenceIds: evidenceIds ?? this.evidenceIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseKnowledgeObject && objectId == other.objectId;

  @override
  int get hashCode => objectId.hashCode;

  /// Bridges this Case into the GARUDA Editorial Production Engine as a
  /// [KnowledgeObject]. No case may be published without a verified official
  /// source, evidence and editorial approval.
  KnowledgeObject toGarudaKnowledgeObject() {
    return KnowledgeObject(
      id: objectId,
      title: caseName,
      subject: caseType?.displayName ?? 'Constitutional Law',
      topic: citation,
      subtopic: court,
      summary: oneLineSummary,
      content: 'Case: $caseName. Citation: $citation. Year: $year. '
          'Bench: $bench. Decision: $decision. '
          'Ratio: ${ratioDecidendi.join("; ")}. '
          'Significance: $constitutionalSignificance.',
      officialSource: officialSource.isNotEmpty ? officialSource : primarySource,
      evidenceIds: evidenceIds.isNotEmpty ? evidenceIds : evidenceReferences,
      status: _toEditorialStatus(),
      version: version,
      package: 'garuda_case_law',
      knowledgeType: 'CaseKnowledgeObject',
      relatedArticles: relatedArticles,
      relatedCaseLaws: relatedCases,
      tags: [...keywords, ...doctrines],
      isVerified: evidenceIds.isNotEmpty &&
          _toEditorialStatus() == EditorialStatus.published,
      metadata: {
        'caseId': caseId,
        'citation': citation,
        'neutralCitation': neutralCitation,
        'court': court,
        'bench': bench,
        'benchStrength': benchStrength,
        'judgmentDate': judgmentDate.toIso8601String(),
        'year': year,
        'caseType': caseType?.name,
        'status': status.name,
        'authoringJudge': authoringJudge,
        'judges': judges,
        'doctrines': doctrines,
        'precedentsFollowed': precedentsFollowed,
        'precedentsOverruled': precedentsOverruled,
        'precedentsDistinguished': precedentsDistinguished,
        'relatedActs': relatedActs,
        'relatedBodies': relatedBodies,
        'relatedSchemes': relatedSchemes,
        'relatedCommittees': relatedCommittees,
        'relatedReports': relatedReports,
        'relatedInternationalOrganisations': relatedInternationalOrganisations,
        'sdgGoals': sdgGoals,
        'pyqIds': pyqIds,
        'relatedCurrentAffairs': relatedCurrentAffairs,
        'prelimsRelevance': prelimsRelevance.name,
        'mainsRelevance': mainsRelevance.name,
        'essayRelevance': essayRelevance.name,
        'interviewRelevance': interviewRelevance.name,
        'legalPrinciple': legalPrinciple,
        'lastVerifiedDate': lastVerifiedDate,
      },
    );
  }

  EditorialStatus _toEditorialStatus() {
    switch (editorialStatus.trim().toUpperCase()) {
      case 'APPROVED':
        return EditorialStatus.approved;
      case 'PUBLISHED':
        return EditorialStatus.published;
      case 'IMPORTED':
        return EditorialStatus.imported;
      case 'PENDING_REVIEW':
      case 'PENDING':
        return EditorialStatus.pendingReview;
      case 'EVIDENCE_VERIFIED':
        return EditorialStatus.evidenceVerified;
      case 'REVIEW':
      case 'IN_REVIEW':
        return EditorialStatus.inReview;
      default:
        return EditorialStatus.approved;
    }
  }
}
