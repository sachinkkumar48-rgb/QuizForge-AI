import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/grammar_issue.dart';
import 'package:titan_reader/src/domain/grammar_text_correction.dart';

GrammarIssue issue({
  int start = 0,
  int end = 3,
  String ruleId = 'rule.test',
  GrammarIssueType type = GrammarIssueType.grammar,
  GrammarIssueSeverity severity = GrammarIssueSeverity.warning,
  List<GrammarSuggestion> suggestions = const [],
}) {
  return GrammarIssue(
    ruleId: ruleId,
    type: type,
    severity: severity,
    message: 'test message',
    startOffset: start,
    endOffset: end,
    originalText: 'abc',
    suggestions: suggestions,
  );
}

void main() {
  group('GrammarSuggestion', () {
    test('serialization round-trip preserves fields', () {
      const suggestion = GrammarSuggestion(replacement: 'goes', label: 'verb');
      final restored = GrammarSuggestion.fromJson(suggestion.toJson());
      expect(restored, suggestion);
      expect(restored.replacement, 'goes');
      expect(restored.label, 'verb');
    });

    test('fromJson requires a replacement', () {
      expect(
        () => GrammarSuggestion.fromJson(const <String, Object?>{'label': 'x'}),
        throwsFormatException,
      );
    });

    test('equality is value based', () {
      expect(
        const GrammarSuggestion(replacement: 'a'),
        const GrammarSuggestion(replacement: 'a'),
      );
      expect(
        const GrammarSuggestion(replacement: 'a') ==
            const GrammarSuggestion(replacement: 'b'),
        isFalse,
      );
    });
  });

  group('GrammarIssue ranges', () {
    test('rejects negative start offsets', () {
      expect(() => issue(start: -1), throwsA(isA<AssertionError>()));
    });

    test('rejects end before start', () {
      expect(() => issue(start: 5, end: 2), throwsA(isA<AssertionError>()));
    });

    test('allows empty spans', () {
      expect(issue(start: 4, end: 4).startOffset, 4);
    });

    test('spanIn extracts the flagged range from the checked text', () {
      final flagged = issue(start: 4, end: 7);
      expect(flagged.spanIn('one two three'), 'two');
    });

    test('spanIn falls back to originalText for out-of-range offsets', () {
      final flagged = issue(start: 100, end: 103);
      expect(flagged.spanIn('short'), 'abc');
    });
  });

  group('GrammarIssue serialization', () {
    test('round-trip preserves every field', () {
      const original = GrammarIssue(
        ruleId: 'rule.repeated-word',
        type: GrammarIssueType.typographical,
        severity: GrammarIssueSeverity.error,
        message: 'Repeated word.',
        explanation: 'Why it is wrong.',
        startOffset: 8,
        endOffset: 12,
        originalText: ' the',
        suggestions: [
          GrammarSuggestion(replacement: ''),
          GrammarSuggestion(replacement: 'a', label: 'alt'),
        ],
        source: GrammarIssueSource.remote,
      );
      final restored = GrammarIssue.fromJson(original.toJson());
      expect(restored.ruleId, original.ruleId);
      expect(restored.type, GrammarIssueType.typographical);
      expect(restored.severity, GrammarIssueSeverity.error);
      expect(restored.message, original.message);
      expect(restored.explanation, original.explanation);
      expect(restored.startOffset, 8);
      expect(restored.endOffset, 12);
      expect(restored.originalText, ' the');
      expect(restored.suggestions, original.suggestions);
      expect(restored.source, GrammarIssueSource.remote);
    });

    test('fromJson rejects missing required fields', () {
      expect(
        () => GrammarIssue.fromJson(const <String, Object?>{
          'ruleId': 'x',
        }),
        throwsFormatException,
      );
    });

    test('fromJson maps unknown enums defensively', () {
      final restored = GrammarIssue.fromJson(const <String, Object?>{
        'ruleId': 'x',
        'message': 'm',
        'originalText': 'o',
        'startOffset': 1,
        'endOffset': 2,
        'type': 'not-a-real-type',
        'severity': 'not-a-real-severity',
        'source': 'not-a-real-source',
      });
      expect(restored.type, GrammarIssueType.grammar);
      expect(restored.severity, GrammarIssueSeverity.warning);
      expect(restored.source, GrammarIssueSource.local);
    });

    test('fromJson clamps invalid offsets instead of crashing', () {
      final restored = GrammarIssue.fromJson(const <String, Object?>{
        'ruleId': 'x',
        'message': 'm',
        'originalText': 'o',
        'startOffset': -4,
        'endOffset': -2,
      });
      expect(restored.startOffset, 0);
      expect(restored.endOffset, 0);
    });

    test('no numeric confidence is ever fabricated', () {
      // The model intentionally has no confidence field; severity is a
      // closed enum supplied by the engine (§7).
      expect(issue().severity, isA<GrammarIssueSeverity>());
      expect(GrammarIssueSeverity.values, hasLength(3));
    });
  });

  group('GrammarCheckResult', () {
    test('fromJson reorders issues by start then end offset', () {
      final restored = GrammarCheckResult.fromJson(<String, Object?>{
        'text': 'sample',
        'language': 'en',
        'engineId': 'local.titan.grammar',
        'engineVersion': '1.0.0',
        'checkedAt': DateTime.utc(2026, 8, 19).toIso8601String(),
        'issues': [
          issue(start: 10, end: 12).toJson(),
          issue(start: 2, end: 9).toJson(),
          issue(start: 2, end: 4).toJson(),
        ],
      });
      expect(
        restored.issues.map((i) => (i.startOffset, i.endOffset)).toList(),
        [(2, 4), (2, 9), (10, 12)],
      );
    });

    test('round-trip preserves metadata', () {
      final original = GrammarCheckResult(
        text: 'some text',
        language: 'en',
        issues: [issue(start: 0, end: 4)],
        engineId: 'local.titan.grammar',
        engineVersion: '1.0.0',
        remoteSourceId: 'remote:languagetool.org',
        checkedAt: DateTime.utc(2026, 8, 19, 10, 30),
      );
      final restored = GrammarCheckResult.fromJson(original.toJson());
      expect(restored.text, 'some text');
      expect(restored.language, 'en');
      expect(restored.engineId, original.engineId);
      expect(restored.engineVersion, original.engineVersion);
      expect(restored.remoteSourceId, 'remote:languagetool.org');
      expect(restored.checkedAt, DateTime.utc(2026, 8, 19, 10, 30));
      expect(restored.issues, hasLength(1));
    });

    test('fromJson rejects missing required fields', () {
      expect(
        () => GrammarCheckResult.fromJson(const <String, Object?>{
          'text': 'x',
        }),
        throwsFormatException,
      );
    });
  });

  group('GrammarCorrection', () {
    test('round-trip preserves every field', () {
      final original = GrammarCorrection(
        id: 'grammar_1',
        documentId: 'doc-1',
        pageNumber: 5,
        originalText: 'the the end.',
        correctedText: 'the end.',
        appliedRuleIds: const ['rule.repeated-word'],
        createdAt: DateTime.utc(2026, 8, 19, 9),
      );
      final restored = GrammarCorrection.fromJson(original.toJson());
      expect(restored.id, 'grammar_1');
      expect(restored.documentId, 'doc-1');
      expect(restored.pageNumber, 5);
      expect(restored.originalText, original.originalText);
      expect(restored.correctedText, original.correctedText);
      expect(restored.appliedRuleIds, original.appliedRuleIds);
      expect(restored.createdAt, DateTime.utc(2026, 8, 19, 9));
    });

    test('fromJson rejects missing required fields', () {
      expect(
        () => GrammarCorrection.fromJson(const <String, Object?>{
          'id': 'x',
        }),
        throwsFormatException,
      );
    });

    test('fromJson tolerates absent optional metadata', () {
      final restored = GrammarCorrection.fromJson(<String, Object?>{
        'id': 'x',
        'originalText': 'a',
        'correctedText': 'b',
        'createdAt': DateTime.utc(2026).toIso8601String(),
      });
      expect(restored.documentId, isNull);
      expect(restored.pageNumber, isNull);
      expect(restored.appliedRuleIds, isEmpty);
    });
  });

  group('GrammarTextCorrection', () {
    test('returns the text unchanged without replacements', () {
      expect(GrammarTextCorrection.apply('abc', const {}), 'abc');
    });

    test('applies a single replacement', () {
      final corrected = GrammarTextCorrection.apply(
        'He go to school.',
        {(3, 5): 'goes'},
      );
      expect(corrected, 'He goes to school.');
    });

    test('applies multiple replacements regardless of insertion order', () {
      final corrected = GrammarTextCorrection.apply(
        'a apple and a orange',
        {
          (12, 13): 'an',
          (0, 1): 'an',
        },
      );
      expect(corrected, 'an apple and an orange');
    });

    test('skips spans that overlap an earlier accepted span', () {
      final corrected = GrammarTextCorrection.apply(
        'abcdef',
        {
          (0, 3): 'X',
          (2, 5): 'Y',
        },
      );
      // The earlier span wins; the overlapping one is dropped intact.
      expect(corrected, 'Xdef');
    });

    test('skips out-of-bounds spans deterministically', () {
      final corrected = GrammarTextCorrection.apply(
        'abcdef',
        {
          (-1, 2): 'X',
          (4, 99): 'Y',
          (0, 1): 'Z',
        },
      );
      expect(corrected, 'Zbcdef');
    });

    test('supports empty replacements that delete spans', () {
      final corrected = GrammarTextCorrection.apply(
        'the the end',
        {(3, 7): ''},
      );
      expect(corrected, 'the end');
    });
  });
}
