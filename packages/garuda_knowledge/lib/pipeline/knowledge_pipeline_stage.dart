import 'knowledge_pipeline_context.dart';

abstract class KnowledgePipelineStage {
  int get stageNumber;
  String get stageName;

  Future<void> execute(KnowledgePipelineContext context);
}
