import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart';

void main() {
  group('InMemoryDoctrineRepository Query Tests', () {
    late InMemoryDoctrineRepository repository;

    setUp(() {
      repository = InMemoryDoctrineRepository();
    });

    test('getDoctrines returns all 20 Phase I Constitutional Doctrines', () async {
      final doctrines = await repository.getDoctrines();
      expect(doctrines.length, equals(20));
    });

    test('findDoctrine retrieves doctrine by ID, objectId, or name', () async {
      final bs = await repository.findDoctrine('BASIC_STRUCTURE');
      expect(bs, isNotNull);
      expect(bs!.name, equals('Basic Structure Doctrine'));

      final eclipse = await repository.findDoctrine('KO-DOC-ECLIPSE');
      expect(eclipse, isNotNull);
      expect(eclipse!.doctrineId, equals('ECLIPSE'));

      final severability = await repository.findDoctrine('Severability');
      expect(severability, isNotNull);
      expect(severability!.name, equals('Doctrine of Severability'));
    });

    test('getDoctrinesByCategory retrieves doctrines by category', () async {
      final frDoctrines = await repository.getDoctrinesByCategory(DoctrineCategory.fundamentalRights);
      expect(frDoctrines, isNotEmpty);
      expect(frDoctrines.any((d) => d.doctrineId == 'ECLIPSE'), isTrue);
      expect(frDoctrines.any((d) => d.doctrineId == 'SEVERABILITY'), isTrue);
    });

    test('getDoctrinesByArticle retrieves doctrines referencing Article 14 or 368', () async {
      final art368Doctrines = await repository.getDoctrinesByArticle('368');
      expect(art368Doctrines, isNotEmpty);
      expect(art368Doctrines.any((d) => d.doctrineId == 'BASIC_STRUCTURE'), isTrue);
    });

    test('getDoctrinesByCase retrieves doctrines originating or developed in Kesavananda or Maneka', () async {
      final kesavanandaDoctrines = await repository.getDoctrinesByCase('Kesavananda');
      expect(kesavanandaDoctrines, isNotEmpty);
      expect(kesavanandaDoctrines.any((d) => d.doctrineId == 'BASIC_STRUCTURE'), isTrue);
    });

    test('searchDoctrines performs multi-criteria search', () async {
      final proportionalityResults = await repository.searchDoctrines('Proportionality');
      expect(proportionalityResults, isNotEmpty);
      expect(proportionalityResults.any((d) => d.doctrineId == 'PROPORTIONALITY'), isTrue);

      final environmentResults = await repository.searchDoctrines('Polluter');
      expect(environmentResults.any((d) => d.doctrineId == 'POLLUTER_PAYS'), isTrue);
    });
  });
}
