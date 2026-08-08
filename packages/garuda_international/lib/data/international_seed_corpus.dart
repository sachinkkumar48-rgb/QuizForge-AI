library;

import '../domain/entities/international_knowledge_object.dart';
import 'international_corpus_finance_trade.dart';
import 'international_corpus_regional.dart';
import 'international_corpus_security_environment.dart';
import 'international_corpus_un.dart';

/// Phase-I Seed Corpus for the GARUDA International Organisations, Groupings &
/// Global Institutions Knowledge Library.
///
/// Every record is a real, traceable international organisation built from
/// official institutional sources, carrying an `officialSource`, evidence IDs,
/// a corpus-wide `lastVerifiedDate` and an `evidenceVerified` editorial status.
/// No fabricated or placeholder records are present; `expectedInternationalCorpus`
/// states exactly how many verified records the Phase-I corpus delivers.
class InternationalSeedCorpus {
  InternationalSeedCorpus._();

  static final List<InternationalKnowledgeObject> phase1Organisations = [
    ...InternationalCorpusUn.bodies,
    ...InternationalCorpusFinanceTrade.bodies,
    ...InternationalCorpusRegional.bodies,
    ...InternationalCorpusSecurityEnvironment.bodies,
  ];

  /// Total expected Phase-I International organisations (verified records).
  static const int expectedInternationalCorpus = 66;

  /// Distinct categories represented in the Phase-I corpus.
  static const List<String> coveredCategories = [
    'United Nations System',
    'Bretton Woods / Global Financial Institution',
    'Trade Organisation',
    'Economic Governance',
    'Regional / Political Grouping',
    'Security / Strategic Organisation',
    'Climate / Environment Institution',
    'Development Bank',
    'Treaty Body',
    'Financial Institution',
    'Initiative',
    'Forum',
  ];
}
