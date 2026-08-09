import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineSeedData;

/// P5 service layer — case ↔ doctrine navigation, including reverse
/// doctrine → case lookup (TITAN-KO-015.0 P5).
void main() {
  final service = DoctrineRelationshipService();

  group('Case → doctrine', () {
    test('KESAVANANDA establishes BASIC_STRUCTURE', () {
      final edges = service.getDoctrinesForCase('KESAVANANDA');
      expect(edges, hasLength(1));
      expect(edges.single.targetId, 'BASIC_STRUCTURE');
      expect(edges.single.type, DoctrineRelationshipType.establishes);
    });

    test('IR_COELHO expands BASIC_STRUCTURE', () {
      final edges = service.getDoctrinesForCase('IR_COELHO');
      expect(edges, hasLength(1));
      expect(edges.single.targetId, 'BASIC_STRUCTURE');
      expect(edges.single.type, DoctrineRelationshipType.expands);
    });

    test('GOLAKNATH establishes PROSPECTIVE_OVERRULING', () {
      final edges = service.getDoctrinesForCase('GOLAKNATH');
      expect(edges.single.targetId, 'PROSPECTIVE_OVERRULING');
      expect(edges.single.type, DoctrineRelationshipType.establishes);
    });

    test('PUTTASWAMY engages PROPORTIONALITY', () {
      final edges = service.getDoctrinesForCase('PUTTASWAMY');
      expect(edges.single.targetId, 'PROPORTIONALITY');
      expect(edges.single.type, DoctrineRelationshipType.engages);
    });

    test('cases with no doctrine link return empty', () {
      expect(service.getDoctrinesForCase('VISHAKA'), isEmpty);
      expect(service.getDoctrinesForCase('NO_SUCH_CASE'), isEmpty);
    });
  });

  group('Reverse doctrine → case', () {
    test('BASIC_STRUCTURE is engaged by 8 corpus cases', () {
      final cases = service.getCasesForDoctrine('BASIC_STRUCTURE');
      expect(cases, hasLength(8));
      expect(cases.map((e) => e.sourceId).toSet(), {
        'KESAVANANDA',
        'MINERVA_MILLS',
        'IR_COELHO',
        'SR_BOMMAI',
        'NJAC_2015',
        'L_CHANDRA_KUMAR',
        'SC_OR_1993',
        'M_NAGARAJ',
      });
    });

    test('getCasesEstablishing(BASIC_STRUCTURE) returns Kesavananda', () {
      final establishing = service.getCasesEstablishing('BASIC_STRUCTURE');
      expect(establishing.map((e) => e.sourceId), ['KESAVANANDA']);
    });

    test('getCasesApplying(BASIC_STRUCTURE) returns Minerva Mills and Bommai',
        () {
      final applying = service.getCasesApplying('BASIC_STRUCTURE');
      expect(applying.map((e) => e.sourceId).toSet(),
          {'MINERVA_MILLS', 'SR_BOMMAI'});
    });

    test('getCasesExpanding(BASIC_STRUCTURE) returns I.R. Coelho', () {
      expect(service.getCasesExpanding('BASIC_STRUCTURE').map((e) => e.sourceId),
          ['IR_COELHO']);
    });

    test('getCasesFollowing(BASIC_STRUCTURE) returns NJAC', () {
      expect(service.getCasesFollowing('BASIC_STRUCTURE').map((e) => e.sourceId),
          ['NJAC_2015']);
    });

    test('SEVERABILITY is established by AK_GOPALAN', () {
      final edges = service.getCasesEstablishing('SEVERABILITY');
      expect(edges.map((e) => e.sourceId), ['AK_GOPALAN']);
    });

    test('PRECAUTIONARY_PRINCIPLE is established by Vellore Citizens', () {
      final edges = service.getCasesEstablishing('PRECAUTIONARY_PRINCIPLE');
      expect(edges.map((e) => e.sourceId), ['VELLORE_CITIZENS']);
    });

    test('PROPORTIONALITY is engaged by Puttaswamy and Navtej Johar', () {
      final edges = service.getCasesForDoctrine('PROPORTIONALITY');
      expect(edges.map((e) => e.sourceId).toSet(),
          {'PUTTASWAMY', 'NAVTEJ_JOHAR'});
    });
  });

  group('Canonical doctrine IDs', () {
    test('every graph doctrine node is a canonical garuda_doctrine ID', () {
      final graphIds =
          service.allDoctrines.map((n) => n.id).toSet();
      final canonical =
          DoctrineSeedData.doctrines.map((d) => d.doctrineId).toSet();
      expect(graphIds, canonical);
    });

    test('invalid doctrine ID resolves to empty and hasDoctrine is false', () {
      expect(service.hasDoctrine('NO_SUCH_DOCTRINE'), isFalse);
      expect(service.getCasesForDoctrine('NO_SUCH_DOCTRINE'), isEmpty);
      expect(service.doctrineNode('NO_SUCH_DOCTRINE'), isNull);
      expect(service.getCasesEstablishing('NO_SUCH_DOCTRINE'), isEmpty);
    });

    test('doctrineNode resolves a known doctrine', () {
      final n = service.doctrineNode('BASIC_STRUCTURE');
      expect(n, isNotNull);
      expect(n!.name, contains('Basic Structure'));
    });
  });
}
