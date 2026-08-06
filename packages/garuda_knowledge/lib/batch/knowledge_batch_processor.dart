import '../domain/entities/knowledge_object.dart';
import '../pipeline/knowledge_pipeline_result.dart';
import '../pipeline/knowledge_registration_pipeline.dart';

typedef BatchProgressCallback = void Function(int processed, int total, double percentage);

class BatchProcessingResult {
  final int totalProcessed;
  final int successCount;
  final int failureCount;
  final List<KnowledgePipelineResult> results;
  final double durationMs;

  const BatchProcessingResult({
    required this.totalProcessed,
    required this.successCount,
    required this.failureCount,
    required this.results,
    required this.durationMs,
  });
}

class KnowledgeBatchProcessor {
  final KnowledgeRegistrationPipeline pipeline;

  KnowledgeBatchProcessor(this.pipeline);

  Future<KnowledgePipelineResult> processSingle(
    KnowledgeObject object, {
    String packageName = 'default',
  }) async {
    return pipeline.process(object, packageName: packageName);
  }

  Future<BatchProcessingResult> processBatch(
    List<KnowledgeObject> objects, {
    String packageName = 'default',
    BatchProgressCallback? onProgress,
  }) async {
    final start = DateTime.now();
    final results = <KnowledgePipelineResult>[];
    int success = 0;
    int failure = 0;

    for (int i = 0; i < objects.length; i++) {
      final obj = objects[i];
      final res = await pipeline.process(obj, packageName: packageName);
      results.add(res);
      if (res.isSuccess) {
        success++;
      } else {
        failure++;
      }
      onProgress?.call(i + 1, objects.length, ((i + 1) / objects.length) * 100.0);
    }

    final durationMs = DateTime.now().difference(start).inMicroseconds / 1000.0;
    return BatchProcessingResult(
      totalProcessed: objects.length,
      successCount: success,
      failureCount: failure,
      results: results,
      durationMs: durationMs,
    );
  }

  Future<BatchProcessingResult> processIncremental(
    List<KnowledgeObject> objects, {
    String packageName = 'default',
  }) async {
    return processBatch(objects, packageName: packageName);
  }
}
