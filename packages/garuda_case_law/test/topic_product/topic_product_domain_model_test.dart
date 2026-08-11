import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P14 — `TopicKnowledgeProduct` / `TopicSection` / `TopicStatement` /
/// `TopicIdentity` / `TopicMembership` domain-model tests (TITAN-KO-015.0 P14).
///
/// The topic product is an immutable, deterministic, provenance-preserving
/// value object mirroring the P12/P13 product-model shape. These tests pin the
/// serialization round-trip, section accessors, provenance aggregation,
/// referenced-ID aggregation, identity/membership value semantics and the
/// invariant that every statement carries non-empty source references.
void main() {
  group('A. statement invariant', () {
    test('a statement without source references is rejected by assert', () {
      expect(
        () => TopicStatement(
          label: 'Member case 1',
          text: 'content',
          sourceRefs: const [],
          provenance: 'p14:membership',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a statement with source references is accepted', () {
      final s = TopicStatement(
        label: 'Member case 1',
        text: 'content',
        sourceRefs: const ['ALPHA', 'p14:config.v1'],
        provenance: 'p14:membership',
      );
      expect(s.sourceRefs, ['ALPHA', 'p14:config.v1']);
    });
  });

  group('B. section aggregation', () {
    test('provenance is unique, sorted and joined by ;', () {
      final section = TopicSection(
        type: TopicSectionType.memberCases,
        title: 'Member Cases',
        statements: [
          TopicStatement(
            label: 'Member case 1',
            text: 'a',
            sourceRefs: const ['ALPHA'],
            provenance: 'p4:mainsThemes; p14:membership',
          ),
          TopicStatement(
            label: 'Member case 2',
            text: 'b',
            sourceRefs: const ['BETA'],
            provenance: 'p3:themes',
          ),
          TopicStatement(
            label: 'Member case 3',
            text: 'c',
            sourceRefs: const ['ALPHA'],
            provenance: 'p4:mainsThemes',
          ),
        ],
      );
      expect(section.provenance, 'p14:membership;p3:themes;p4:mainsThemes');
    });

    test('references are unique and sorted', () {
      final section = TopicSection(
        type: TopicSectionType.memberCases,
        title: 'Member Cases',
        statements: [
          TopicStatement(
            label: 'a',
            text: 'a',
            sourceRefs: const ['BETA', 'ALPHA', 'BETA'],
            provenance: 'p14:membership',
          ),
        ],
      );
      expect(section.references, ['ALPHA', 'BETA']);
    });

    test('a section with no statements is empty', () {
      const section = TopicSection(
        type: TopicSectionType.overview,
        title: 'Overview',
        statements: [],
      );
      expect(section.isEmpty, isTrue);
    });
  });

  group('C. identity value semantics', () {
    test('TopicIdentity is immutable and equality-testable', () {
      const a = TopicIdentity(
        id: 'topic_x',
        name: 'Topic X',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → X',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      );
      const b = TopicIdentity(
        id: 'topic_x',
        name: 'Topic X',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → X',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      );
      const c = TopicIdentity(
        id: 'topic_y',
        name: 'Topic Y',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → Y',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('a topic never claims official syllabus status', () {
      const t = TopicIdentity(
        id: 'topic_x',
        name: 'Topic X',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → X',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      );
      expect(t.isOfficialSyllabus, isFalse);
      expect(t.mappingKind, TopicMappingKind.pedagogicalMapping);
    });
  });

  group('D. membership value semantics', () {
    test('TopicMembership is immutable and equality-testable', () {
      const a = TopicMembership(
        topicId: 'topic_x',
        caseId: 'ALPHA',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Alpha mains theme',
      );
      const b = TopicMembership(
        topicId: 'topic_x',
        caseId: 'ALPHA',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Alpha mains theme',
      );
      const c = TopicMembership(
        topicId: 'topic_x',
        caseId: 'BETA',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Alpha mains theme',
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('membership serialization round-trips', () {
      const m = TopicMembership(
        topicId: 'topic_x',
        caseId: 'ALPHA',
        signalField: TopicSignalField.p3Themes,
        signalValue: 'equality',
        note: 'test note',
      );
      final restored = TopicMembership.fromJson(m.toJson());
      expect(restored, equals(m));
    });
  });

  group('E. product construction & serialization', () {
    test('a product round-trips through JSON', () {
      final p = TopicKnowledgeProduct(
        topicId: 'topic_x',
        topicName: 'Topic X',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → X',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
        memberCaseIds: const ['ALPHA', 'BETA'],
        sections: [
          TopicSection(
            type: TopicSectionType.identity,
            title: 'Identity',
            statements: [
              TopicStatement(
                label: 'Topic ID',
                text: 'topic_x',
                sourceRefs: const ['p14:syllabusConfig'],
                provenance: 'p14:syllabusConfig.identity',
              ),
            ],
          ),
        ],
        caseExplanations: const [],
        doctrineProducts: const [],
        statuteProducts: const [],
      );
      final json = p.toJson();
      expect(json['topicKind'], TopicKnowledgeProduct.topicKind);
      final restored = TopicKnowledgeProduct.fromJson(json);
      expect(restored, equals(p));
    });

    test('a product exposes a TopicIdentity and never claims official status',
        () {
      const p = TopicKnowledgeProduct(
        topicId: 'topic_x',
        topicName: 'Topic X',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → X',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
        memberCaseIds: [],
        sections: [],
        caseExplanations: [],
        doctrineProducts: [],
        statuteProducts: [],
      );
      expect(p.identity.id, 'topic_x');
      expect(p.isOfficialSyllabus, isFalse);
      expect(p.isEmpty, isTrue);
      expect(p.sectionOf(TopicSectionType.memberCases), isNull);
      expect(p.hasSection(TopicSectionType.memberCases), isFalse);
    });

    test('referencedIds aggregates topic, members, sections and products', () {
      final p = TopicKnowledgeProduct(
        topicId: 'topic_x',
        topicName: 'Topic X',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → X',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
        memberCaseIds: const ['BETA', 'ALPHA'],
        sections: [
          TopicSection(
            type: TopicSectionType.memberCases,
            title: 'Member Cases',
            statements: [
              TopicStatement(
                label: 'Member case 1',
                text: 'ALPHA',
                sourceRefs: const ['ALPHA', 'edge:e1'],
                provenance: 'p14:membership',
              ),
            ],
          ),
        ],
        caseExplanations: const [],
        doctrineProducts: const [],
        statuteProducts: const [],
      );
      final ids = p.referencedIds;
      expect(ids, containsAll(['topic_x', 'ALPHA', 'BETA', 'edge:e1']));
      // Sorted for determinism.
      expect(ids, orderedEquals([...ids]..sort()));
    });
  });
}
