import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P5 service layer — case → case precedent queries (TITAN-KO-015.0 P5).
void main() {
  final service = PrecedentGraphService();

  group('followed relationship', () {
    test('MINERVA_MILLS followed KESAVANANDA', () {
      final precedents = service.directPrecedents('MINERVA_MILLS');
      expect(precedents.map((e) => e.targetId), contains('KESAVANANDA'));
      final e = precedents.firstWhere((e) => e.targetId == 'KESAVANANDA');
      expect(e.type, PrecedentRelationshipType.followed);
      expect(e.provenance, 'corpus:precedentsFollowed');
    });

    test('casesFollowing(KESAVANANDA) returns the three followers', () {
      final followers = service.casesFollowing('KESAVANANDA');
      expect(followers.map((e) => e.sourceId).toSet(),
          {'MINERVA_MILLS', 'IR_COELHO', 'L_CHANDRA_KUMAR'});
    });
  });

  group('overruled relationship', () {
    test('KESAVANANDA overruled GOLAKNATH', () {
      final edges = service.outgoingRelationships('KESAVANANDA');
      final e = edges.firstWhere(
          (e) => e.targetId == 'GOLAKNATH',
          orElse: () => throw StateError('missing overrule edge'));
      expect(e.type, PrecedentRelationshipType.overruled);
    });

    test('GOLAKNATH overruled Shankari Prasad and Sajjan Singh', () {
      final edges = service.outgoingRelationships('GOLAKNATH')
          .where((e) => e.type == PrecedentRelationshipType.overruled);
      expect(edges.map((e) => e.targetId).toSet(),
          {'SHANKARI_PRASAD', 'SAJJAN_SINGH'});
    });

    test('casesOverruling(AK_GOPALAN) returns Maneka Gandhi and Puttaswamy',
        () {
      final overruling = service.casesOverruling('AK_GOPALAN');
      expect(overruling.map((e) => e.sourceId).toSet(),
          {'MANEKA_GANDHI', 'PUTTASWAMY'});
    });

    test('casesOverruling(GOLAKNATH) returns KESAVANANDA', () {
      expect(service.casesOverruling('GOLAKNATH').map((e) => e.sourceId),
          contains('KESAVANANDA'));
    });
  });

  group('distinguished relationship', () {
    test('LALITA_KUMARI distinguished DK_BASU', () {
      final edges = service.casesDistinguishing('DK_BASU');
      expect(edges.map((e) => e.sourceId), contains('LALITA_KUMARI'));
    });

    test('M_NAGARAJ distinguished CHAMPAKAM_DORAIRAJAN', () {
      final edges = service.outgoingRelationships('M_NAGARAJ')
          .where((e) => e.type == PrecedentRelationshipType.distinguished);
      expect(edges.map((e) => e.targetId), contains('CHAMPAKAM_DORAIRAJAN'));
    });
  });

  group('related relationship', () {
    test('relatedCases is symmetric', () {
      final maneka = service.relatedCases('MANEKA_GANDHI').map((e) => e.targetId);
      expect(maneka, contains('PUTTASWAMY'));
      expect(maneka, contains('DK_BASU'));
      // Directionality of the stored edge does not matter for relatedness.
      final puttaswamy =
          service.relatedCases('PUTTASWAMY').map((e) => e.targetId);
      expect(puttaswamy, contains('MANEKA_GANDHI'));
    });

    test('shared doctrine does not imply a related edge', () {
      // KESAVANANDA and SR_BOMMAI both engage BASIC_STRUCTURE, but the corpus
      // records no explicit `related` edge between them.
      final related =
          service.relatedCases('KESAVANANDA').map((e) => e.targetId).toSet();
      expect(related, isNot(contains('SR_BOMMAI')));
    });
  });

  group('Relationship direction', () {
    test('the recorded source is the case that establishes the edge', () {
      final edges = service.relationshipsBetween('MANEKA_GANDHI', 'AK_GOPALAN');
      // MANEKA_GANDHI overruled AK_GOPALAN, and AK_GOPALAN is related to
      // MANEKA_GANDHI — both directions are recorded, each with its own source.
      final overrule = edges.singleWhere((e) => e.type ==
          PrecedentRelationshipType.overruled);
      expect(overrule.sourceId, 'MANEKA_GANDHI');
      expect(overrule.targetId, 'AK_GOPALAN');
      final related = edges.singleWhere(
          (e) => e.type == PrecedentRelationshipType.related);
      expect(related.sourceId, 'AK_GOPALAN');
      expect(related.targetId, 'MANEKA_GANDHI');
    });
  });

  group('Invalid case IDs', () {
    test('unknown case IDs resolve to empty results', () {
      expect(service.directPrecedents('NO_SUCH_CASE'), isEmpty);
      expect(service.casesFollowing('NO_SUCH_CASE'), isEmpty);
      expect(service.casesOverruling('NO_SUCH_CASE'), isEmpty);
      expect(service.casesDistinguishing('NO_SUCH_CASE'), isEmpty);
      expect(service.relatedCases('NO_SUCH_CASE'), isEmpty);
      expect(service.outgoingRelationships('NO_SUCH_CASE'), isEmpty);
      expect(service.hasCase('NO_SUCH_CASE'), isFalse);
    });

    test('empty case ID resolves to empty results', () {
      expect(service.outgoingRelationships(''), isEmpty);
    });
  });

  group('Node access', () {
    test('caseNode resolves canonical IDs', () {
      final n = service.caseNode('KESAVANANDA');
      expect(n, isNotNull);
      expect(n!.name, contains('Kesavananda'));
      expect(n.attributes['year'], 1973);
    });

    test('allCases exposes the 49 corpus cases', () {
      expect(service.allCases.length, 49);
    });
  });
}
