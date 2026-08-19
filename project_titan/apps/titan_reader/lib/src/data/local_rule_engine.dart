import '../domain/entities/grammar_issue.dart';

/// Deterministic, offline grammar/punctuation/typography rules.
///
/// Every rule is exact and explainable: no heuristics are reported as
/// certainty and no classification exists that a rule does not produce.
/// Rules cover the recurring mechanical error classes; deep grammar
/// remains out of scope for the local engine (§42: no AI).
class RuleGrammarChecker {
  const RuleGrammarChecker();

  static final RegExp _repeatedWord =
      RegExp(r'\b([A-Za-z]+)[ \t]+\1\b', caseSensitive: false);
  static final RegExp _standaloneI = RegExp(r"(?<![A-Za-z'])i(?![A-Za-z'])");
  static final RegExp _doubleSpace = RegExp(r'(?<=\S) {2,}(?=\S)');
  static final RegExp _doubledPunctuation = RegExp(r'([,;:]){2,}|([!?]){2,}');
  static final RegExp _missingSpaceAfterPunctuation =
      RegExp(r'[,;:](?=[A-Za-z0-9])');
  static final RegExp _spaceBeforePunctuation = RegExp(r'[ \t]+(?=[,;:])');
  static final RegExp _modalOf = RegExp(
      r'\b(would|could|should|must|might)[ \t]+of\b',
      caseSensitive: false);
  static final RegExp _alot = RegExp(r'\b[Aa]lot\b');
  static final RegExp _articleNoun =
      RegExp(r'\b(a|an)[ \t]+([A-Za-z][A-Za-z-]+)', caseSensitive: false);
  static final RegExp _sentenceEnd = RegExp(r'[.!?][ \t\r\n]+');

  /// Words whose initial vowel letters still take the article "a".
  static const List<String> _consonantSoundVowels = [
    'uni',
    'unan',
    'use',
    'user',
    'usu',
    'one',
    'once',
    'eu',
    'ewe',
    'uke'
  ];

  /// Words whose initial silent "h" takes the article "an".
  static const List<String> _vowelSoundConsonants = [
    'hour',
    'honest',
    'honor',
    'honour',
    'heir'
  ];

  /// Runs every rule over [text] and returns issues ordered by offset.
  List<GrammarIssue> check(String text) {
    if (text.trim().isEmpty) return const [];
    final issues = <GrammarIssue>[
      ..._repeatedWords(text),
      ..._sentenceCapitalization(text),
      ..._standaloneIs(text),
      ..._doubleSpaces(text),
      ..._doubledPunctuations(text),
      ..._punctuationSpacing(text),
      ..._modalOfs(text),
      ..._alots(text),
      ..._articleAgreements(text),
    ];
    issues.sort((a, b) {
      final byStart = a.startOffset.compareTo(b.startOffset);
      if (byStart != 0) return byStart;
      return a.endOffset.compareTo(b.endOffset);
    });
    return issues;
  }

  List<GrammarIssue> _repeatedWords(String text) {
    final issues = <GrammarIssue>[];
    for (final match in _repeatedWord.allMatches(text)) {
      final word = match.group(1)!;
      // Span covers the separator plus the duplicate; applying the empty
      // replacement leaves a single occurrence.
      final start = match.start + word.length;
      issues.add(GrammarIssue(
        ruleId: 'rule.repeated-word',
        type: GrammarIssueType.typographical,
        severity: GrammarIssueSeverity.error,
        message: 'Repeated word "$word".',
        explanation: 'The word "$word" appears twice in a row.',
        startOffset: start,
        endOffset: match.end,
        originalText: text.substring(start, match.end),
        suggestions: const [GrammarSuggestion(replacement: '')],
        source: GrammarIssueSource.local,
      ));
    }
    return issues;
  }

