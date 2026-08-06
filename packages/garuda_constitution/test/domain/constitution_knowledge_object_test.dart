import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_constitution/garuda_constitution.dart';

void main() {
  group('ConstitutionKnowledgeObject Entity & Serialization Tests', () {
    test('Creation of ConstitutionKnowledgeObject stores all required fields', () {
      final obj = ConstitutionKnowledgeObject(
        objectId: 'KO-PART-III',
        title: 'Part III: Fundamental Rights',
        officialName: 'PART III - FUNDAMENTAL RIGHTS',
        description: 'Guarantees fundamental rights to all citizens.',
        effectiveDate: DateTime(1950, 1, 26),
        keywords: const ['Rights', 'Equality', 'Freedom'],
        aliases: const ['Fundamental Rights'],
        timeline: const ['1950-01-26: Enacted'],
        crossReferences: const ['KO-PART-IV'],
        relatedArticles: const ['Art 12', 'Art 14', 'Art 21'],
        relatedCases: const ['Kesavananda Bharati 1973'],
      );

      expect(obj.objectId, equals('KO-PART-III'));
      expect(obj.title, equals('Part III: Fundamental Rights'));
      expect(obj.status, equals(ConstitutionStatus.active));
      expect(obj.aliases, contains('Fundamental Rights'));
      expect(obj.timeline, contains('1950-01-26: Enacted'));
      expect(obj.crossReferences, contains('KO-PART-IV'));
      expect(obj.relatedArticles, contains('Art 21'));
      expect(obj.relatedCases, contains('Kesavananda Bharati 1973'));
    });

    test('PreambleKnowledgeObject serialization and specific getters', () {
      final preamble = ConstitutionSeedData.preamble;
      final json = preamble.toJson();
      final restored = PreambleKnowledgeObject.fromJson(json);

      expect(restored.objectId, equals('KO_CONST_PREAMBLE'));
      expect(restored.officialText, contains('WE, THE PEOPLE OF INDIA'));
      expect(restored.objectives, contains('JUSTICE (Social, Economic, and Political)'));
      expect(restored.historicalBackground, contains('Objectives Resolution'));
      expect(restored.fortySecondAmendmentChanges, isNotEmpty);
      expect(restored.relevantJudgments.any((j) => j.contains('Kesavananda Bharati')), isTrue);
      expect(restored.editorialNotes, isNotEmpty);
    });

    test('PartKnowledgeObject serialization and properties', () {
      final partIII = ConstitutionSeedData.parts.firstWhere((p) => p.partNumber == 'III');
      final json = partIII.toJson();
      final restored = PartKnowledgeObject.fromJson(json);

      expect(restored.partNumber, equals('III'));
      expect(restored.objectId, equals('KO-PART-III'));
      expect(restored.articlesCovered, contains('Art 21'));
      expect(restored.partType, equals(PartType.corePart));
      expect(restored.knowledgeGraphLinks, isNotEmpty);
    });

    test('ScheduleKnowledgeObject serialization and properties', () {
      final sched7 = ConstitutionSeedData.schedules.firstWhere((s) => s.scheduleNumber == '7');
      final json = sched7.toJson();
      final restored = ScheduleKnowledgeObject.fromJson(json);

      expect(restored.scheduleNumber, equals('7'));
      expect(restored.objectId, equals('KO-SCHED-7'));
      expect(restored.scheduleType, equals(ScheduleType.legislativeLists));
      expect(restored.relatedParts, contains('KO-PART-XI'));
      expect(restored.knowledgeGraphLinks, isNotEmpty);
    });

    test('toJson and fromJson cycle retains complete payload', () {
      final obj = ConstitutionKnowledgeObject(
        objectId: 'KO-SCHED-7',
        title: 'Schedule 7: Legislative Lists',
        officialName: 'SEVENTH SCHEDULE',
        description: 'Union, State, Concurrent Lists',
        effectiveDate: DateTime(1950, 1, 26),
        keywords: const ['Seventh Schedule', 'Union List', 'State List'],
        relatedParts: const ['KO-PART-XI'],
        editorialStatus: 'APPROVED',
      );

      final json = obj.toJson();
      final restored = ConstitutionKnowledgeObject.fromJson(json);

      expect(restored.objectId, equals(obj.objectId));
      expect(restored.officialName, equals(obj.officialName));
      expect(restored.keywords, equals(obj.keywords));
      expect(restored.relatedParts, equals(obj.relatedParts));
      expect(restored, equals(obj));
    });

    test('copyWith properly updates immutable state', () {
      final obj = ConstitutionKnowledgeObject(
        objectId: 'KO-PREAMBLE',
        title: 'Preamble',
        officialName: 'Preamble',
        description: 'We the people of India',
        effectiveDate: DateTime(1950, 1, 26),
      );

      final updated = obj.copyWith(
        version: 2,
        description: 'Updated Preamble Description',
      );

      expect(updated.version, equals(2));
      expect(updated.description, equals('Updated Preamble Description'));
      expect(updated.objectId, equals('KO-PREAMBLE'));
    });
  });
}
