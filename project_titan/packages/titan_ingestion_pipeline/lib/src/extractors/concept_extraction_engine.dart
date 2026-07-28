import 'package:titan_ai/titan_ai.dart';
import '../models/glossary_item.dart';
import '../models/knowledge_concept.dart';

/// Container for extracted concept results.
class ConceptExtractionResult {
  final List<KnowledgeConcept> concepts;
  final List<GlossaryItem> glossary;
  final List<String> keywords;

  ConceptExtractionResult({
    required this.concepts,
    required this.glossary,
    required this.keywords,
  });
}

/// Concept & Glossary Extraction Engine for Knowledge Ingestion Pipeline.
class ConceptExtractionEngine {
  final AIService? aiService;

  ConceptExtractionEngine({this.aiService});

  /// Extracts concepts, glossary terms, keywords, and learning objectives from document text.
  Future<ConceptExtractionResult> extract(
      String text, String documentTitle) async {
    final concepts = <KnowledgeConcept>[];
    final glossary = <GlossaryItem>[];
    final keywords = <String>{};

    var conceptIdCounter = 1;
    String nextId() => 'c_${conceptIdCounter++}';

    // 1. Rule-based extraction for Articles (e.g. Article 21, Article 370)
    final articleMatches =
        RegExp(r'\bArticle\s+\d+[A-Z]?\b', caseSensitive: false)
            .allMatches(text);
    for (final match in articleMatches) {
      final name = match.group(0)!;
      keywords.add(name);
      concepts.add(KnowledgeConcept(
        id: nextId(),
        name: name,
        type: ConceptType.article,
        description: 'Constitutional provision: $name',
      ));
    }

    // 2. Rule-based extraction for Acts (e.g. Right to Information Act, 2005)
    final actMatches =
        RegExp(r'\b[A-Z][a-zA-Z\s]+Act(?:,\s*\d{4})?\b').allMatches(text);
    for (final match in actMatches) {
      final name = match.group(0)!.trim();
      if (name.length > 5 && !name.contains('\n')) {
        keywords.add(name);
        concepts.add(KnowledgeConcept(
          id: nextId(),
          name: name,
          type: ConceptType.act,
          description: 'Legislative act: $name',
        ));
      }
    }

    // 3. Rule-based extraction for Dates/Years (e.g. 1947, 26th January 1950)
    final dateMatches =
        RegExp(r'\b(?:\d{1,2}(?:st|nd|rd|th)?\s+[A-Z][a-z]+\s+)?\d{4}\b')
            .allMatches(text);
    for (final match in dateMatches) {
      final name = match.group(0)!;
      concepts.add(KnowledgeConcept(
        id: nextId(),
        name: name,
        type: ConceptType.date,
        description: 'Historical date: $name',
      ));
    }

    // 4. Rule-based extraction for Definitions (e.g. "Term" is defined as ...)
    final defMatches = RegExp(
            r'(?:"([^"]+)"|([A-Z][a-zA-Z\s]+))\s+(?:is defined as|refers to|means)\s+([^.\n]+)',
            caseSensitive: false)
        .allMatches(text);
    for (final match in defMatches) {
      final term = match.group(1) ?? match.group(2) ?? 'Term';
      final def = match.group(3) ?? '';
      if (term.isNotEmpty && def.isNotEmpty) {
        keywords.add(term);
        glossary.add(GlossaryItem(term: term.trim(), definition: def.trim()));
        concepts.add(KnowledgeConcept(
          id: nextId(),
          name: term.trim(),
          type: ConceptType.definition,
          description: def.trim(),
        ));
      }
    }

    // 5. Extract fallback keywords from title & frequent words
    for (final word in documentTitle.split(RegExp(r'\s+'))) {
      if (word.length > 3) keywords.add(word);
    }

    // 6. Optional AI LLM enrichment if AIService is available
    if (aiService != null && text.length > 100) {
      try {
        final prompt =
            'Extract key concepts (facts, committees, schemes, people, places, events, terminology) from text:\n"${text.substring(0, text.length > 500 ? 500 : text.length)}"\nReturn a bullet list of concepts.';
        final resp = await aiService!.generate<String>(
          AIRequest(prompt: prompt, model: 'gemini-flash'),
        );
        for (final line in resp.text.split('\n')) {
          final trimmed = line.replaceAll(RegExp(r'^[-*•\d.]+\s*'), '').trim();
          if (trimmed.isNotEmpty && trimmed.length < 50) {
            keywords.add(trimmed);
            concepts.add(KnowledgeConcept(
              id: nextId(),
              name: trimmed,
              type: ConceptType.terminology,
              description: 'AI Extracted concept for $documentTitle',
            ));
          }
        }
      } catch (_) {
        // Fallback gracefully on pure Dart matching
      }
    }

    return ConceptExtractionResult(
      concepts: concepts,
      glossary: glossary,
      keywords: keywords.toList(),
    );
  }
}
