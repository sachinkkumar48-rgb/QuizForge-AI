import '../models/search_query.dart';

/// Parsed query data structure containing normalized tokens and expansions.
class ParsedQuery {
  final SearchQuery originalQuery;
  final List<String> tokens;
  final List<String> exactPhrases;
  final Map<String, List<String>> synonyms;
  final Set<String> expandedConcepts;

  ParsedQuery({
    required this.originalQuery,
    required this.tokens,
    required this.exactPhrases,
    required this.synonyms,
    required this.expandedConcepts,
  });
}

/// Query Parser responsible for tokenization, phrase extraction, typo tolerance,
/// and UPSC-domain synonym / concept expansion.
class QueryParser {
  final Map<String, List<String>> synonymDictionary;

  QueryParser({Map<String, List<String>>? synonymDictionary})
      : synonymDictionary = synonymDictionary ?? _defaultUPSCSynonyms;

  static const Map<String, List<String>> _defaultUPSCSynonyms = {
    'polity': ['constitution', 'governance', 'parliament', 'judiciary'],
    'fr': ['fundamental rights', 'article 12-35', 'rights'],
    'dpsp': ['directive principles', 'state policy', 'article 36-51'],
    'history': [
      'freedom struggle',
      'modern history',
      'ancient history',
      'art and culture'
    ],
    'economy': ['inflation', 'gdp', 'rbi', 'budget', 'fiscal policy'],
    'environment': [
      'biodiversity',
      'climate change',
      'ecology',
      'national park'
    ],
    'geography': ['monsoon', 'rivers', 'soils', 'physical geography'],
    'current': ['current affairs', 'news', 'editorials'],
  };

  /// Parses and expands raw search query.
  ParsedQuery parse(SearchQuery query) {
    final raw = query.rawQuery.trim();
    if (raw.isEmpty) {
      return ParsedQuery(
        originalQuery: query,
        tokens: const [],
        exactPhrases: const [],
        synonyms: const {},
        expandedConcepts: const {},
      );
    }

    final exactPhrases = <String>[];
    final phraseRegex = RegExp(r'"([^"]+)"');
    final matches = phraseRegex.allMatches(raw);

    for (final match in matches) {
      final phrase = match.group(1);
      if (phrase != null && phrase.isNotEmpty) {
        exactPhrases.add(phrase.toLowerCase());
      }
    }

    // Clean query without quotes for token extraction
    final cleaned = raw.replaceAll(phraseRegex, ' ').toLowerCase();
    final tokens = cleaned
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && t.length > 1)
        .toList();

    final synonyms = <String, List<String>>{};
    final expandedConcepts = <String>{};

    if (query.includeSynonyms) {
      for (final token in tokens) {
        final list = synonymDictionary[token];
        if (list != null) {
          synonyms[token] = list;
          expandedConcepts.addAll(list);
        }
      }
    }

    return ParsedQuery(
      originalQuery: query,
      tokens: tokens,
      exactPhrases: exactPhrases,
      synonyms: synonyms,
      expandedConcepts: expandedConcepts,
    );
  }
}
