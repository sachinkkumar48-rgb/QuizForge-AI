library;

import '../data/doctrine_seed_data.dart';
import '../domain/entities/doctrine_enums.dart';
import '../domain/entities/doctrine_knowledge_object.dart';
import 'doctrine_repository.dart';

/// Thread-safe offline-first repository implementation of [DoctrineRepository].
class InMemoryDoctrineRepository implements DoctrineRepository {
  final List<DoctrineKnowledgeObject> _doctrinesList;
  final Map<String, DoctrineKnowledgeObject> _doctrinesMap = {};

  InMemoryDoctrineRepository({
    List<DoctrineKnowledgeObject>? doctrines,
  }) : _doctrinesList = doctrines ?? DoctrineSeedData.doctrines {
    for (final d in _doctrinesList) {
      _doctrinesMap[d.objectId.toUpperCase()] = d;
      _doctrinesMap[d.doctrineId.toUpperCase()] = d;
      _doctrinesMap[d.name.toUpperCase()] = d;
    }
  }

  @override
  Future<List<DoctrineKnowledgeObject>> getDoctrines() async => _doctrinesList;

  @override
  Future<DoctrineKnowledgeObject?> findDoctrine(String idOrName) async {
    final raw = idOrName.trim();
    if (raw.isEmpty) return null;

    final upper = raw.toUpperCase();
    if (_doctrinesMap.containsKey(upper)) return _doctrinesMap[upper];
    if (_doctrinesMap.containsKey('KO-DOC-$upper')) return _doctrinesMap['KO-DOC-$upper'];

    final clean = raw.replaceAll(RegExp(r'^(KO-DOC-|DOCTRINE-|DOCTRINE OF\s*)', caseSensitive: false), '').trim().toUpperCase();

    for (final d in _doctrinesList) {
      if (d.doctrineId.toUpperCase() == clean ||
          d.objectId.toUpperCase() == upper ||
          d.objectId.toUpperCase() == 'KO-DOC-$clean' ||
          d.name.toUpperCase().contains(upper) ||
          d.name.toUpperCase().contains(clean) ||
          d.aliases.any((alias) => alias.toUpperCase() == upper || alias.toUpperCase() == clean)) {
        return d;
      }
    }
    return null;
  }

  @override
  Future<List<DoctrineKnowledgeObject>> getDoctrinesByCategory(DoctrineCategory category) async {
    return _doctrinesList.where((d) => d.category == category).toList();
  }

  @override
  Future<List<DoctrineKnowledgeObject>> getDoctrinesByArticle(String articleNumber) async {
    final target = articleNumber.replaceAll(RegExp(r'^(ARTICLE|ART)\s*', caseSensitive: false), '').trim().toLowerCase();
    if (target.isEmpty) return const [];

    return _doctrinesList.where((d) {
      return d.relatedArticles.any((art) {
        final cleanArt = art.replaceAll(RegExp(r'^(ARTICLE|ART)\s*', caseSensitive: false), '').trim().toLowerCase();
        return cleanArt == target || art.toLowerCase() == target || art.toLowerCase() == 'art $target';
      });
    }).toList();
  }

  @override
  Future<List<DoctrineKnowledgeObject>> getDoctrinesByCase(String caseNameOrId) async {
    final target = caseNameOrId.toLowerCase().trim();
    if (target.isEmpty) return const [];

    return _doctrinesList.where((d) {
      final inOrigin = d.originatingCase.toLowerCase().contains(target);
      final inLandmark = d.landmarkCases.any((c) => c.toLowerCase().contains(target));
      final inSubsequent = d.subsequentCases.any((c) => c.toLowerCase().contains(target));
      return inOrigin || inLandmark || inSubsequent;
    }).toList();
  }

  @override
  Future<List<DoctrineKnowledgeObject>> searchDoctrines(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return _doctrinesList;

    return _doctrinesList.where((d) {
      final inId = d.objectId.toLowerCase().contains(q) || d.doctrineId.toLowerCase().contains(q);
      final inName = d.name.toLowerCase().contains(q);
      final inAliases = d.aliases.any((a) => a.toLowerCase().contains(q));
      final inCategory = d.category.name.toLowerCase().contains(q);
      final inOriginCase = d.originatingCase.toLowerCase().contains(q);
      final inDefinition = d.officialDefinition.toLowerCase().contains(q) || d.plainLanguageExplanation.toLowerCase().contains(q);
      final inCases = d.landmarkCases.any((c) => c.toLowerCase().contains(q));
      final inArticles = d.relatedArticles.any((a) => a.toLowerCase().contains(q));
      final inSummary = d.oneLineSummary.toLowerCase().contains(q) || d.detailedExplanation.toLowerCase().contains(q);

      return inId || inName || inAliases || inCategory || inOriginCase || inDefinition || inCases || inArticles || inSummary;
    }).toList();
  }
}
