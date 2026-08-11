import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P14 — topic resolution tests (TITAN-KO-015.0 P14).
///
/// Pins how a topic is resolved from the versioned syllabus configuration:
/// valid topics resolve by canonical ID or display name, unknown topics resolve
/// to nothing (never fabricated), and every canonical topic produces a product.
void main() {
  final svc = buildSyntheticTopicService();

  group('A. valid topic resolution', () {
    test('a canonical topic ID resolves to its identity', () {
      final t = svc.resolveTopic('topic_alpha');
      expect(t, isNotNull);
      expect(t!.id, 'topic_alpha');
      expect(t.name, 'Synthetic Topic Alpha');
      expect(t.area, UpscSyllabusArea.gs2);
      expect(t.mappingKind, TopicMappingKind.pedagogicalMapping);
      expect(t.isOfficialSyllabus, isFalse);
    });

    test('a display name resolves (normalized topic lookup)', () {
      final t = svc.resolveTopic('Synthetic Topic Sparse');
      expect(t, isNotNull);
      expect(t!.id, 'topic_sparse');
    });

    test('topic lookup trims surrounding whitespace', () {
      expect(svc.resolveTopic('  topic_alpha  ')?.id, 'topic_alpha');
    });
  });

  group('B. unknown topic resolution', () {
    test('an unknown topic resolves to null', () {
      expect(svc.resolveTopic('topic_does_not_exist'), isNull);
    });

    test('an empty topic name resolves to null', () {
      expect(svc.resolveTopic(''), isNull);
    });

    test('build returns null for an unknown topic (no fabrication)', () {
      expect(svc.build('topic_does_not_exist'), isNull);
    });
  });

  group('C. topic enumeration', () {
    test('buildAll produces one product per canonical topic', () {
      final all = svc.buildAll();
      expect(all.map((p) => p.topicId).toList(),
          orderedEquals(['topic_alpha', 'topic_sparse']));
      expect(TopicKnowledgeProduct.topicKind, isNotEmpty);
      for (final p in all) {
        expect(p.configVersion, 'test-1');
      }
    });

    test('hasTopic reflects the canonical set', () {
      expect(svc.hasTopic('topic_alpha'), isTrue);
      expect(svc.hasTopic('topic_sparse'), isTrue);
      expect(svc.hasTopic('topic_nope'), isFalse);
    });

    test('topics are exposed in deterministic ID order', () {
      expect(svc.topics.map((t) => t.id).toList(),
          orderedEquals(['topic_alpha', 'topic_sparse']));
    });
  });

  group('D. case → topic resolution', () {
    test('a mapped case resolves to its pedagogical topics', () {
      final topics = svc.topicForCase('ALPHA');
      expect(topics.map((t) => t.id).toList(), ['topic_alpha']);
    });

    test('an unmapped case resolves to no topics (never inferred)', () {
      expect(svc.topicForCase('GAMMA'), isEmpty);
    });

    test('a case not in the corpus resolves to no topics', () {
      expect(svc.topicForCase('UNKNOWN'), isEmpty);
    });

    test('membershipsForCase returns the explicit memberships', () {
      final memberships = svc.membershipsForCase('ALPHA');
      expect(memberships.length, 2);
      expect(memberships.every((m) => m.caseId == 'ALPHA'), isTrue);
      expect(memberships.map((m) => m.topicId).toSet(), {'topic_alpha'});
    });
  });
}
