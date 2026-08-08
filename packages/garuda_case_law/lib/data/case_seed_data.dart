library;

import '../domain/entities/case_knowledge_object.dart';
import 'case_corpus_support.dart';
import 'landmark_cases_phase1.dart';
import 'landmark_cases_phase2.dart';

/// Permanent Seeded Official Repository Data for the GARUDA Landmark Case Library.
///
/// Combines the Phase-I (20) and Phase-II (29) landmark cases and applies
/// corpus enrichment so every record carries a resolvable evidence ID, an
/// official source and a verification date.
class CaseSeedData {
  static final List<CaseKnowledgeObject> cases = [
    ...LandmarkCasesPhase1.cases,
    ...LandmarkCasesPhase2.cases,
  ].map(CaseCorpusSupport.enrichCase).toList();
}
