import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_constitution/garuda_constitution.dart';

void main() {
  late ConstitutionRepository repository;

  setUp(() {
    repository = InMemoryConstitutionRepository();
  });

  group('ConstitutionRepository Integration Tests', () {
    test('getMetadata returns accurate constitutional metadata', () async {
      final metadata = await repository.getMetadata();
      expect(metadata.title, equals('Constitution of India'));
      expect(metadata.originalArticles, equals(395));
      expect(metadata.originalParts, equals(22));
      expect(metadata.currentParts, equals(25));
      expect(metadata.currentSchedules, equals(12));
    });

    test('getPreamble returns Preamble Knowledge Object', () async {
      final preamble = await repository.getPreamble();
      expect(preamble.objectId, equals('KO_CONST_PREAMBLE'));
      expect(preamble.title, contains('Preamble'));
      expect(preamble.officialText, contains('WE, THE PEOPLE OF INDIA'));
    });

    test('getParts returns exactly 26 Parts (Parts I to XXII plus IVA, IXA, IXB, XIVA)', () async {
      final parts = await repository.getParts();
      expect(parts.length, equals(26));
      expect(parts.any((p) => p.objectId == 'KO-PART-I'), isTrue);
      expect(parts.any((p) => p.objectId == 'KO-PART-III'), isTrue);
      expect(parts.any((p) => p.objectId == 'KO-PART-IVA'), isTrue);
      expect(parts.any((p) => p.objectId == 'KO-PART-IXA'), isTrue);
      expect(parts.any((p) => p.objectId == 'KO-PART-XXII'), isTrue);
    });

    test('getSchedules returns exactly 12 Schedules', () async {
      final schedules = await repository.getSchedules();
      expect(schedules.length, equals(12));
      expect(schedules.first.objectId, equals('KO-SCHED-1'));
      expect(schedules.last.objectId, equals('KO-SCHED-12'));
    });

    test('findPart locates Part by ID or Part Number', () async {
      final part3ById = await repository.findPart('KO-PART-III');
      expect(part3ById, isNotNull);
      expect(part3ById!.title, contains('Fundamental Rights'));

      final part3ByNum = await repository.findPart('III');
      expect(part3ByNum, isNotNull);
      expect(part3ByNum!.objectId, equals('KO-PART-III'));
    });

    test('findSchedule locates Schedule by ID or Schedule Number', () async {
      final sched7ById = await repository.findSchedule('KO-SCHED-7');
      expect(sched7ById, isNotNull);
      expect(sched7ById!.title, contains('Legislative Lists'));

      final sched7ByNum = await repository.findSchedule('7');
      expect(sched7ByNum, isNotNull);
      expect(sched7ByNum!.objectId, equals('KO-SCHED-7'));
    });

    test('findByArticle locates Knowledge Objects referencing Article 21', () async {
      final results = await repository.findByArticle('Art 21');
      expect(results, isNotEmpty);
      expect(results.any((r) => r.objectId == 'KO-PART-III' || r.objectId == 'KO_CONST_PREAMBLE'), isTrue);
    });

    test('findByAmendment locates Knowledge Objects referencing 42nd Amendment', () async {
      final results = await repository.findByAmendment('42nd Amendment');
      expect(results, isNotEmpty);
      expect(results.any((r) => r.objectId == 'KO_CONST_PREAMBLE' || r.objectId == 'KO-PART-IVA'), isTrue);
    });

    test('searchObjects performs multi-criteria search by keyword, article, or topic', () async {
      final results = await repository.searchObjects('Citizenship');
      expect(results, isNotEmpty);
      expect(results.any((r) => r.objectId == 'KO-PART-II'), isTrue);
    });
  });
}
