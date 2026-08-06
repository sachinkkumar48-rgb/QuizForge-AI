library;

import '../domain/entities/act_knowledge_object.dart';
import '../domain/entities/act_section.dart';
import '../domain/entities/act_enums.dart';

/// Repository interface for accessing Central Acts Knowledge Objects.
abstract class ActRepository {
  /// Get all Acts.
  List<ActKnowledgeObject> getAllActs();

  /// Find Act by ID.
  ActKnowledgeObject? getActById(String actId);

  /// Find Section by ID across all Acts.
  ActSection? getSectionById(String sectionId);

  /// Get Sections for a given Act.
  List<ActSection> getSectionsForAct(String actId);

  /// Find Acts by category.
  List<ActKnowledgeObject> getActsByCategory(ActCategory category);

  /// Find Acts by status.
  List<ActKnowledgeObject> getActsByStatus(ActStatus status);

  /// Search Acts by keyword query.
  List<ActKnowledgeObject> searchActs(String query);

  /// Register/upsert an Act.
  void registerAct(ActKnowledgeObject act);
}
