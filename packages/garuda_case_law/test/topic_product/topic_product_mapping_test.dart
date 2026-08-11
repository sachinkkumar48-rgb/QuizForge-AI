import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P14 — mapping tests (TITAN-KO-015.0 P14).
///
/// Pins how validated P3/P4 case signals map to P14 topics and how the P14-local
/// validator detects invalid / duplicate / orphaned / missing-signal mappings.
/// A case never enters a topic without an explicit, validated signal.
void main() {
  final svc = buildSyntheticTopicService();
  final validator = TopicMappingValidator(service: svc);

  group('A. valid mapping', () {
    test('a validated P4 signal maps a case to a topic', () {
      final p = svc.build('topic_alpha')!;
      expect(p.memberCaseIds, containsAll(['ALPHA', 'BETA']));
      expect(p.hasSection(TopicSectionType.memberCases), isTrue);
    });

    test('the valid synthetic config validates cleanly', () {
      final r = validator.validate();
      expect(r.isValid, isTrue);
      expect(r.errors, isEmpty);
    });

    test('a case mapped via multiple distinct signals is accepted', () {
      // ALPHA maps to topic_alpha via p4:mainsThemes AND p3:themes; distinct
      // signals are not a conflict.
      final memberships = svc.config.membershipsForTopic('topic_alpha');
      expect(memberships.where((m) => m.caseId == 'ALPHA').length, 2);
      final r = validator.validate();
      expect(r.errors.where((i) => i.code == 'duplicate-membership'), isEmpty);
    });
  });

  group('B. invalid / unsafe mapping', () {
    test('an orphaned case (not in corpus) is an error', () {
      const bad = TopicSyllabusConfig(
        version: 'test-bad',
        mappingDeclaration: 'test',
        topics: [
          TopicIdentity(
            id: 'topic_bad',
            name: 'Bad Topic',
            area: UpscSyllabusArea.gs2,
            pedagogicalPath: 'GS Paper II → Bad',
            mappingKind: TopicMappingKind.pedagogicalMapping,
            configVersion: 'test-bad',
          ),
        ],
        memberships: [
          TopicMembership(
            topicId: 'topic_bad',
            caseId: 'NOT_IN_CORPUS',
            signalField: TopicSignalField.p3Themes,
            signalValue: 'x',
          ),
        ],
        overviews: {},
      );
      final v = TopicMappingValidator(
        service: TopicKnowledgeProductService(
          cases: syntheticTopicCorpus(),
          doctrines: syntheticTopicDoctrines(),
          config: bad,
        ),
      );
      final r = v.validate();
      expect(r.isValid, isFalse);
      expect(
        r.errors.where((i) => i.code == 'orphan-case'),
        isNotEmpty,
      );
    });

    test('a missing signal (value absent on the case) is an error', () {
      const bad = TopicSyllabusConfig(
        version: 'test-bad2',
        mappingDeclaration: 'test',
        topics: [
          TopicIdentity(
            id: 'topic_bad',
            name: 'Bad Topic',
            area: UpscSyllabusArea.gs2,
            pedagogicalPath: 'GS Paper II → Bad',
            mappingKind: TopicMappingKind.pedagogicalMapping,
            configVersion: 'test-bad2',
          ),
        ],
        memberships: [
          TopicMembership(
            topicId: 'topic_bad',
            caseId: 'ALPHA',
            signalField: TopicSignalField.p4MainsThemes,
            signalValue: 'Not a real theme',
          ),
        ],
        overviews: {},
      );
      final v = TopicMappingValidator(
        service: TopicKnowledgeProductService(
          cases: syntheticTopicCorpus(),
          doctrines: syntheticTopicDoctrines(),
          config: bad,
        ),
      );
      final r = v.validate();
      expect(r.isValid, isFalse);
      expect(r.errors.where((i) => i.code == 'missing-signal'), isNotEmpty);
    });

    test('an unsupported signal field is an error', () {
      const bad = TopicSyllabusConfig(
        version: 'test-bad3',
        mappingDeclaration: 'test',
        topics: [
          TopicIdentity(
            id: 'topic_bad',
            name: 'Bad Topic',
            area: UpscSyllabusArea.gs2,
            pedagogicalPath: 'GS Paper II → Bad',
            mappingKind: TopicMappingKind.pedagogicalMapping,
            configVersion: 'test-bad3',
          ),
        ],
        memberships: [
          TopicMembership(
            topicId: 'topic_bad',
            caseId: 'ALPHA',
            signalField: 'p9:discovery',
            signalValue: 'x',
          ),
        ],
        overviews: {},
      );
      final v = TopicMappingValidator(
        service: TopicKnowledgeProductService(
          cases: syntheticTopicCorpus(),
          doctrines: syntheticTopicDoctrines(),
          config: bad,
        ),
      );
      final r = v.validate();
      expect(r.isValid, isFalse);
      expect(
        r.errors.where((i) => i.code == 'unknown-signal-field'),
        isNotEmpty,
      );
    });

    test('a duplicate exact membership is an error', () {
      const bad = TopicSyllabusConfig(
        version: 'test-bad4',
        mappingDeclaration: 'test',
        topics: [
          TopicIdentity(
            id: 'topic_bad',
            name: 'Bad Topic',
            area: UpscSyllabusArea.gs2,
            pedagogicalPath: 'GS Paper II → Bad',
            mappingKind: TopicMappingKind.pedagogicalMapping,
            configVersion: 'test-bad4',
          ),
        ],
        memberships: [
          TopicMembership(
            topicId: 'topic_bad',
            caseId: 'ALPHA',
            signalField: TopicSignalField.p3Themes,
            signalValue: 'equality',
          ),
          TopicMembership(
            topicId: 'topic_bad',
            caseId: 'ALPHA',
            signalField: TopicSignalField.p3Themes,
            signalValue: 'equality',
          ),
        ],
        overviews: {},
      );
      final v = TopicMappingValidator(
        service: TopicKnowledgeProductService(
          cases: syntheticTopicCorpus(),
          doctrines: syntheticTopicDoctrines(),
          config: bad,
        ),
      );
      final r = v.validate();
      expect(r.isValid, isFalse);
      expect(
        r.errors.where((i) => i.code == 'duplicate-membership'),
        isNotEmpty,
      );
    });

    test('an unknown topic ID on a membership is an error', () {
      const bad = TopicSyllabusConfig(
        version: 'test-bad5',
        mappingDeclaration: 'test',
        topics: [
          TopicIdentity(
            id: 'topic_bad',
            name: 'Bad Topic',
            area: UpscSyllabusArea.gs2,
            pedagogicalPath: 'GS Paper II → Bad',
            mappingKind: TopicMappingKind.pedagogicalMapping,
            configVersion: 'test-bad5',
          ),
        ],
        memberships: [
          TopicMembership(
            topicId: 'topic_unknown',
            caseId: 'ALPHA',
            signalField: TopicSignalField.p3Themes,
            signalValue: 'equality',
          ),
        ],
        overviews: {},
      );
      final v = TopicMappingValidator(
        service: TopicKnowledgeProductService(
          cases: syntheticTopicCorpus(),
          doctrines: syntheticTopicDoctrines(),
          config: bad,
        ),
      );
      final r = v.validate();
      expect(r.isValid, isFalse);
      expect(r.errors.where((i) => i.code == 'unknown-topic'), isNotEmpty);
    });
  });

  group('C. unmapped data', () {
    test(
        'an unmapped case is reported informationally, never invented into a '
        'topic', () {
      final r = validator.validate();
      final unmapped = r.infos
          .where((i) => i.code == 'unmapped-case')
          .map((i) => i.subject)
          .toList();
      // GAMMA carries no membership; it is surfaced (not fabricated) and the
      // overall mapping stays valid.
      expect(r.isValid, isTrue);
      expect(unmapped, contains('GAMMA'));
    });
  });

  group('D. deterministic mapping', () {
    test('repeated mapping is identical', () {
      final a = svc.build('topic_alpha')!;
      final b = svc.build('topic_alpha')!;
      expect(a, equals(b));
      expect(a.toJson(), b.toJson());
    });

    test('buildAll is deterministic across calls', () {
      final a = svc.buildAll().map((p) => p.toJson()).toList();
      final b = svc.buildAll().map((p) => p.toJson()).toList();
      expect(a, b);
    });
  });
}
