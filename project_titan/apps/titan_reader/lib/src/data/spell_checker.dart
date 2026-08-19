import '../domain/entities/grammar_issue.dart';

/// Contract over a set of known words used for offline spell checking.
///
/// The Reader reuses the Phase 3 bundled WordNet headword index through
/// [DictionaryHeadwordIndex] so no second word list ships with the app.
abstract class HeadwordIndex {
  /// All known words, lowercase. Loaded lazily and cached by callers.
  Future<Set<String>> loadWords();
}

/// [HeadwordIndex] backed by the bundled dictionary's headword list.
class DictionaryHeadwordIndex implements HeadwordIndex {
  DictionaryHeadwordIndex(this._loadHeadwords);

  final Future<List<String>> Function() _loadHeadwords;

  Set<String>? _words;

  @override
  Future<Set<String>> loadWords() async {
    final cached = _words;
    if (cached != null) return cached;
    final headwords = await _loadHeadwords();
    final words = headwords.map((w) => w.toLowerCase()).toSet();
    _words = words;
    return words;
  }
}

/// Deterministic offline spell checker over a [HeadwordIndex].
///
/// Words missing from the index become [GrammarIssueType.spelling] issues
/// with replacement candidates generated at Damerau-Levenshtein distance 1
/// (deletes, transposes, replaces, inserts) and, only when distance 1 finds
/// nothing, distance 2. Candidates are ordered by distance then
/// alphabetically and capped; no frequency or confidence values are
/// invented because the bundled dataset provides none.
class WordNetSpellChecker {
  WordNetSpellChecker({required HeadwordIndex index, this.maxSuggestions = 5})
      : _index = index;

  /// Rule identifier used on every issue this checker produces.
  static const String ruleId = 'spelling.unknown-word';

  /// Alphabetic tokens with optional inner apostrophe (contractions).
  static final RegExp _tokenPattern = RegExp(r"[A-Za-z]+(?:'[A-Za-z]+)*");

  /// Suffixes allowed after an apostrophe in contractions/possessives.
  static const Set<String> _contractionSuffixes = {
    't',
    's',
    're',
    've',
    'll',
    'd',
    'm'
  };

  /// Single letters that are valid English words on their own.
  static const Set<String> _validSingleLetters = {'a', 'i'};

  final HeadwordIndex _index;
  final int maxSuggestions;

  static const String _alphabet = 'abcdefghijklmnopqrstuvwxyz';

  /// Checks [text] and returns spelling issues ordered by offset.
  Future<List<GrammarIssue>> check(String text) async {
    if (text.trim().isEmpty) return const [];
    final words = await _index.loadWords();
    final issues = <GrammarIssue>[];
    for (final match in _tokenPattern.allMatches(text)) {
      final token = match.group(0)!;
      final lower = token.toLowerCase();
      if (_isKnown(lower, words)) continue;
      if (_skipToken(token, match.start, text)) continue;
      final suggestions = _candidates(lower, words)
          .map((candidate) => GrammarSuggestion(replacement: candidate))
          .toList();
      issues.add(GrammarIssue(
        ruleId: ruleId,
        type: GrammarIssueType.spelling,
        severity: GrammarIssueSeverity.error,
        message: 'Possible spelling mistake.',
        explanation: '"$token" was not found in the bundled WordNet '
            'dictionary.',
        startOffset: match.start,
        endOffset: match.end,
        originalText: token,
        suggestions: List.unmodifiable(suggestions),
        source: GrammarIssueSource.local,
      ));
    }
    return issues;
  }

  /// Whether [lower] is a known word, contraction of known parts or a
  /// valid single letter.
  bool _isKnown(String lower, Set<String> words) {
    if (words.contains(lower)) return true;
    if (lower.length == 1) return _validSingleLetters.contains(lower);
    if (lower.contains("'")) {
      final parts = lower.split("'");
      if (parts.isEmpty || parts.first.isEmpty) return false;
      if (!words.contains(parts.first) && parts.first != 'i') return false;
      return parts.skip(1).every(_contractionSuffixes.contains);
    }
    return false;
  }

  /// Tokens that are deliberately not spell-checked:
  /// * ALL-CAPS tokens (acronyms);
  /// * capitalized tokens in the middle of a sentence (likely proper
  ///   nouns — the checker cannot know them and refuses to guess).
  bool _skipToken(String token, int start, String text) {
    if (token.length >= 2 && token == token.toUpperCase()) return true;
    if (start > 0 && _isSentenceStart(start, text)) return false;
    final first = token[0];
    if (first == first.toUpperCase() && first != first.toLowerCase()) {
      // Capitalized mid-sentence token: treat as a proper noun unless its
      // lowercase form is known (that case is handled by _isKnown above
      // and never reaches here).
      if (start > 0) return true;
    }
    return false;
  }

  static bool _isSentenceStart(int index, String text) {
    var i = index - 1;
    var sawWhitespace = false;
    while (i >= 0) {
      final char = text[i];
      if (char == '.' || char == '!' || char == '?') return true;
      if (char == ' ' || char == '\t' || char == '\n' || char == '\r') {
        sawWhitespace = true;
        i--;
        continue;
      }
      return false;
    }
    return sawWhitespace || index == 0;
  }

  /// Replacement candidates for [word] at edit distance 1, then 2.
  List<String> _candidates(String word, Set<String> words) {
    final distanceOne = _edits(word).where(words.contains).toSet()
      ..remove(word);
    if (distanceOne.isNotEmpty) {
      return _cap(_order(distanceOne));
    }
    final distanceTwo = <String>{};
    for (final intermediate in _edits(word)) {
      distanceTwo.addAll(_edits(intermediate).where(words.contains));
    }
    distanceTwo
      ..remove(word)
      ..removeAll(distanceOne);
    return _cap(_order(distanceTwo));
  }

  /// Damerau-Levenshtein distance-1 edits: deletes, transposes, replaces
  /// and inserts over the ASCII alphabet.
  Iterable<String> _edits(String word) sync* {
    for (var i = 0; i < word.length; i++) {
      yield word.substring(0, i) + word.substring(i + 1);
    }
    for (var i = 0; i < word.length - 1; i++) {
      yield word.substring(0, i) +
          word[i + 1] +
          word[i] +
          word.substring(i + 2);
    }
    for (var i = 0; i < word.length; i++) {
      for (final letter in _alphabet.split('')) {
        yield word.substring(0, i) + letter + word.substring(i + 1);
      }
    }
    for (var i = 0; i <= word.length; i++) {
      for (final letter in _alphabet.split('')) {
        yield word.substring(0, i) + letter + word.substring(i);
      }
    }
  }

  List<String> _order(Set<String> candidates) {
    final list = candidates.toList()..sort();
    return list;
  }

  List<String> _cap(List<String> ordered) => ordered.length <= maxSuggestions
      ? ordered
      : ordered.sublist(0, maxSuggestions);
}
