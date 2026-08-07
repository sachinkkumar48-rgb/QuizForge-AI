library;

import '../data/committee_seed_corpus.dart';
import '../domain/entities/committee_enums.dart';
import '../domain/entities/committee_knowledge_object.dart';
import '../search/committee_search_engine.dart';
import 'committee_repository.dart';

/// In-memory implementation of CommitteeRepository pre-seeded with Phase-I corpus.
class InMemoryCommitteeRepository implements CommitteeRepository {
  final Map<String, CommitteeKnowledgeObject> _storage = {};
  final int _expectedCorpusTarget;

  InMemoryCommitteeRepository({
    bool seedDefaultCorpus = true,
    int expectedCorpusTarget = 100,
  }) : _expectedCorpusTarget = expectedCorpusTarget {
    if (seedDefaultCorpus) {
      for (final committee in CommitteeSeedCorpus.phase1Committees) {
        _storage[committee.id] = committee;
      }
    }
  }

  @override
  Future<void> saveCommittee(CommitteeKnowledgeObject object) async {
    _storage[object.id] = object;
  }

  @override
  Future<CommitteeKnowledgeObject?> getCommitteeById(String id) async {
    return _storage[id];
  }

  @override
  Future<List<CommitteeKnowledgeObject>> getAllCommittees() async {
    return List.unmodifiable(_storage.values.toList());
  }

  @override
  Future<List<CommitteeKnowledgeObject>> getByCategory(CommitteeCategory category) async {
    return _storage.values.where((c) => c.category == category).toList();
  }

  @override
  Future<List<CommitteeKnowledgeObject>> getByMinistry(String ministry) async {
    final lower = ministry.toLowerCase().trim();
    return _storage.values
        .where((c) =>
            c.constitutingAuthority.toLowerCase().contains(lower) ||
            c.relatedMinistries.any((m) => m.toLowerCase().contains(lower)))
        .toList();
  }

  @override
  Future<List<CommitteeKnowledgeObject>> searchCommittees(CommitteeSearchQuery query) async {
    return CommitteeSearchEngine.search(
      committees: _storage.values.toList(),
      query: query,
    );
  }

  @override
  Future<CommitteeCorpusReport> generateCorpusReport() async {
    final committees = _storage.values.toList();
    final totalImported = committees.length;
    final categoryCounts = <CommitteeCategory, int>{};

    int totalRecs = 0;
    int totalReps = 0;
    int totalPyqs = 0;
    int totalCa = 0;

    for (final c in committees) {
      categoryCounts[c.category] = (categoryCounts[c.category] ?? 0) + 1;
      totalRecs += c.recommendations.length;
      totalReps += c.reports.length;
      totalPyqs += c.relatedPyqIds.length;
      totalCa += c.relatedCurrentAffairsIds.length;
    }

    final coveragePct =
        _expectedCorpusTarget > 0 ? (totalImported / _expectedCorpusTarget) * 100.0 : 100.0;

    return CommitteeCorpusReport(
      totalExpectedCommittees: _expectedCorpusTarget,
      totalImportedCommittees: totalImported,
      coveragePercentage: double.parse(coveragePct.toStringAsFixed(1)),
      totalRecommendations: totalRecs,
      totalReports: totalReps,
      totalPyqLinks: totalPyqs,
      totalCurrentAffairsLinks: totalCa,
      categoryCounts: Map.unmodifiable(categoryCounts),
    );
  }

  void clear() {
    _storage.clear();
  }
}
