import 'package:meta/meta.dart';

/// Tokenizer for knowledge text processing.
@immutable
class KnowledgeTokenizer {
  static final RegExp _wordBoundaryRegex = RegExp(r'[^\w\d_]+');

  /// Tokenizes string input into lowercase terms.
  List<String> tokenize(String input) {
    if (input.trim().isEmpty) return const [];
    return input
        .toLowerCase()
        .split(_wordBoundaryRegex)
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Generates N-grams (min 2, max 5) for prefix/substring matching.
  List<String> generateNGrams(String input, {int minLength = 2, int maxLength = 10}) {
    final tokens = tokenize(input);
    final nGrams = <String>{};

    for (final token in tokens) {
      final len = token.length;
      for (int i = 0; i < len; i++) {
        for (int j = i + minLength; j <= len && (j - i) <= maxLength; j++) {
          nGrams.add(token.substring(i, j));
        }
      }
    }
    return nGrams.toList();
  }
}
