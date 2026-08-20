library;

import 'dart:math';

import 'package:titan_pdf/titan_pdf.dart';

import '../domain/entities/ai_reading_task.dart';

/// Lightweight document context retrieval engine (Local RAG) using keyword and term overlap.
class AIRetrievalEngine {
  const AIRetrievalEngine();

  static const Set<String> _stopwords = {
    'a',
    'about',
    'above',
    'after',
    'again',
    'against',
    'all',
    'am',
    'an',
    'and',
    'any',
    'are',
    'as',
    'at',
    'be',
    'because',
    'been',
    'before',
    'being',
    'below',
    'between',
    'both',
    'but',
    'by',
    'could',
    'did',
    'do',
    'does',
    'doing',
    'down',
    'during',
    'each',
    'few',
    'for',
    'from',
    'further',
    'had',
    'has',
    'have',
    'having',
    'he',
    'her',
    'here',
    'hers',
    'herself',
    'him',
    'himself',
    'his',
    'how',
    'i',
    'if',
    'in',
    'into',
    'is',
    'it',
    'its',
    'itself',
    'just',
    'me',
    'more',
    'most',
    'my',
    'myself',
    'no',
    'nor',
    'not',
    'now',
    'of',
    'off',
    'on',
    'once',
    'only',
    'or',
    'other',
    'ought',
    'our',
    'ours',
    'ourselves',
    'out',
    'over',
    'own',
    'same',
    'she',
    'should',
    'so',
    'some',
    'such',
    'than',
    'that',
    'the',
    'their',
    'theirs',
    'them',
    'themselves',
    'then',
    'there',
    'these',
    'they',
    'this',
    'those',
    'through',
    'to',
    'too',
    'under',
    'until',
    'up',
    'very',
    'was',
    'we',
    'were',
    'what',
    'when',
    'where',
    'which',
    'while',
    'who',
    'whom',
    'why',
    'with',
    'would',
    'you',
    'your',
    'yours',
    'yourself',
    'yourselves'
  };

  static String _normalizeDiacritics(String text) {
    return text
        .replaceAll(RegExp(r'[àáâãäåāăą]'), 'a')
        .replaceAll(RegExp(r'[èéêëēĕėęě]'), 'e')
        .replaceAll(RegExp(r'[ìíîïīĭį]'), 'i')
        .replaceAll(RegExp(r'[òóôõöøōŏő]'), 'o')
        .replaceAll(RegExp(r'[ùúûüũūŭůűų]'), 'u')
        .replaceAll(RegExp(r'[ñńňņ]'), 'n')
        .replaceAll(RegExp(r'[çćčĉċ]'), 'c')
        .replaceAll(RegExp(r'[ÿý]'), 'y')
        .replaceAll(RegExp(r'[ß]'), 'ss');
  }

  /// Tokenizes string into lower-cased meaningful keyword stems.
  static Set<String> extractKeywords(String text) {
    final normalized = _normalizeDiacritics(text.toLowerCase());
    final rawTokens = normalized.split(RegExp(r'[^a-z0-9]+'));
    return rawTokens
        .where((t) => t.length >= 3 && !_stopwords.contains(t))
        .toSet();
  }

  /// Retrieves top [maxChunks] most relevant chunks from [chunks] for the given [query].
  List<SourceReference> retrieveRelevantChunks({
    required String query,
    required List<PdfChunk> chunks,
    int maxChunks = 4,
    int maxTotalCharacters = 4000,
  }) {
    if (chunks.isEmpty) return const [];
    final queryTerms = extractKeywords(query);

    if (queryTerms.isEmpty) {
      // If query has no distinctive terms, return initial chunks up to budget
      return _takeWithinBudget(
        chunks.take(maxChunks).map(_toSourceReference).toList(),
        maxTotalCharacters,
      );
    }

    final scored = <({PdfChunk chunk, double score})>[];

    for (final chunk in chunks) {
      final chunkTerms = extractKeywords(chunk.text);
      if (chunkTerms.isEmpty) continue;

      var matches = 0.0;
      for (final term in queryTerms) {
        if (chunkTerms.contains(term)) {
          matches += 1.0;
        } else {
          // Substring partial match bonus
          for (final ct in chunkTerms) {
            if (ct.contains(term) || term.contains(ct)) {
              matches += 0.4;
              break;
            }
          }
        }
      }

      if (matches > 0) {
        final score = matches / sqrt(chunkTerms.length.toDouble());
        scored.add((chunk: chunk, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    final selected =
        scored.take(maxChunks).map((s) => _toSourceReference(s.chunk)).toList();
    return _takeWithinBudget(selected, maxTotalCharacters);
  }

  static SourceReference _toSourceReference(PdfChunk chunk) {
    return SourceReference(
      documentId: chunk.documentId,
      pageNumber: chunk.startPage,
      chunkId: chunk.chunkId,
      excerpt: chunk.text.trim(),
    );
  }

  static List<SourceReference> _takeWithinBudget(
    List<SourceReference> refs,
    int maxTotalCharacters,
  ) {
    final result = <SourceReference>[];
    var totalChars = 0;
    for (final ref in refs) {
      if (totalChars + ref.excerpt.length > maxTotalCharacters &&
          result.isNotEmpty) {
        break;
      }
      result.add(ref);
      totalChars += ref.excerpt.length;
    }
    return List.unmodifiable(result);
  }
}
