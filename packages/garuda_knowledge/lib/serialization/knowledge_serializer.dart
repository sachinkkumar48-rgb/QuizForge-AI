import 'dart:convert';
import '../domain/entities/knowledge_object.dart';
import '../domain/entities/knowledge_relationship.dart';

abstract class StorageAdapter {
  Future<void> saveObject(Map<String, dynamic> json);
  Future<Map<String, dynamic>?> readObject(String id);
  Future<List<Map<String, dynamic>>> readAll();
  Future<void> deleteObject(String id);
}

class KnowledgeSerializer {
  static String serializeObject(KnowledgeObject object) {
    return jsonEncode(object.toJson());
  }

  static KnowledgeObject deserializeObject(String rawJson) {
    final Map<String, dynamic> map = jsonDecode(rawJson) as Map<String, dynamic>;
    return KnowledgeObject.fromJson(map);
  }

  static String serializeRelationship(KnowledgeRelationship relationship) {
    return jsonEncode(relationship.toJson());
  }

  static KnowledgeRelationship deserializeRelationship(String rawJson) {
    final Map<String, dynamic> map = jsonDecode(rawJson) as Map<String, dynamic>;
    return KnowledgeRelationship.fromJson(map);
  }

  static List<String> serializeObjectList(List<KnowledgeObject> objects) {
    return objects.map(serializeObject).toList();
  }

  static List<KnowledgeObject> deserializeObjectList(List<String> rawJsonList) {
    return rawJsonList.map(deserializeObject).toList();
  }
}
