library;

import '../data/constitution_seed_data.dart';
import '../domain/entities/article_knowledge_object.dart';
import '../domain/entities/constitution_knowledge_object.dart';
import '../domain/entities/constitution_metadata.dart';
import '../domain/entities/part_knowledge_object.dart';
import '../domain/entities/preamble_knowledge_object.dart';
import '../domain/entities/schedule_knowledge_object.dart';
import 'constitution_repository.dart';

/// Thread-safe offline-first repository implementation of [ConstitutionRepository].
class InMemoryConstitutionRepository implements ConstitutionRepository {
  final ConstitutionMetadata _metadata;
  final PreambleKnowledgeObject _preamble;
  final List<PartKnowledgeObject> _partsList;
  final List<ScheduleKnowledgeObject> _schedulesList;
  final List<ArticleKnowledgeObject> _articlesList;
  final Map<String, PartKnowledgeObject> _partsMap = {};
  final Map<String, ScheduleKnowledgeObject> _schedulesMap = {};
  final Map<String, ArticleKnowledgeObject> _articlesMap = {};
  final Map<String, ConstitutionKnowledgeObject> _allObjectsMap = {};

  InMemoryConstitutionRepository({
    ConstitutionMetadata? metadata,
    PreambleKnowledgeObject? preamble,
    List<PartKnowledgeObject>? parts,
    List<ScheduleKnowledgeObject>? schedules,
    List<ArticleKnowledgeObject>? articles,
  })  : _metadata = metadata ?? ConstitutionSeedData.metadata,
        _preamble = preamble ?? ConstitutionSeedData.preamble,
        _partsList = parts ?? ConstitutionSeedData.parts,
        _schedulesList = schedules ?? ConstitutionSeedData.schedules,
        _articlesList = articles ?? ConstitutionSeedData.articles {
    for (final p in _partsList) {
      _partsMap[p.objectId] = p;
      _allObjectsMap[p.objectId] = p;
    }

    for (final s in _schedulesList) {
      _schedulesMap[s.objectId] = s;
      _allObjectsMap[s.objectId] = s;
    }

    for (final a in _articlesList) {
      _articlesMap[a.objectId] = a;
      _articlesMap[a.articleNumber.toUpperCase()] = a;
      _allObjectsMap[a.objectId] = a;
    }

    _allObjectsMap[_preamble.objectId] = _preamble;
  }

  @override
  Future<ConstitutionMetadata> getMetadata() async => _metadata;

  @override
  Future<PreambleKnowledgeObject> getPreamble() async => _preamble;

  @override
  Future<List<PartKnowledgeObject>> getParts() async => _partsList;

  @override
  Future<List<ScheduleKnowledgeObject>> getSchedules() async => _schedulesList;

  @override
  Future<List<ArticleKnowledgeObject>> getArticles() async => _articlesList;

  @override
  Future<PartKnowledgeObject?> findPart(String idOrNumber) async {
    final clean = idOrNumber.trim().toUpperCase();

    // Direct objectId match
    if (_partsMap.containsKey(clean)) return _partsMap[clean];
    if (_partsMap.containsKey('KO-PART-$clean')) return _partsMap['KO-PART-$clean'];

    // Match part number, title, or alias
    for (final p in _partsList) {
      if (p.partNumber.toUpperCase() == clean ||
          p.title.toUpperCase().contains('PART $clean:') ||
          p.title.toUpperCase().contains('PART $clean ') ||
          p.objectId.endsWith('-$clean')) {
        return p;
      }
    }
    return null;
  }

  @override
  Future<ScheduleKnowledgeObject?> findSchedule(String idOrNumber) async {
    final clean = idOrNumber.trim().toUpperCase();

    // Direct objectId match
    if (_schedulesMap.containsKey(clean)) return _schedulesMap[clean];
    if (_schedulesMap.containsKey('KO-SCHED-$clean')) return _schedulesMap['KO-SCHED-$clean'];

    // Match schedule number, title, or alias
    for (final s in _schedulesList) {
      if (s.scheduleNumber.toUpperCase() == clean ||
          s.title.toUpperCase().contains('SCHEDULE $clean:') ||
          s.title.toUpperCase().contains('SCHEDULE $clean ') ||
          s.objectId.endsWith('-$clean')) {
        return s;
      }
    }
    return null;
  }

