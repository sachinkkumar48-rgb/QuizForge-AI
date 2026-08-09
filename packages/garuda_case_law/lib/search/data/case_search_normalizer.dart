/// Deterministic search normalization (TITAN-KO-015.0 P6).
///
/// All normalization is pure string transformation — lowercase, whitespace
/// collapsing, punctuation removal and constitutional-article variant folding.
/// There is no stemming, no opaque ML normalization and no loss of the
/// information needed to render match context.
///
/// Article variants fold onto one canonical form:
/// `Article 21`, `Art. 21`, `art 21`, `article21` → text `article 21`,
/// article key `21`.
library;

/// Pure, deterministic string normalization for the case-law search engine.
class CaseSearchNormalizer {
  const CaseSearchNormalizer._();

  /// Canonical text normalization used for indexing and matching.
  ///
  /// 1. lowercase + trim
  /// 2. fold article prefixes (`Art. 21` / `art 21` / `article21` → `article 21`)
  /// 3. punctuation → single space
  /// 4. collapse repeated whitespace
  static String normalizeText(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'\bart\.\s*'), 'article ');
    s = s.replaceAll(RegExp(r'\bart\s+'), 'article ');
    s = s.replaceAll(RegExp(r'\bart(?=\d)'), 'article ');
    s = s.replaceAll(RegExp(r'^article(?=\d)'), 'article ');
    s = s.replaceAll(RegExp(r'^art(?=\d)'), 'article ');
    s = s.replaceAll(RegExp(r'[^\w\s]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Normalizes a constitutional-article reference to a comparable key:
  /// `Article 21` / `Art. 21` / `art 21` / `article21` / `21` → `21`,
  /// `Article 19(1)(a)` → `191a`, `Article 323A` → `323a`.
  static String normalizeArticle(String input) {
    var s = input.trim().toLowerCase();
    // Fold leading article references (`Article 21`, `Art. 21`, `art 21`,
    // `article21`, `art21`). No trailing `\b` here: "Art." is followed by a
    // non-word char and whitespace, so a word boundary would never hold.
    s = s.replaceFirst(RegExp(r'^(article|art\.?)\s*'), '');
    s = s.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return s;
  }

  /// Word tokens of the normalized text (empty tokens removed).
  static List<String> tokenize(String input) =>
      normalizeText(input).split(' ').where((t) => t.isNotEmpty).toList();

  /// Whether [normalizeText(a)] starts with [normalizeText(b)] (used by
  /// prefix search and autocomplete).
  static bool isPrefixOf(String query, String value) {
    final q = normalizeText(query);
    final v = normalizeText(value);
    return q.isNotEmpty && v.startsWith(q);
  }

  /// Deterministic match weight for one term against one value:
  /// exact 1.0 > whole-value prefix 0.7 > token prefix 0.6 >
  /// substring 0.4 > token substring 0.35 > no match 0.0.
  static double matchWeight(String term, String value) {
    final t = normalizeText(term);
    final v = normalizeText(value);
    if (t.isEmpty) return 0.0;
    if (v == t) return 1.0;
    if (v.startsWith(t)) return 0.7;
    final vTokens = tokenize(v);
    for (final tok in vTokens) {
      if (tok.startsWith(t)) return 0.6;
    }
    if (v.contains(t)) return 0.4;
    for (final tok in vTokens) {
      if (tok.contains(t)) return 0.35;
    }
    return 0.0;
  }
}
