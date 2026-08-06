import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart' hide CoverageReport;

void main() {
  group('QualityScoreEngine & QualityGates Tests', () {
    late KnowledgeObject highQualityObject;
    late KnowledgeObject incompleteObject;

    setUp(() {
      highQualityObject = KnowledgeObject(
        id: 'ko_polity_01',
        title: 'Basic Structure Doctrine (Kesavananda Bharati v. State of Kerala)',
        content:
            'The Supreme Court ruled that Parliament cannot alter the basic structure of the Constitution.',
        subject: 'Polity',
        topic: 'Constitutional Doctrines',
        officialSource: 'Supreme Court of India Official Records',
        evidenceIds: const ['ev_sb_01', 'ev_sb_02', 'ev_sb_03'],
        relatedArticles: const ['Article 368', 'Article 13'],
        relatedCaseLaws: const ['Minerva Mills v. Union of India (1980)'],
        tags: const ['polity', 'basic_structure', 'judiciary'],
        status: EditorialStatus.approved,
        isVerified: true,
      );

      incompleteObject = KnowledgeObject(
        id: 'ko_raw_01',
        title: 'Draft notes on taxes',
        content: 'Draft content.',
        subject: 'Economy',
        topic: 'Taxation',
        officialSource: '', // Missing
        evidenceIds: const [], // Missing
        tags: const [],
        status: EditorialStatus.imported,
        isVerified: false,
      );
    });

    test('QualityScoreEngine generates accurate 9-dimension quality score', () {
      final breakdown = QualityScoreEngine.calculateScore(highQualityObject);
      expect(breakdown.evidenceCompleteness, equals(15.0));
      expect(breakdown.officialSourceQuality, equals(15.0));
      expect(breakdown.factVerification, equals(10.0));
      expect(breakdown.totalScore, greaterThanOrEqualTo(80.0));
    });

    test('QualityGates blocks publication for incomplete object', () {
      final gateResult = QualityGates.validatePublicationGate(incompleteObject);
      expect(gateResult.isPassed, isFalse);
      expect(gateResult.blockingReasons.length, greaterThanOrEqualTo(3));
      expect(
        gateResult.blockingReasons.any((r) => r.contains('Missing official evidence')),
        isTrue,
      );
      expect(
        gateResult.blockingReasons.any((r) => r.contains('Missing official source')),
        isTrue,
      );
    });

    test('QualityGates approves publication for high quality approved object', () {
      final gateResult = QualityGates.validatePublicationGate(highQualityObject);
      expect(gateResult.isPassed, isTrue);
      expect(gateResult.blockingReasons, isEmpty);
    });
  });
}
