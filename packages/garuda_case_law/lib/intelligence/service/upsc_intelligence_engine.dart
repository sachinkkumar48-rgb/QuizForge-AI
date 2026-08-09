/// UPSC Intelligence Engine (TITAN-KO-015.0 P4).
///
/// Composes a case-specific civil-services preparation profile from the
/// verified judgment record and the curated UPSC intelligence. Every section
/// is grounded in case-specific data — nothing is generic filler. Sections
/// with no case-specific content are returned empty and marked as absent,
/// never padded.
library;

import '../../domain/entities/case_knowledge_object.dart';
import '../domain/judgment_intelligence.dart';

/// Case-specific UPSC preparation profile.
class UpscIntelligenceProfile {
  final String caseId;
  final String caseName;

  // Prelims
  final List<String> prelimsFacts;
  final List<String> importantArticles;
  final List<String> importantActs;
  final List<int> importantYears;
  final List<String> judgesOrBench;
  final String landmarkPrinciple;
  final List<String> commonTraps;
  final List<String> eliminationClues;

  // Mains
  final List<String> issueFramings;
  final List<String> constitutionalProvisions;
  final List<String> arguments;
  final List<String> counterarguments;
  final String judgmentPrinciple;
  final List<String> contemporaryRelevance;
  final List<String> answerKeywords;
  final List<String> conclusionIdeas;

  // Interview
  final List<String> likelyInterviewQuestions;
  final List<String> conceptualDiscussionPoints;
  final String constitutionalSignificance;
  final List<String> contemporaryImplications;

  // Essay
  final List<String> essayThemes;
  final List<String> philosophicalDimensions;
  final List<String> examples;

  const UpscIntelligenceProfile({
    required this.caseId,
    required this.caseName,
    this.prelimsFacts = const [],
    this.importantArticles = const [],
    this.importantActs = const [],
    this.importantYears = const [],
    this.judgesOrBench = const [],
    this.landmarkPrinciple = '',
    this.commonTraps = const [],
    this.eliminationClues = const [],
    this.issueFramings = const [],
    this.constitutionalProvisions = const [],
    this.arguments = const [],
    this.counterarguments = const [],
    this.judgmentPrinciple = '',
    this.contemporaryRelevance = const [],
    this.answerKeywords = const [],
    this.conclusionIdeas = const [],
    this.likelyInterviewQuestions = const [],
    this.conceptualDiscussionPoints = const [],
    this.constitutionalSignificance = '',
    this.contemporaryImplications = const [],
    this.essayThemes = const [],
    this.philosophicalDimensions = const [],
    this.examples = const [],
  });

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'caseName': caseName,
        'prelimsFacts': prelimsFacts,
        'importantArticles': importantArticles,
        'importantActs': importantActs,
        'importantYears': importantYears,
        'judgesOrBench': judgesOrBench,
        'landmarkPrinciple': landmarkPrinciple,
        'commonTraps': commonTraps,
        'eliminationClues': eliminationClues,
        'issueFramings': issueFramings,
        'constitutionalProvisions': constitutionalProvisions,
        'arguments': arguments,
        'counterarguments': counterarguments,
        'judgmentPrinciple': judgmentPrinciple,
        'contemporaryRelevance': contemporaryRelevance,
        'answerKeywords': answerKeywords,
        'conclusionIdeas': conclusionIdeas,
        'likelyInterviewQuestions': likelyInterviewQuestions,
        'conceptualDiscussionPoints': conceptualDiscussionPoints,
        'constitutionalSignificance': constitutionalSignificance,
        'contemporaryImplications': contemporaryImplications,
        'essayThemes': essayThemes,
        'philosophicalDimensions': philosophicalDimensions,
        'examples': examples,
      };
}

/// Composes case-specific UPSC profiles from the corpus.
class UpscIntelligenceEngine {
  const UpscIntelligenceEngine();

  /// Builds the UPSC profile for a case from its record and intelligence.
  UpscIntelligenceProfile profileFor(CaseKnowledgeObject c) {
    final intel = c.judgmentIntelligence;
    final upsc = intel?.upscIntelligence;

    final bench = intel?.bench;
    final years = <int>{
      if (c.year > 0) c.year,
      for (final t in intel?.timeline ?? const <JudgmentTimelineEvent>[])
        if (t.year != null && t.year! > 0) t.year!,
    }.toList()..sort();

    return UpscIntelligenceProfile(
      caseId: c.caseId,
      caseName: c.caseName,
      prelimsFacts: upsc?.prelimsFacts ?? const [],
      importantArticles: c.relatedArticles,
      importantActs: c.relatedActs,
      importantYears: years,
      judgesOrBench: [
        ...bench?.judgeNames ?? const [],
        if (bench?.constitutionOfBench.isNotEmpty ?? false)
          bench!.constitutionOfBench,
      ],
      landmarkPrinciple: intel?.ratios.isNotEmpty == true
          ? intel!.ratios.first.ratio
          : c.legalPrinciple,
      commonTraps: upsc?.prelimsTraps ?? const [],
      eliminationClues: _eliminationClues(c, upsc),
      issueFramings: intel?.issues.map((e) => e.issue).toList() ?? const [],
      constitutionalProvisions: c.relatedArticles,
      arguments: [
        ...upsc?.mainsArguments ?? const [],
        ...c.petitionerArguments,
      ],
      counterarguments: [
        ...upsc?.mainsCounterarguments ?? const [],
        ...c.respondentArguments,
      ],
      judgmentPrinciple: intel?.ratios.isNotEmpty == true
          ? intel!.ratios.first.ratio
          : c.legalPrinciple,
      contemporaryRelevance: upsc?.contemporaryRelevance ?? const [],
      answerKeywords: upsc?.answerKeywords ?? const [],
      conclusionIdeas: upsc?.conclusionIdeas ?? const [],
      likelyInterviewQuestions:
          upsc?.likelyInterviewQuestions ?? const [],
      conceptualDiscussionPoints: upsc?.interviewAreas ?? const [],
      constitutionalSignificance:
          intel?.judicialSignificance?.constitutionalSignificance ??
              c.constitutionalSignificance,
      contemporaryImplications: upsc?.contemporaryRelevance ?? const [],
      essayThemes: upsc?.essayThemes ?? const [],
      philosophicalDimensions: _philosophicalDimensions(intel),
      examples: [c.caseName],
    );
  }

  /// Elimination clues are concrete, case-specific distractors recorded in the
  /// curated traps — surfaced verbatim, never invented.
  List<String> _eliminationClues(
          CaseKnowledgeObject c, UpscJudgmentIntelligence? upsc) =>
      (upsc?.prelimsTraps ?? const []).where((t) => t.isNotEmpty).toList();

  /// Philosophical / doctrinal dimensions are drawn from the reasoning tools
  /// and doctrines actually invoked in the judgment.
  List<String> _philosophicalDimensions(JudgmentIntelligence? intel) {
    final dims = <String>[
      ...intel?.reasoning?.reasoningTools ?? const [],
      ...intel?.reasoning?.constitutionalPhilosophy ?? const [],
    ];
    final unique = dims.toSet().toList();
    return unique;
  }
}
