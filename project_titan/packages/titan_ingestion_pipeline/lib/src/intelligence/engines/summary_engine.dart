import 'package:titan_ai/titan_ai.dart';
import '../../models/knowledge_object.dart';
import '../models/generated_learning_assets.dart';

/// Summary Engine producing 30-second, 5-minute, and detailed summaries from KnowledgeObjects.
class SummaryEngine {
  final AIService? aiService;

  SummaryEngine({this.aiService});

  /// Generates a complete [SummaryBundle] from a canonical [KnowledgeObject].
  Future<SummaryBundle> generate(KnowledgeObject obj) async {
    final textBlocks = obj.contentBlocks
        .map((b) => b.toJson()['text'] ?? '')
        .where((t) => (t as String).isNotEmpty)
        .cast<String>()
        .join('\n');
    final title = obj.title;

    // Pure Dart default fallback summaries
    var summary30s =
        '30s Overview: $title covers ${obj.concepts.take(3).map((c) => c.name).join(', ')}. Key takeaways include fundamental principles and legal frameworks.';
    var summary5m =
        '5m Executive Summary for $title:\n• Main Topic: $title\n• Key Concepts: ${obj.keywords.take(5).join(', ')}\n• Core Analysis: $textBlocks\n• Summary: Extracted from canonical KnowledgeObject.';
    var detailedSummary =
        'Detailed Analysis for $title:\n\n1. Overview:\n$textBlocks\n\n2. Key Concepts & Terms:\n${obj.concepts.map((c) => '- ${c.name}: ${c.description}').join('\n')}\n\n3. Glossary & References:\n${obj.glossary.map((g) => '- ${g.term}: ${g.definition}').join('\n')}';

    // Optional LLM enhancement if AIService is provided
    if (aiService != null && textBlocks.isNotEmpty) {
      try {
        final prompt =
            'Synthesize a 30-second bullet summary for "$title":\n$textBlocks';
        final resp = await aiService!
            .generate<String>(AIRequest(prompt: prompt, model: 'gemini-flash'));
        if (resp.text.trim().isNotEmpty) {
          summary30s = resp.text.trim();
        }
      } catch (_) {}
    }

    return SummaryBundle(
      summary30s: summary30s,
      summary5m: summary5m,
      detailedSummary: detailedSummary,
    );
  }
}
