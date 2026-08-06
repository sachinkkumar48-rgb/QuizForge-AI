import '../pipeline/knowledge_pipeline_context.dart';
import '../pipeline/knowledge_pipeline_result.dart';

abstract class KnowledgePipelineMiddleware {
  Future<void> preProcess(KnowledgePipelineContext context) async {}
  Future<void> postProcess(KnowledgePipelineContext context, KnowledgePipelineResult result) async {}
}
