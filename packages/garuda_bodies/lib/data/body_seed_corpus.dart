library;

import '../domain/entities/body_knowledge_object.dart';
import 'body_corpus_constitutional.dart';
import 'body_corpus_regulatory.dart';

/// Phase-I Seed Corpus for the GARUDA Government Commissions & Statutory
/// Bodies Knowledge Library.
///
/// Every record is a real, traceable Government of India body built from the
/// Constitution, establishing Acts and official body portals, carrying an
/// `officialSource`, evidence IDs, a corpus-wide `lastVerifiedDate` and an
/// `evidenceVerified` editorial status. No fabricated or placeholder records
/// are present; `expectedBodyCorpus` states exactly how many verified records
/// the Phase-I corpus delivers.
class BodySeedCorpus {
  BodySeedCorpus._();

  static final List<BodyKnowledgeObject> phase1Bodies = [
    ...BodyCorpusConstitutional.bodies,
    ...BodyCorpusRegulatory.bodies,
  ];

  /// Total expected Phase-I Bodies (verified records).
  static const int expectedBodyCorpus = 43;

  /// Distinct parent-ministries / oversight arrangements represented in the
  /// Phase-I corpus (stable analytics key).
  static const List<String> coveredOversight = [
    'Not under any Ministry (constitutionally independent)',
    'Ministry of Social Justice & Empowerment (administrative)',
    'Ministry of Tribal Affairs (administrative)',
    'Ministry of Personnel, Public Grievances & Pensions (administrative)',
    'Ministry of Women & Child Development (administrative)',
    'Ministry of Minority Affairs (administrative)',
    'Department of Consumer Affairs (administrative)',
    'Department of Corporate Affairs (administrative)',
    'Ministry of Finance (administrative)',
    'Ministry of Communications (administrative)',
    'Ministry of Environment, Forest & Climate Change (administrative)',
    'Ministry of Home Affairs (administrative)',
    'Ministry of Health & Family Welfare (administrative)',
    'Ministry of Education (administrative)',
    'Ministry of Ayush (administrative)',
    'Ministry of Electronics & Information Technology (administrative)',
    'Ministry of Power (administrative)',
    'Ministry of Law & Justice',
    'Autonomous (reports to Parliament)',
    'Constituted by the Governor (autonomous)',
    'Constituted by the President (autonomous)',
    'Prime Minister\'s Office (via PM as Chairperson)',
  ];
}