  List<GrammarIssue> _sentenceCapitalization(String text) {
    final issues = <GrammarIssue>[];
    final boundaries = <int>[0];
    for (final match in _sentenceEnd.allMatches(text)) {
      boundaries.add(match.end);
    }
    for (final boundary in boundaries) {
      var index = boundary;
      while (
          index < text.length && (' \t\r\n"\'“”‘’(['.contains(text[index]))) {
        index++;
      }
      if (index >= text.length) continue;
      final char = text[index];
      final isLowerAlpha =
          char.codeUnitAt(0) >= 0x61 && char.codeUnitAt(0) <= 0x7A;
      if (!isLowerAlpha) continue;
      // Find the word the character starts; skip the standalone pronoun
      // "i" (handled by rule.standalone-i with the same correction).
      var end = index + 1;
      while (end < text.length && _isWordChar(text[end])) {
        end++;
      }
      final word = text.substring(index, end);
      if (word == 'i') continue;
      if (word.length < 2) continue;
      issues.add(GrammarIssue(
        ruleId: 'rule.sentence-capitalization',
        type: GrammarIssueType.style,
        severity: GrammarIssueSeverity.warning,
        message: 'Sentence should start with a capital letter.',
        explanation: 'The first word of a sentence is capitalized in English.',
        startOffset: index,
        endOffset: index + 1,
        originalText: char,
        suggestions: [
          GrammarSuggestion(replacement: char.toUpperCase()),
        ],
        source: GrammarIssueSource.local,
      ));
    }
    return issues;
  }

  List<GrammarIssue> _standaloneIs(String text) {
    return _standaloneI.allMatches(text).map((match) {
      return GrammarIssue(
        ruleId: 'rule.standalone-i',
        type: GrammarIssueType.style,
        severity: GrammarIssueSeverity.error,
        message: 'The pronoun "I" is always capitalized.',
        explanation: 'The first-person singular pronoun is written "I".',
        startOffset: match.start,
        endOffset: match.end,
        originalText: 'i',
        suggestions: const [GrammarSuggestion(replacement: 'I')],
        source: GrammarIssueSource.local,
      );
    }).toList();
  }

  List<GrammarIssue> _doubleSpaces(String text) {
    return _doubleSpace.allMatches(text).map((match) {
      return GrammarIssue(
        ruleId: 'rule.double-space',
        type: GrammarIssueType.typographical,
        severity: GrammarIssueSeverity.warning,
        message: 'Multiple consecutive spaces.',
        explanation: 'Words are separated by a single space.',
        startOffset: match.start,
        endOffset: match.end,
        originalText: match.group(0)!,
        suggestions: const [GrammarSuggestion(replacement: ' ')],
        source: GrammarIssueSource.local,
      );
    }).toList();
  }

  List<GrammarIssue> _doubledPunctuations(String text) {
    final issues = <GrammarIssue>[];
    for (final match in _doubledPunctuation.allMatches(text)) {
      final run = match.group(0)!;
      issues.add(GrammarIssue(
        ruleId: 'rule.doubled-punctuation',
        type: GrammarIssueType.typographical,
        severity: GrammarIssueSeverity.warning,
        message: 'Duplicated punctuation "${run[0]}".',
        explanation: 'The punctuation mark "${run[0]}" is repeated.',
        startOffset: match.start,
        endOffset: match.end,
        originalText: run,
        suggestions: [GrammarSuggestion(replacement: run[0])],
        source: GrammarIssueSource.local,
      ));
    }
    return issues;
  }

  List<GrammarIssue> _punctuationSpacing(String text) {
    final issues = <GrammarIssue>[];
    for (final match in _missingSpaceAfterPunctuation.allMatches(text)) {
      final mark = match.group(0)!;
      issues.add(GrammarIssue(
        ruleId: 'rule.punctuation-space-after',
        type: GrammarIssueType.punctuation,
        severity: GrammarIssueSeverity.warning,
        message: 'Missing space after "$mark".',
        explanation: 'A space follows commas, semicolons and colons.',
        startOffset: match.start,
        endOffset: match.end,
        originalText: mark,
        suggestions: [GrammarSuggestion(replacement: '$mark ')],
        source: GrammarIssueSource.local,
      ));
    }
    for (final match in _spaceBeforePunctuation.allMatches(text)) {
      issues.add(GrammarIssue(
        ruleId: 'rule.punctuation-space-before',
        type: GrammarIssueType.punctuation,
        severity: GrammarIssueSeverity.warning,
        message: 'Space before punctuation.',
        explanation:
            'Commas, semicolons and colons attach to the preceding word.',
        startOffset: match.start,
        endOffset: match.end,
        originalText: match.group(0)!,
        suggestions: const [GrammarSuggestion(replacement: '')],
        source: GrammarIssueSource.local,
      ));
    }
    return issues;
  }

