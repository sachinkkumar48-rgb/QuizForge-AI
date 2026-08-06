import 'package:meta/meta.dart';

/// Text normalizer for standardizing search terms, article numbers, and titles.
@immutable
class KnowledgeNormalizer {
  /// Normalizes generic text for search index hashing and comparison.
  String normalize(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\d\s\-_]'), '');
  }

  /// Normalizes Indian Constitution article designations (e.g. "Art. 21", "article 21A" -> "21a").
  String normalizeArticleNumber(String articleInput) {
    var cleaned = articleInput.trim().toLowerCase();
    cleaned = cleaned.replaceAll(RegExp(r'^(article|art\.?|art)\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');
    return cleaned;
  }

  /// Normalizes Case names by removing common legal suffixes/prefixes (e.g., "v.", "vs", "state of").
  String normalizeCaseName(String caseInput) {
    var cleaned = caseInput.trim().toLowerCase();
    cleaned = cleaned.replaceAll(RegExp(r'\b(v\.|vs\.?|versus)\b'), ' v ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ');
  }
}
