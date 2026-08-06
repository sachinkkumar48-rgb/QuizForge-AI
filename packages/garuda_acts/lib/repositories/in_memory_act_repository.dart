library;

import '../domain/entities/act_knowledge_object.dart';
import '../domain/entities/act_section.dart';
import '../domain/entities/act_enums.dart';
import '../data/phase1_acts_corpus.dart';
import 'act_repository.dart';

/// Production-ready In-Memory implementation of ActRepository.
class InMemoryActRepository implements ActRepository {
  final Map<String, ActKnowledgeObject> _actMap = {};
  final Map<String, ActSection> _sectionMap = {};

  InMemoryActRepository({List<ActKnowledgeObject>? initialActs}) {
    final acts = initialActs ?? Phase1ActsCorpus.phase1Acts;
    for (final act in acts) {
      registerAct(act);
    }
  }

  @override
  List<ActKnowledgeObject> getAllActs() {
    return List.unmodifiable(_actMap.values);
  }

  @override
  ActKnowledgeObject? getActById(String actId) {
    return _actMap[actId];
  }

  @override
  ActSection? getSectionById(String sectionId) {
    return _sectionMap[sectionId];
  }

  @override
  List<ActSection> getSectionsForAct(String actId) {
    final act = _actMap[actId];
    if (act == null) return [];
    return act.sections;
  }

  @override
  List<ActKnowledgeObject> getActsByCategory(ActCategory category) {
    return _actMap.values.where((a) => a.metadata.category == category).toList();
  }

  @override
  List<ActKnowledgeObject> getActsByStatus(ActStatus status) {
    return _actMap.values.where((a) => a.metadata.status == status).toList();
  }

  @override
  List<ActKnowledgeObject> searchActs(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAllActs();

    return _actMap.values.where((act) {
      final titleMatch = act.metadata.shortTitle.toLowerCase().contains(q) ||
          act.metadata.officialName.toLowerCase().contains(q);
      final keywordMatch = act.searchKeywords.any((k) => k.toLowerCase().contains(q));
      final sectionMatch = act.sections.any((s) =>
          s.sectionNumber.toLowerCase().contains(q) ||
          s.title.toLowerCase().contains(q) ||
          s.keywords.any((k) => k.toLowerCase().contains(q)));

      return titleMatch || keywordMatch || sectionMatch;
    }).toList();
  }

  @override
  void registerAct(ActKnowledgeObject act) {
    _actMap[act.actId] = act;
    for (final sec in act.sections) {
      _sectionMap[sec.sectionId] = sec;
    }
  }
}
