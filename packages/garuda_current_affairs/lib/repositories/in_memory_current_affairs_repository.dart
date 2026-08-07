library;

import '../domain/entities/current_affairs_enums.dart';
import '../domain/entities/current_affairs_knowledge_object.dart';
import '../domain/entities/news_event.dart';
import '../search/current_affairs_search_engine.dart';
import 'current_affairs_repository.dart';

class InMemoryCurrentAffairsRepository implements CurrentAffairsRepository {
  final Map<String, NewsEvent> _events = {};
  final Map<String, CurrentAffairsKnowledgeObject> _objects = {};

  @override
  Future<void> saveNewsEvent(NewsEvent event) async {
    _events[event.id] = event;
  }

  @override
  Future<NewsEvent?> getNewsEventById(String id) async {
    return _events[id];
  }

  @override
  Future<List<NewsEvent>> getAllNewsEvents() async {
    return List.unmodifiable(_events.values.toList());
  }

  @override
  Future<void> saveKnowledgeObject(CurrentAffairsKnowledgeObject object) async {
    _objects[object.id] = object;
  }

  @override
  Future<CurrentAffairsKnowledgeObject?> getKnowledgeObjectById(String id) async {
    return _objects[id];
  }

  @override
  Future<List<CurrentAffairsKnowledgeObject>> getAllKnowledgeObjects() async {
    return List.unmodifiable(_objects.values.toList());
  }

  @override
  Future<List<CurrentAffairsKnowledgeObject>> getByCategory(CurrentAffairsCategory category) async {
    return _objects.values.where((obj) => obj.category == category).toList();
  }

  @override
  Future<List<CurrentAffairsKnowledgeObject>> searchObjects(CurrentAffairsSearchQuery query) async {
    return CurrentAffairsSearchEngine.search(
      objects: _objects.values.toList(),
      query: query,
    );
  }

  void clear() {
    _events.clear();
    _objects.clear();
  }
}
