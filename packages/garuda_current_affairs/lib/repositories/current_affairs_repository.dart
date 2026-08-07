library;

import '../domain/entities/current_affairs_enums.dart';
import '../domain/entities/current_affairs_knowledge_object.dart';
import '../domain/entities/news_event.dart';
import '../search/current_affairs_search_engine.dart';

abstract class CurrentAffairsRepository {
  Future<void> saveNewsEvent(NewsEvent event);
  Future<NewsEvent?> getNewsEventById(String id);
  Future<List<NewsEvent>> getAllNewsEvents();

  Future<void> saveKnowledgeObject(CurrentAffairsKnowledgeObject object);
  Future<CurrentAffairsKnowledgeObject?> getKnowledgeObjectById(String id);
  Future<List<CurrentAffairsKnowledgeObject>> getAllKnowledgeObjects();
  Future<List<CurrentAffairsKnowledgeObject>> getByCategory(CurrentAffairsCategory category);

  Future<List<CurrentAffairsKnowledgeObject>> searchObjects(CurrentAffairsSearchQuery query);
}
