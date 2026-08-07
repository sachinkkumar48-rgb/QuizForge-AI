import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

void main() {
  group('CaseKnowledgeObject Entity & Serialization Tests', () {
    test('Creation of CaseKnowledgeObject holds all required fields', () {
      final kesavananda = LandmarkCasesPhase1.cases.firstWhere((c) => c.caseId == 'KESAVANANDA');

      expect(kesavananda.objectId, equals('KO-CASE-KESAVANANDA'));
      expect(kesavananda.caseName, equals('Kesavananda Bharati v. State of Kerala'));
      expect(kesavananda.citation, equals('AIR 1973 SC 1461'));
      expect(kesavananda.year, equals(1973));
      expect(kesavananda.bench, contains('13-Judge'));
      expect(kesavananda.ratioDecidendi, isNotEmpty);
      expect(kesavananda.relatedArticles, contains('368'));
      expect(kesavananda.pyqIds, isNotEmpty);
    });

    test('CaseKnowledgeObject toJson and fromJson round-trip preserves payload', () {
      final puttaswamy = LandmarkCasesPhase1.cases.firstWhere((c) => c.caseId == 'PUTTASWAMY');
      final json = puttaswamy.toJson();
      final restored = CaseKnowledgeObject.fromJson(json);

      expect(restored.objectId, equals(puttaswamy.objectId));
      expect(restored.caseName, equals(puttaswamy.caseName));
      expect(restored.citation, equals(puttaswamy.citation));
      expect(restored.ratioDecidendi, equals(puttaswamy.ratioDecidendi));
      expect(restored.relatedArticles, equals(puttaswamy.relatedArticles));
      expect(restored.judgmentDate, equals(puttaswamy.judgmentDate));
    });
  });
}
