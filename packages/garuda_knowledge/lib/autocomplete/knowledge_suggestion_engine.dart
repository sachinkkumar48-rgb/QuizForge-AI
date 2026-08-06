import '../indexing/knowledge_index.dart';
import '../text/knowledge_synonym_dictionary.dart';
import '../text/knowledge_tokenizer.dart';

/// Suggestion engine providing did-you-mean spelling correction and query expansion.
class KnowledgeSuggestionEngine {
  final KnowledgeIndex index;
  final KnowledgeSynonymDictionary synonyms;
  final KnowledgeTokenizer tokenizer;

  KnowledgeSuggestionEngine({
    required this.index,
    KnowledgeSynonymDictionary? synonyms,
    KnowledgeTokenizer? tokenizer,
  })  : synonyms = synonyms ?? KnowledgeSynonymDictionary(),
        tokenizer = tokenizer ?? KnowledgeTokenizer();

  /// Returns suggested corrections or synonym expansions for a raw query string.
  List<String> suggest(String query, {int maxDistance = 2, int limit = 5}) {
    if (query.trim().isEmpty) return const [];
    final tokens = tokenizer.tokenize(query);
    final suggestions = <String>{};

    for (final token in tokens) {
      // 1. Synonym Expansion
      final expanded = synonyms.expand(token);
      for (final exp in expanded) {
        if (exp != token) suggestions.add(exp);
      }

      // 2. Levenshtein Edit Distance matching against index titles
      for (final obj in index.storedObjects.values) {
        final titleTokens = tokenizer.tokenize(obj.title);
        for (final titleToken in titleTokens) {
          if (titleToken != token && _levenshteinDistance(token, titleToken) <= maxDistance) {
            suggestions.add(titleToken);
          }
        }
      }
    }

    return suggestions.take(limit).toList();
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }
}
