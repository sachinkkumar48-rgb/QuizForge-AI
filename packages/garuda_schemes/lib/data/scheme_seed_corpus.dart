library;

import '../domain/entities/scheme_knowledge_object.dart';
import 'scheme_corpus_agriculture.dart';
import 'scheme_corpus_economy.dart';
import 'scheme_corpus_infrastructure.dart';
import 'scheme_corpus_welfare.dart';

/// Phase-I Seed Corpus for the GARUDA Government Schemes Knowledge Library.
///
/// Every record is a real, traceable Government of India scheme built from
/// official scheme portals and PIB releases, carrying an `officialSource`,
/// evidence IDs, a corpus-wide `lastVerifiedDate` and `evidenceVerified`
/// editorial status. No fabricated or placeholder records are present; the
/// `expectedSchemeCorpus` count states exactly how many verified records the
/// Phase-I corpus delivers.
class SchemeSeedCorpus {
  SchemeSeedCorpus._();

  static final List<SchemeKnowledgeObject> phase1Schemes = [
    ...SchemeCorpusAgriculture.schemes,
    ...SchemeCorpusWelfare.schemes,
    ...SchemeCorpusEconomy.schemes,
    ...SchemeCorpusInfrastructure.schemes,
  ];

  /// Total expected Phase-I Schemes (verified records).
  static const int expectedSchemeCorpus = 67;

  /// Distinct ministries covered by the Phase-I corpus (stable analytics key).
  static const List<String> coveredMinistries = [
    'Ministry of Agriculture & Farmers Welfare',
    'Ministry of Rural Development',
    'Ministry of New & Renewable Energy',
    'Ministry of Consumer Affairs, Food & Public Distribution',
    'Ministry of Health & Family Welfare',
    'Ministry of Chemicals & Fertilizers',
    'Ministry of Education',
    'Ministry of Women & Child Development',
    'Ministry of Tribal Affairs',
    'Ministry of Social Justice & Empowerment',
    'Ministry of Finance',
    'Ministry of Housing & Urban Affairs',
    'Ministry of Commerce & Industry',
    'Ministry of Skill Development & Entrepreneurship',
    'Ministry of Labour & Employment',
    'Ministry of MSME',
    'Ministry of Heavy Industries',
    'Ministry of Jal Shakti',
    'Ministry of Petroleum & Natural Gas',
    'Ministry of Power',
    'Ministry of Road Transport & Highways',
    'Ministry of Civil Aviation',
    'Ministry of Communications',
    'Ministry of Electronics & Information Technology',
    'Ministry of Environment, Forest & Climate Change',
    'Ministry of Science & Technology',
    'Ministry of Earth Sciences',
  ];
}
