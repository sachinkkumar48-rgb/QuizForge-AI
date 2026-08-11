import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P15 — determinism & offline-first tests (TITAN-KO-015.0 P15).
///
/// P15 must be fully deterministic (the same source and repository state
/// produce byte-identical serialized output) and operate completely offline,
/// with no network, API, LLM or external-service dependency. Determinism across
/// independently constructed service instances is the strongest offline
/// guarantee: nothing remote or time-varying can affect the output.
void main() {
  final svc = buildSyntheticQaService();

  group('A. repeated generation equality', () {
    test('building the same source twice yields equal products', () {
      final a = svc.buildForCase('ALPHA');
      final b = svc.buildForCase('ALPHA');
      expect(a, b);
    });

    test('byte-identical serialized output across repeated generation', () {
      final jsonA = jsonEncode(svc.buildForCase('ALPHA')!.toJson());
      final jsonB = jsonEncode(svc.buildForCase('ALPHA')!.toJson());
      expect(jsonA, jsonB);
    });
  });

  group('B. cross-instance equality', () {
    test('independently constructed services produce equal products', () {
      final a = buildSyntheticQaService().buildForCase('ALPHA');
      final b = buildSyntheticQaService().buildForCase('ALPHA');
      expect(a, b);
    });

    test('buildAll is byte-identical across two independent instances', () {
      List<String> serialize(QuestionKnowledgeProductService s) => [
            for (final p in s.buildAll()) jsonEncode(p.toJson()),
          ];
      expect(serialize(buildSyntheticQaService()),
          serialize(buildSyntheticQaService()));
    });
  });

  group('C. deterministic ordering', () {
    test('question order within a product is stable across instances', () {
      final a = buildSyntheticQaService().buildForCase('ALPHA')!;
      final b = buildSyntheticQaService().buildForCase('ALPHA')!;
      expect(
        a.questions.map((q) => q.questionId).toList(),
        b.questions.map((q) => q.questionId).toList(),
      );
    });

    test('serialized JSON has no time/random/path fields', () {
      final json = svc.buildForCase('ALPHA')!.toJson();
      expect(json.containsKey('generatedAt'), isFalse);
      expect(json.containsKey('timestamp'), isFalse);
      expect(json.containsKey('machinePath'), isFalse);
    });
  });

  group('D. offline-first', () {
    test('product building is synchronous and needs no async setup', () {
      // Synchronous construction over local validated data only.
      final all = buildSyntheticQaService().buildAll();
      expect(all, isNotEmpty);
    });

    test('no product content embeds a network address or file path', () {
      for (final p in buildSyntheticQaService().buildAll()) {
        for (final q in p.questions) {
          final lower =
              '${q.questionText} ${q.answer.answerText}'.toLowerCase();
          expect(lower, isNot(contains('http://')));
          expect(lower, isNot(contains('https://')));
          expect(lower, isNot(contains('api.')));
          expect(lower, isNot(contains('C:\\')));
        }
      }
    });
  });
}
