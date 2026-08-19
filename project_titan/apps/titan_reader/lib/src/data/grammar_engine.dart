import '../domain/entities/grammar_issue.dart';
import 'local_rule_engine.dart';
import 'spell_checker.dart';

/// Engine-agnostic contract for grammar/spelling analysis.
///
/// The UI and the service layer depend only on this contract; concrete
/// engines (the deterministic local engine, an optional remote engine)
/// live behind it so no engine type ever leaks into the domain.
abstract class GrammarEngine {
  /// Stable engine identifier, part of the grammar cache key.
  String get engineId;

  /// Engine version, part of the grammar cache key so an engine update
  /// never serves stale cached results.
  String get engineVersion;

  /// Analyzes [text] and returns the issues found, ordered by offset.
  ///
  /// Offsets are character offsets into [text]. [language] is reserved for
  /// future languages; Phase 4 supports `en` only.
  Future<List<GrammarIssue>> check(String text, {String language = 'en'});
}

/// The deterministic local engine: rule-based grammar/punctuation/
/// typography checks plus WordNet-backed spelling.
///
/// Fully offline, identical on Android and Windows, no JVM and no native
/// bridge. Spelling issues that fall inside a span already flagged by a
/// rule (e.g. "alot") are suppressed so an error is reported once.
class LocalGrammarEngine implements GrammarEngine {
  LocalGrammarEngine({
    required WordNetSpellChecker spellChecker,
    RuleGrammarChecker? ruleChecker,
  })  : _spellChecker = spellChecker,
        _ruleChecker = ruleChecker ?? const RuleGrammarChecker();

  @override
  String get engineId => 'local.titan.grammar';

  @override
  String get engineVersion => '1.0.0';

  final WordNetSpellChecker _spellChecker;
  final RuleGrammarChecker _ruleChecker;

  @override
  Future<List<GrammarIssue>> check(String text,
      {String language = 'en'}) async {
    if (text.trim().isEmpty) return const [];
    final ruleIssues = _ruleChecker.check(text);
    final spellingIssues = await _spellChecker.check(text);
    final merged = <GrammarIssue>[
      ...ruleIssues,
      ...spellingIssues.where((issue) => !_coveredByRule(issue, ruleIssues)),
    ];
    merged.sort((a, b) {
      final byStart = a.startOffset.compareTo(b.startOffset);
      if (byStart != 0) return byStart;
      return a.endOffset.compareTo(b.endOffset);
    });
    return List.unmodifiable(merged);
  }

  /// Whether [issue]'s span sits inside a rule-flagged span.
  static bool _coveredByRule(
      GrammarIssue issue, List<GrammarIssue> ruleIssues) {
    return ruleIssues.any((rule) =>
        issue.startOffset >= rule.startOffset &&
        issue.endOffset <= rule.endOffset);
  }
}
