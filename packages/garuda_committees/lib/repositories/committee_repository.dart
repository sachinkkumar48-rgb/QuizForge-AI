library;

import '../domain/entities/committee_enums.dart';
import '../domain/entities/committee_knowledge_object.dart';
import '../search/committee_search_engine.dart';

/// Corpus Coverage Metrics Report.
class CommitteeCorpusReport {
  final int totalExpectedCommittees;
  final int totalImportedCommittees;
  final double coveragePercentage;
  final int totalRecommendations;
  final int totalReports;
  final int totalPyqLinks;
  final int totalCurrentAffairsLinks;
  final Map<CommitteeCategory, int> categoryCounts;

  const CommitteeCorpusReport({
    required this.totalExpectedCommittees,
    required this.totalImportedCommittees,
    required this.coveragePercentage,
    required this.totalRecommendations,
    required this.totalReports,
    required this.totalPyqLinks,
    required this.totalCurrentAffairsLinks,
    required this.categoryCounts,
  });
}

/// Abstract repository interface for Committee & Commission Knowledge Objects.
abstract class CommitteeRepository {
  Future<void> saveCommittee(CommitteeKnowledgeObject object);
  Future<CommitteeKnowledgeObject?> getCommitteeById(String id);
  Future<List<CommitteeKnowledgeObject>> getAllCommittees();
  Future<List<CommitteeKnowledgeObject>> getByCategory(CommitteeCategory category);
  Future<List<CommitteeKnowledgeObject>> getByMinistry(String ministry);
  Future<List<CommitteeKnowledgeObject>> searchCommittees(CommitteeSearchQuery query);
  Future<CommitteeCorpusReport> generateCorpusReport();
}
