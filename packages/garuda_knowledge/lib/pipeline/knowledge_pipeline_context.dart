import '../domain/entities/knowledge_object.dart';

class KnowledgePipelineContext {
  final KnowledgeObject inputObject;
  final String packageName;
  final DateTime startTime;
  final Map<String, dynamic> metadata;

  KnowledgeObject? previousState;
  bool isUpdateOperation = false;

  KnowledgePipelineContext({
    required this.inputObject,
    this.packageName = 'default',
    required this.startTime,
    this.metadata = const {},
    this.previousState,
  });
}
