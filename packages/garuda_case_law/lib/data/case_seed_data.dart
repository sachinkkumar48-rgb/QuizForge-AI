library;

import '../domain/entities/case_knowledge_object.dart';
import 'landmark_cases_phase1.dart';

/// Permanent Seeded Official Repository Data for the GARUDA Landmark Case Library.
class CaseSeedData {
  static final List<CaseKnowledgeObject> cases = LandmarkCasesPhase1.cases;
}
