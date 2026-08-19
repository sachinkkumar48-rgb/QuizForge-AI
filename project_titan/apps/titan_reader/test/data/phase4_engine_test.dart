import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/grammar_engine.dart';
import 'package:titan_reader/src/data/local_rule_engine.dart';
import 'package:titan_reader/src/data/spell_checker.dart';
import 'package:titan_reader/src/domain/entities/grammar_issue.dart';
import 'package:titan_reader/src/domain/grammar_text_correction.dart';

/// Small scripted [HeadwordIndex] standing in for the bundled WordNet
/// headword list.
class FakeHeadwordIndex implements HeadwordIndex {
  FakeHeadwordIndex(this.words);

  final Set<String> words;
  int loadCount = 0;

  @override
  Future<Set<String>> loadWords() async {
    loadCount++;
    return words;
  }
}

/// Applies the first suggestion of every issue, engine-style.
String applyAll(String text, List<GrammarIssue> issues) {
  final replacements = <(int, int), String>{
    for (final issue in issues)
      if (issue.suggestions.isNotEmpty)
        (issue.startOffset, issue.endOffset):
            issue.suggestions.first.replacement,
  };
  return GrammarTextCorrection.apply(text, replacements);
}

void main() {
  const checker = RuleGrammarChecker();

  GrammarIssue only(String text, {String? ruleId}) {
    final issues = checker.check(text);
    final filtered =
        ruleId == null ? issues : issues.where((i) => i.ruleId == ruleId);
    expect(filtered, isNotEmpty, reason: 'expected $ruleId issue in "$text"');
    return filtered.first;
  }

  group('RuleGrammarChecker', () {
    test('correct text produces no issues', () {
      expect(
        checker.check('The committee reached a unanimous decision.'),
        isEmpty,
      );
    });

    test('empty and whitespace-only input produce no issues', () {
      expect(checker.check(''), isEmpty);
      expect(checker.check('   \t\n '), isEmpty);
    });

    test('flags repeated words and the fix removes the duplicate', () {
      const text = 'This is the the end.';
      final flagged = only(text, ruleId: 'rule.repeated-word');
      expect(flagged.type, GrammarIssueType.typographical);
      expect(flagged.severity, GrammarIssueSeverity.error);
      expect(flagged.originalText, ' the');
      expect(applyAll(text, [flagged]), 'This is the end.');
    });

    test('flags lowercase sentence starts and capitalizes them', () {
      const text = 'Hello world. this is wrong.';
      final flagged = only(text, ruleId: 'rule.sentence-capitalization');
      expect(flagged.type, GrammarIssueType.style);
      expect(flagged.originalText, 't');
      expect(applyAll(text, [flagged]), 'Hello world. This is wrong.');
    });

    test('flags the standalone pronoun i', () {
      const text = 'i think so.';
      final flagged = only(text, ruleId: 'rule.standalone-i');
      expect(flagged.severity, GrammarIssueSeverity.error);
      expect(applyAll(text, [flagged]), 'I think so.');
    });

    test('does not flag i inside words', () {
      expect(
        checker
            .check('It is inside and item.')
            .where((i) => i.ruleId == 'rule.standalone-i'),
        isEmpty,
      );
    });

    test('collapses double spaces', () {
      const text = 'two  spaces';
      final flagged = only(text, ruleId: 'rule.double-space');
      expect(applyAll(text, [flagged]), 'two spaces');
    });

    test('collapses doubled punctuation', () {
      const text = 'Wait,, what!!';
      final issues = checker
          .check(text)
          .where((i) => i.ruleId == 'rule.doubled-punctuation')
          .toList();
      expect(issues, hasLength(2));
      expect(applyAll(text, issues), 'Wait, what!');
    });

    test('adds the missing space after commas', () {
      const text = 'one,two';
      final flagged = only(text, ruleId: 'rule.punctuation-space-after');
      expect(flagged.type, GrammarIssueType.punctuation);
      expect(applyAll(text, [flagged]), 'one, two');
    });

    test('removes the space before punctuation', () {
      const text = 'word , next';
      final flagged = only(text, ruleId: 'rule.punctuation-space-before');
      expect(applyAll(text, [flagged]), 'word, next');
    });

    test('corrects modal + of to modal + have', () {
      const text = 'I should of gone.';
      final flagged = only(text, ruleId: 'rule.modal-of');
      expect(flagged.type, GrammarIssueType.grammar);
      expect(applyAll(text, [flagged]), 'I should have gone.');
    });

    test('splits alot into two words', () {
      const text = 'There is alot of work.';
      final flagged = only(text, ruleId: 'rule.alot');
      expect(flagged.type, GrammarIssueType.spelling);
      expect(applyAll(text, [flagged]), 'There is a lot of work.');
    });

    test('corrects article agreement', () {
      expect(
          applyAll(
              'a apple', [only('a apple', ruleId: 'rule.article-agreement')]),
          'an apple');
      expect(
          applyAll(
              'an car', [only('an car', ruleId: 'rule.article-agreement')]),
          'a car');
    });

    test('respects sound-based article exceptions', () {
      // "u" pronounced "you", silent "h", and acronyms are never guessed.
      expect(
        checker.check('a university, an hour and a NASA program.'),
        isEmpty,
      );
    });

    test('handles multiline text and orders issues by offset', () {
      const text = 'i agree.\n\nthe the plan needs  work.';
      final issues = checker.check(text);
      expect(issues.length, greaterThanOrEqualTo(3));
      final starts = issues.map((i) => i.startOffset).toList();
      expect(starts, orderedEquals(List.of(starts)..sort()));
      for (final flagged in issues) {
        // Every reported span must match the checked text exactly.
        expect(flagged.spanIn(text), flagged.originalText);
      }
    });

    test('quoted sentence starts are still checked', () {
      const text = 'He said. "this is quoted."';
      final flagged = only(text, ruleId: 'rule.sentence-capitalization');
      expect(flagged.originalText, 't');
      expect(applyAll(text, [flagged]), 'He said. "This is quoted."');
    });

    test('contractions are not mangled by the rules', () {
      expect(checker.check("I don't know; it's fine."), isEmpty);
    });

    test('unicode text does not crash and offsets stay valid', () {
      const text = 'Résumé: the the naïve café.';
      final issues = checker.check(text);
      expect(issues, isNotEmpty);
      for (final flagged in issues) {
        expect(flagged.startOffset, greaterThanOrEqualTo(0));
        expect(flagged.endOffset, lessThanOrEqualTo(text.length));
        expect(flagged.spanIn(text), flagged.originalText);
      }
    });
  });

  group('WordNetSpellChecker', () {
    WordNetSpellChecker checkerWith(Set<String> words) =>
        WordNetSpellChecker(index: FakeHeadwordIndex(words));

    test('known words produce no issues', () async {
      final issues =
          await checkerWith({'the', 'cat', 'sat'}).check('The cat sat.');
      expect(issues, isEmpty);
    });

    test('empty input produces no issues', () async {
      expect(await checkerWith({'a'}).check(''), isEmpty);
      expect(await checkerWith({'a'}).check('   '), isEmpty);
    });

    test('unknown words become spelling issues with distance-1 candidates',
        () async {
      final issues = await checkerWith({'receive', 'the', 'letter'})
          .check('recieve the letter');
      expect(issues, hasLength(1));
      final flagged = issues.single;
      expect(flagged.ruleId, WordNetSpellChecker.ruleId);
      expect(flagged.type, GrammarIssueType.spelling);
      expect(flagged.originalText, 'recieve');
      expect(
        flagged.suggestions.map((s) => s.replacement),
        contains('receive'),
      );
    });

    test('suggestions are capped and never invent confidence', () async {
      final words = {'cat', 'bat', 'hat', 'mat', 'rat', 'sat', 'pat', 'oat'};
      final issues = await checkerWith(words).check('fat');
      final flagged = issues.single;
      expect(flagged.suggestions.length, lessThanOrEqualTo(5));
      expect(flagged.suggestions.map((s) => s.replacement), contains('cat'));
    });

    test('accepts contractions of known words', () async {
      final issues = await checkerWith({'don', 'do', 'it', 'i', 'sure'})
          .check("don't do it, i'm sure");
      expect(issues, isEmpty);
    });

    test('rejects contractions of unknown bases', () async {
      final issues = await checkerWith({'do'}).check("zxq't happen");
      expect(issues.map((i) => i.originalText), contains("zxq't"));
    });

    test('skips ALL-CAPS acronyms', () async {
      final issues =
          await checkerWith({'the', 'report'}).check('The UNESCO report.');
      expect(issues, isEmpty);
    });

    test('skips capitalized proper nouns mid-sentence', () async {
      final issues =
          await checkerWith({'the', 'tower'}).check('the Eiffel tower');
      expect(issues, isEmpty);
    });

    test('single letters a and i are valid, others are not', () async {
      final issues = await checkerWith({'b'}).check('a b i x');
      expect(issues.map((i) => i.originalText), ['x']);
    });

    test('issue offsets map exactly onto the checked text', () async {
      const text = 'get the repport now';
      final issues =
          await checkerWith({'get', 'the', 'report', 'now'}).check(text);
      final flagged = issues.single;
      expect(text.substring(flagged.startOffset, flagged.endOffset), 'repport');
    });

    test('the production headword index loads its source only once', () async {
      var loads = 0;
      final index = DictionaryHeadwordIndex(() async {
        loads++;
        return ['a'];
      });
      final subject = WordNetSpellChecker(index: index);
      await subject.check('a');
      await subject.check('a');
      expect(loads, 1);
    });
  });

  group('LocalGrammarEngine', () {
    test('identifies itself for the cache key', () {
      final engine = LocalGrammarEngine(
          spellChecker: WordNetSpellChecker(
        index: FakeHeadwordIndex(const {}),
      ));
      expect(engine.engineId, 'local.titan.grammar');
      expect(engine.engineVersion, isNotEmpty);
    });

    test('empty input short-circuits', () async {
      final index = FakeHeadwordIndex(const {});
      final engine =
          LocalGrammarEngine(spellChecker: WordNetSpellChecker(index: index));
      expect(await engine.check('   '), isEmpty);
      expect(index.loadCount, 0);
    });

    test('merges rule and spelling issues ordered by offset', () async {
      final engine = LocalGrammarEngine(
        spellChecker: WordNetSpellChecker(
          index: FakeHeadwordIndex({'the', 'report', 'received'}),
        ),
      );
      const text = 'i recieved the the report';
      final issues = await engine.check(text);
      final ruleIds = issues.map((i) => i.ruleId).toList();
      expect(
        ruleIds,
        containsAll([
          'rule.standalone-i',
          WordNetSpellChecker.ruleId,
          'rule.repeated-word',
        ]),
      );
      final starts = issues.map((i) => i.startOffset).toList();
      expect(starts, orderedEquals(List.of(starts)..sort()));
    });

    test('suppresses spelling issues inside rule-flagged spans', () async {
      // "alot" is both a rule match and an unknown word; it must be
      // reported exactly once.
      final engine = LocalGrammarEngine(
        spellChecker: WordNetSpellChecker(
          index: FakeHeadwordIndex({'there', 'is', 'of', 'work'}),
        ),
      );
      final issues = await engine.check('There is alot of work.');
      expect(issues, hasLength(1));
      expect(issues.single.ruleId, 'rule.alot');
    });

    test('multi-paragraph selections keep offsets intact', () async {
      final engine = LocalGrammarEngine(
        spellChecker: WordNetSpellChecker(
          index: FakeHeadwordIndex({'first', 'paragraph', 'second'}),
        ),
      );
      const text = 'first paragraph.\n\nsecond paragraph the the end.';
      final issues = await engine.check(text);
      final repeated =
          issues.where((i) => i.ruleId == 'rule.repeated-word').single;
      expect(repeated.spanIn(text), ' the');
      // The flagged span starts right after the first duplicated word.
      expect(repeated.startOffset, text.indexOf('the the') + 3);
    });
  });
}
