import 'package:meta/meta.dart';
import '../domain/entities/knowledge_object.dart';
import '../query/knowledge_query.dart';
import '../query/knowledge_search_hit.dart';
import '../text/knowledge_normalizer.dart';
import '../text/knowledge_synonym_dictionary.dart';
import '../text/knowledge_tokenizer.dart';

/// Relevance ranking engine implementing multi-factor scoring strategy.
@immutable
class KnowledgeRankingEngine {
  final KnowledgeTokenizer tokenizer;
  final KnowledgeNormalizer normalizer;
  final KnowledgeSynonymDictionary synonyms;

  KnowledgeRankingEngine({
    KnowledgeTokenizer? tokenizer,
    KnowledgeNormalizer? normalizer,
    KnowledgeSynonymDictionary? synonyms,
  })  : tokenizer = tokenizer ?? KnowledgeTokenizer(),
        normalizer = normalizer ?? KnowledgeNormalizer(),
        synonyms = synonyms ?? KnowledgeSynonymDictionary();

  /// Computes ranking hit containing total score & score breakdown for a single candidate object.
  KnowledgeSearchHit rank({
    required KnowledgeObject object,
    required KnowledgeQuery query,
    required Set<String> queryTerms,
  }) {
    final scoreBreakdown = <String, double>{};
    final matchedFields = <String>{};

    final titleLower = object.title.toLowerCase();
    final contentLower = object.content.toLowerCase();
    final summaryLower = object.summary?.toLowerCase() ?? '';
    final rawLower = query.rawQuery.toLowerCase().trim();

    // 1. Exact Match (Weight: 10.0)
    double exactMatchScore = 0.0;
    if (rawLower.isNotEmpty) {
      if (titleLower == rawLower || object.id.value.toLowerCase() == rawLower) {
        exactMatchScore = 10.0;
        matchedFields.add('title_exact');
      } else if (titleLower.contains(rawLower)) {
        exactMatchScore = 6.0;
        matchedFields.add('title_substring');
      }
    }
    scoreBreakdown['exact_match'] = exactMatchScore;

    // 2. Alias Match (Weight: 8.0)
    double aliasScore = 0.0;
    final aliases = object.metadata.customAttributes['aliases'];
    if (aliases is List && rawLower.isNotEmpty) {
      for (final alias in aliases) {
        final aStr = alias.toString().toLowerCase();
        if (aStr == rawLower) {
          aliasScore = 8.0;
          matchedFields.add('alias_exact');
          break;
        } else if (aStr.contains(rawLower)) {
          aliasScore = 4.0;
          matchedFields.add('alias_substring');
        }
      }
    }
    scoreBreakdown['alias_match'] = aliasScore;

    // 3. Keyword Density (TF-IDF / Density) (Weight: 5.0)
    double keywordScore = 0.0;
    if (queryTerms.isNotEmpty) {
      for (final term in queryTerms) {
        if (titleLower.contains(term)) {
          keywordScore += 2.0;
          matchedFields.add('title_keyword');
        }
        if (summaryLower.contains(term)) {
          keywordScore += 1.5;
          matchedFields.add('summary_keyword');
        }
        if (contentLower.contains(term)) {
          keywordScore += 1.0;
          matchedFields.add('content_keyword');
        }
        for (final tag in object.tags) {
          if (tag.name.toLowerCase().contains(term)) {
            keywordScore += 1.5;
            matchedFields.add('tag_keyword');
          }
        }
      }
    }
    scoreBreakdown['keyword_density'] = keywordScore;

    // 4. Relationship Score (Weight: 3.0)
    double relScore = object.relationships.length * 0.5;
    if (relScore > 3.0) relScore = 3.0;
    scoreBreakdown['relationship_score'] = relScore;

    // 5. Editorial Confidence (Weight: 2.0)
    double editorialScore = 1.0;
    final status = object.metadata.customAttributes['editorial_status'];
    if (status == 'verified' || status == 'published') {
      editorialScore = 2.0;
    }
    scoreBreakdown['editorial_confidence'] = editorialScore;

    // 6. Evidence Score (Weight: 3.0)
    double evidenceScore = object.evidenceReferences.length * 1.0;
    if (evidenceScore > 3.0) evidenceScore = 3.0;
    scoreBreakdown['evidence_score'] = evidenceScore;

    // 7. Knowledge Graph Connectivity (Weight: 2.0)
    double graphScore = (object.relationships.length + object.references.length + object.citations.length) * 0.2;
    if (graphScore > 2.0) graphScore = 2.0;
    scoreBreakdown['graph_connectivity'] = graphScore;

    // 8. Recency (Weight: 2.0)
    double recencyScore = 1.0;
    final year = object.metadata.customAttributes['year'];
    if (year is int && year >= 2020) {
      recencyScore = 2.0;
    }
    scoreBreakdown['recency'] = recencyScore;

    // Aggregate total normalized score
    final totalScore = exactMatchScore +
        aliasScore +
        keywordScore +
        relScore +
        editorialScore +
        evidenceScore +
        graphScore +
        recencyScore;

    return KnowledgeSearchHit(
      object: object,
      score: double.parse(totalScore.toStringAsFixed(3)),
      matchedFields: matchedFields,
      scoreBreakdown: scoreBreakdown,
      snippet: object.summary ?? (object.content.length > 120 ? '${object.content.substring(0, 120)}...' : object.content),
    );
  }
}