  @override
  Future<ArticleKnowledgeObject?> findArticle(String articleNumber) async {
    final raw = articleNumber.trim();
    if (raw.isEmpty) return null;

    if (_articlesMap.containsKey(raw)) return _articlesMap[raw];
    if (_articlesMap.containsKey(raw.toUpperCase())) return _articlesMap[raw.toUpperCase()];

    final clean = raw.replaceAll(RegExp(r'^(ARTICLE|ART)\s*', caseSensitive: false), '').trim().toUpperCase();

    if (_articlesMap.containsKey(clean)) return _articlesMap[clean];
    if (_articlesMap.containsKey('KO-ART-$clean')) return _articlesMap['KO-ART-$clean'];

    for (final a in _articlesList) {
      if (a.articleNumber.toUpperCase() == clean ||
          a.objectId.toUpperCase() == clean ||
          a.objectId.toUpperCase() == 'KO-ART-$clean' ||
          a.aliases.any((alias) => alias.toUpperCase() == clean || alias.toUpperCase() == raw.toUpperCase())) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<List<ArticleKnowledgeObject>> getArticlesByPart(String partIdOrNumber) async {
    final clean = partIdOrNumber.trim().toUpperCase();
    return _articlesList.where((a) {
      return a.part.toUpperCase() == clean ||
          a.part.toUpperCase() == 'PART $clean' ||
          a.relatedParts.any((p) => p.toUpperCase().contains(clean));
    }).toList();
  }

  @override
  Future<List<ConstitutionKnowledgeObject>> findByArticle(String article) async {
    final target = article.toLowerCase().trim();
    if (target.isEmpty) return const [];

    return _allObjectsMap.values.where((obj) {
      if (obj is ArticleKnowledgeObject) {
        return obj.articleNumber.toLowerCase() == target ||
            obj.title.toLowerCase().contains(target) ||
            obj.relatedArticles.any((art) => art.toLowerCase().contains(target));
      }
      return obj.relatedArticles.any((art) => art.toLowerCase().contains(target));
    }).toList();
  }

  @override
  Future<List<ConstitutionKnowledgeObject>> findByAmendment(String amendment) async {
    final target = amendment.toLowerCase().trim();
    if (target.isEmpty) return const [];

    return _allObjectsMap.values.where((obj) {
      return obj.relatedAmendments.any((amd) => amd.toLowerCase().contains(target));
    }).toList();
  }

  @override
  Future<ConstitutionKnowledgeObject?> getObjectById(String objectId) async {
    return _allObjectsMap[objectId];
  }

  @override
  Future<List<ConstitutionKnowledgeObject>> searchObjects(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return _allObjectsMap.values.toList();

    return _allObjectsMap.values.where((obj) {
      final inId = obj.objectId.toLowerCase().contains(q);
      final inTitle = obj.title.toLowerCase().contains(q);
      final inOfficial = obj.officialName.toLowerCase().contains(q);
      final inDesc = obj.description.toLowerCase().contains(q);
      final inKeywords = obj.keywords.any((k) => k.toLowerCase().contains(q));
      final inArticles = obj.relatedArticles.any((a) => a.toLowerCase().contains(q));
      final inAmendments = obj.relatedAmendments.any((a) => a.toLowerCase().contains(q));
      final inCases = obj.relatedCases.any((c) => c.toLowerCase().contains(q));

      bool inPartOrSchedOrArt = false;
      if (obj is PartKnowledgeObject) {
        inPartOrSchedOrArt = obj.partNumber.toLowerCase() == q || 'part ${obj.partNumber.toLowerCase()}' == q;
      } else if (obj is ScheduleKnowledgeObject) {
        inPartOrSchedOrArt = obj.scheduleNumber.toLowerCase() == q || 'schedule ${obj.scheduleNumber.toLowerCase()}' == q;
      } else if (obj is ArticleKnowledgeObject) {
        inPartOrSchedOrArt = obj.articleNumber.toLowerCase() == q ||
            'article ${obj.articleNumber.toLowerCase()}' == q ||
            obj.searchKeywords.any((k) => k.toLowerCase().contains(q)) ||
            obj.originalGarudaExplanation.toLowerCase().contains(q) ||
            obj.caseLaw.any((c) =>
                c.caseName.toLowerCase().contains(q) ||
                c.legalPrinciple.toLowerCase().contains(q) ||
                c.importance.toLowerCase().contains(q)) ||
            obj.amendmentHistory.any((a) =>
                a.amendmentName.toLowerCase().contains(q) ||
                a.reason.toLowerCase().contains(q)) ||
            obj.keyTakeaways.any((k) => k.toLowerCase().contains(q)) ||
            obj.revisionPoints.any((r) => r.toLowerCase().contains(q)) ||
            obj.pyqIds.any((p) => p.toLowerCase().contains(q));
      }

      return inId || inTitle || inOfficial || inDesc || inKeywords || inArticles || inAmendments || inCases || inPartOrSchedOrArt;
    }).toList();
  }
}

