import '../domain/entities/knowledge_object.dart';
import '../domain/entities/knowledge_tag.dart';
import '../domain/enums/knowledge_object_type.dart';
import '../domain/enums/relationship_type.dart';
import '../repositories/knowledge_repository.dart';

class LegacySearchResult {
  final KnowledgeObject object;
  final double score;

  const LegacySearchResult({required this.object, required this.score});
}

class KnowledgeSearchEngine {
  final KnowledgeRepository _repository;

  KnowledgeSearchEngine(this._repository);

  Future<List<LegacySearchResult>> search({
    String? query,
    KnowledgeObjectType? type,
    KnowledgeTag? tag,
    RelationshipType? relationshipType,
    double minScore = 0.1,
  }) async {
    final allObjects = await _repository.bulkExport();
    final results = <LegacySearchResult>[];

    final terms = (query ?? '')
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    for (final obj in allObjects) {
      if (type != null && obj.type != type) continue;
      if (tag != null &&
          !obj.tags.any((t) => t.name.toLowerCase() == tag.name.toLowerCase())) {
        continue;
      }
      if (relationshipType != null &&
          !obj.relationships.any((r) => r.type == relationshipType)) {
        continue;
      }

      if (terms.isEmpty) {
        results.add(LegacySearchResult(object: obj, score: 1.0));
        continue;
      }

      double score = 0.0;
      final titleLower = obj.title.toLowerCase();
      final contentLower = obj.content.toLowerCase();
      final summaryLower = obj.summary?.toLowerCase() ?? '';

      for (final term in terms) {
        if (titleLower.contains(term)) score += 3.0;
        if (summaryLower.contains(term)) score += 2.0;
        if (contentLower.contains(term)) score += 1.0;
        for (final t in obj.tags) {
          if (t.name.toLowerCase().contains(term)) score += 1.5;
        }
      }

      final normalizedScore = score / (terms.length * 3.0);
      if (normalizedScore >= minScore) {
        results.add(LegacySearchResult(object: obj, score: normalizedScore));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}
