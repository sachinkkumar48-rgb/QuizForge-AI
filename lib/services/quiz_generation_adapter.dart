import 'package:knowledge_engine/knowledge_engine.dart';

/// Adapter class that transforms Knowledge Intelligence Engine outputs
/// ([PipelineResult] or [KnowledgeObject] lists) into normalized prompt text
/// consumed by the QuizForge AI quiz generator.
class QuizGenerationAdapter {
  const QuizGenerationAdapter();

  /// Extracts and reconstructs clean normalized text from a [PipelineResult].
  String preparePromptText(PipelineResult pipelineResult) {
    if (pipelineResult.objects.isEmpty) {
      return '';
    }

    return preparePromptTextFromObjects(pipelineResult.objects);
  }

  /// Extracts and combines text content from a list of [KnowledgeObject] entities.
  String preparePromptTextFromObjects(List<KnowledgeObject> objects) {
    if (objects.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();

    for (var i = 0; i < objects.length; i++) {
      final obj = objects[i];

      // Prefer full chunk text from metadata if available, otherwise summary
      final textContent =
          obj.metadata['fullChunkText'] as String? ?? obj.summary;

      if (textContent.trim().isNotEmpty) {
        if (buffer.isNotEmpty) {
          buffer.write('\n\n');
        }
        buffer.write(textContent.trim());
      }
    }

    return buffer.toString();
  }
}