  List<GrammarIssue> _modalOfs(String text) {
    final issues = <GrammarIssue>[];
    for (final match in _modalOf.allMatches(text)) {
      final modal = match.group(1)!;
      final have = _startsWithCapital(modal) ? 'Have' : 'have';
      issues.add(GrammarIssue(
        ruleId: 'rule.modal-of',
        type: GrammarIssueType.grammar,
        severity: GrammarIssueSeverity.error,
        message: '"$modal of" is not a verb phrase.',
        explanation: 'After a modal verb use "have"; "$modal of" is a '
            'mishearing of the contraction "$modal\'ve".',
        startOffset: match.start,
        endOffset: match.end,
        originalText: match.group(0)!,
        suggestions: [GrammarSuggestion(replacement: '$modal $have')],
        source: GrammarIssueSource.local,
      ));
    }
    return issues;
  }

  List<GrammarIssue> _alots(String text) {
    return _alot.allMatches(text).map((match) {
      final token = match.group(0)!;
      return GrammarIssue(
        ruleId: 'rule.alot',
        type: GrammarIssueType.spelling,
        severity: GrammarIssueSeverity.error,
        message: '"$token" should be two words.',
        explanation: '"A lot" is always written as two separate words.',
        startOffset: match.start,
        endOffset: match.end,
        originalText: token,
        suggestions: [
          GrammarSuggestion(
              replacement: token.startsWith('A') ? 'A lot' : 'a lot'),
        ],
        source: GrammarIssueSource.local,
      );
    }).toList();
  }

  List<GrammarIssue> _articleAgreements(String text) {
    final issues = <GrammarIssue>[];
    for (final match in _articleNoun.allMatches(text)) {
      final article = match.group(1)!;
      final noun = match.group(2)!;
      // Acronym pronunciation is unknown; never guess.
      if (noun == noun.toUpperCase()) continue;
      final vowelSound = _startsWithVowelSound(noun);
      final articleIsVowelForm = article.toLowerCase() == 'an';
      if (vowelSound == articleIsVowelForm) continue;
      final expected = vowelSound
          ? (article.startsWith('A') ? 'An' : 'an')
          : (article.startsWith('A') ? 'A' : 'a');
      issues.add(GrammarIssue(
        ruleId: 'rule.article-agreement',
        type: GrammarIssueType.grammar,
        severity: GrammarIssueSeverity.warning,
        message: 'Use "$expected" before "$noun".',
        explanation: 'The indefinite article agrees with the sound that '
            'starts the following word.',
        startOffset: match.start,
        endOffset: match.start + article.length,
        originalText: article,
        suggestions: [GrammarSuggestion(replacement: expected)],
        source: GrammarIssueSource.local,
      ));
    }
    return issues;
  }

  static bool _startsWithVowelSound(String word) {
    final lower = word.toLowerCase();
    for (final prefix in _consonantSoundVowels) {
      if (lower.startsWith(prefix)) return false;
    }
    for (final prefix in _vowelSoundConsonants) {
      if (lower.startsWith(prefix)) return true;
    }
    return 'aeiou'.contains(lower[0]);
  }

  static bool _startsWithCapital(String word) =>
      word.isNotEmpty &&
      word[0].codeUnitAt(0) >= 0x41 &&
      word[0].codeUnitAt(0) <= 0x5A;

  static bool _isWordChar(String char) {
    final unit = char.codeUnitAt(0);
    return (unit >= 0x41 && unit <= 0x5A) ||
        (unit >= 0x61 && unit <= 0x7A) ||
        char == "'";
  }
}
