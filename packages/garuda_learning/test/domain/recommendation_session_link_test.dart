import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/recommendation_session_link.dart';

void main() {
  group('RecommendationSessionLink Domain Entity Tests', () {
    final timestamp = DateTime.utc(2026, 8, 18, 10, 30, 0);

    test(
        'instantiates valid recommendation session link with immutable metadata',
        () {
      final link = RecommendationSessionLink(
        linkId: 'link_101',
        instanceId: 'inst_202',
        sessionId: 'session_303',
        linkedAt: timestamp,
        metadata: const {'mode': 'retry'},
      );

      expect(link.linkId, equals('link_101'));
      expect(link.instanceId, equals('inst_202'));
      expect(link.sessionId, equals('session_303'));
      expect(link.linkedAt, equals(timestamp));
      expect(link.metadata['mode'], equals('retry'));
    });

    test(
        'supports 1-to-many relationship (multiple session links per instance)',
        () {
      final link1 = RecommendationSessionLink(
        linkId: 'link_attempt_1',
        instanceId: 'inst_100',
        sessionId: 'session_part_1',
        linkedAt: timestamp,
      );
      final link2 = RecommendationSessionLink(
        linkId: 'link_attempt_2',
        instanceId: 'inst_100',
        sessionId: 'session_part_2',
        linkedAt: timestamp.add(const Duration(hours: 1)),
      );

      expect(link1.instanceId, equals(link2.instanceId));
      expect(link1.sessionId, isNot(equals(link2.sessionId)));
      expect(link1.linkId, isNot(equals(link2.linkId)));
    });

    test('throws ArgumentError on blank required fields', () {
      expect(
        () => RecommendationSessionLink(
          linkId: '  ',
          instanceId: 'inst_1',
          sessionId: 'session_1',
          linkedAt: timestamp,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationSessionLink(
          linkId: 'link_1',
          instanceId: '',
          sessionId: 'session_1',
          linkedAt: timestamp,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationSessionLink(
          linkId: 'link_1',
          instanceId: 'inst_1',
          sessionId: '   ',
          linkedAt: timestamp,
        ),
        throwsArgumentError,
      );
    });

    test('serializes and deserializes to/from JSON accurately', () {
      final link = RecommendationSessionLink(
        linkId: 'link_404',
        instanceId: 'inst_505',
        sessionId: 'session_606',
        linkedAt: timestamp,
        metadata: const {'attemptIndex': 2},
      );

      final json = link.toJson();
      final restored = RecommendationSessionLink.fromJson(json);

      expect(restored, equals(link));
      expect(restored.sessionId, equals('session_606'));
      expect(restored.metadata['attemptIndex'], equals(2));
    });

    test('value equality and hashCode are deterministic', () {
      final l1 = RecommendationSessionLink(
        linkId: 'link_1',
        instanceId: 'inst_1',
        sessionId: 'session_1',
        linkedAt: timestamp,
      );
      final l2 = RecommendationSessionLink(
        linkId: 'link_1',
        instanceId: 'inst_1',
        sessionId: 'session_1',
        linkedAt: timestamp,
      );
      final l3 = RecommendationSessionLink(
        linkId: 'link_2',
        instanceId: 'inst_1',
        sessionId: 'session_1',
        linkedAt: timestamp,
      );

      expect(l1, equals(l2));
      expect(l1.hashCode, equals(l2.hashCode));
      expect(l1, isNot(equals(l3)));
    });
  });
}
