import '../../domain/entities/evidence_object.dart';
import '../../domain/entities/evidence_search_query.dart';
import '../../domain/repositories/evidence_repository.dart';

/// Thread-safe in-memory and offline-first storage repository for Evidence Objects.
class InMemoryEvidenceRepository implements EvidenceRepository {
  final Map<String, EvidenceObject> _storage = {};

  @override
  Future<bool> save(EvidenceObject evidence) async {
    _storage[evidence.id] = evidence;
    return true;
  }

  @override
  Future<bool> update(EvidenceObject evidence) async {
    _storage[evidence.id] = evidence;
    return true;
  }

  @override
  Future<bool> delete(String id) async {
    final removed = _storage.remove(id);
    return removed != null;
  }

  @override
  Future<EvidenceObject?> findById(String id) async {
    return _storage[id];
  }

  @override
  Future<List<EvidenceObject>> findBySource(String sourceName) async {
    return _storage.values
        .where((e) => e.sourceName.toLowerCase() == sourceName.toLowerCase())
        .toList();
  }

  @override
  Future<List<EvidenceObject>> findByTopic(String topic) async {
    return _storage.values
        .where((e) => e.topic.toLowerCase() == topic.toLowerCase())
        .toList();
  }

  @override
  Future<List<EvidenceObject>> findByTag(String tag) async {
    final lowerTag = tag.toLowerCase();
    return _storage.values
        .where((e) => e.keywords.any((k) => k.toLowerCase() == lowerTag))
        .toList();
  }

  @override
  Future<List<EvidenceObject>> findRecent({int limit = 10}) async {
    final list = _storage.values.toList()
      ..sort((a, b) => b.publicationDate.compareTo(a.publicationDate));
    return list.take(limit).toList();
  }

  @override
  Future<List<EvidenceObject>> search(EvidenceSearchQuery query) async {
    var results = _storage.values.toList();

    if (query.keyword != null && query.keyword!.isNotEmpty) {
      final kw = query.keyword!.toLowerCase();
      results = results
          .where((e) =>
              e.title.toLowerCase().contains(kw) ||
              e.summary.toLowerCase().contains(kw) ||
              e.keywords.any((k) => k.toLowerCase().contains(kw)))
          .toList();
    }

    if (query.semanticQuery != null && query.semanticQuery!.isNotEmpty) {
      final sq = query.semanticQuery!.toLowerCase();
      results = results
          .where((e) =>
              e.title.toLowerCase().contains(sq) ||
              e.summary.toLowerCase().contains(sq) ||
              e.topic.toLowerCase().contains(sq) ||
              e.subject.toLowerCase().contains(sq))
          .toList();
    }

    if (query.topic != null && query.topic!.isNotEmpty) {
      final t = query.topic!.toLowerCase();
      results = results.where((e) => e.topic.toLowerCase() == t).toList();
    }

    if (query.subject != null && query.subject!.isNotEmpty) {
      final s = query.subject!.toLowerCase();
      results = results.where((e) => e.subject.toLowerCase() == s).toList();
    }

    if (query.authorityId != null && query.authorityId!.isNotEmpty) {
      results = results
          .where((e) => e.authority.id.toLowerCase() == query.authorityId!.toLowerCase())
          .toList();
    }

    if (query.sourceType != null) {
      results = results.where((e) => e.sourceType == query.sourceType).toList();
    }

    if (query.verificationStatus != null) {
      results =
          results.where((e) => e.verificationStatus == query.verificationStatus).toList();
    }

    if (query.startDate != null) {
      results = results
          .where((e) =>
              e.publicationDate.isAfter(query.startDate!) ||
              e.publicationDate.isAtSameMomentAs(query.startDate!))
          .toList();
    }

    if (query.endDate != null) {
      results = results
          .where((e) =>
              e.publicationDate.isBefore(query.endDate!) ||
              e.publicationDate.isAtSameMomentAs(query.endDate!))
          .toList();
    }

    if (query.tags.isNotEmpty) {
      final queryTags = query.tags.map((t) => t.toLowerCase()).toSet();
      results = results
          .where((e) => e.keywords.any((k) => queryTags.contains(k.toLowerCase())))
          .toList();
    }

    // Sorting & Pagination
    results.sort((a, b) => b.publicationDate.compareTo(a.publicationDate));

    if (query.offset >= results.length) return [];

    final start = query.offset;
    final end = (start + query.limit < results.length)
        ? start + query.limit
        : results.length;

    return results.sublist(start, end);
  }
}
