import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P4.8 — Editorial integration: GARUDA Editorial Production Engine reuse for
/// Judgment Intelligence (TITAN-KO-015.0 P4).
void main() {
  final kesavananda =
      CaseSeedData.cases.firstWhere((c) => c.caseId == 'KESAVANANDA');

  group('JudgmentIntelligenceEditorialService', () {
    late JudgmentIntelligenceEditorialService service;
    setUp(() => service = JudgmentIntelligenceEditorialService());

    test('submits a case into the editorial workflow', () {
      expect(
        () => service.submitToEditorialWorkflow(kesavananda),
        returnsNormally,
      );
    });

    test('calculates a quality score breakdown for an approved case', () {
      final approved =
          kesavananda.copyWith(editorialStatus: 'APPROVED');
      final breakdown = service.calculateQualityScore(approved);
      expect(breakdown.totalScore, greaterThanOrEqualTo(80.0));
    });

    test('evidence gate passes for the curated corpus', () {
      final result = service.evidenceVerificationGate(kesavananda);
      expect(result.isValid, isTrue);
      expect(service.passesEvidenceGate(kesavananda), isTrue);
    });

    test('advances an object through editorial stages', () {
      service.submitToEditorialWorkflow(kesavananda);
      final result = service.advanceEditorialStage(
        objectId: kesavananda.objectId,
        actorId: 'ed1',
        actorName: 'Editor',
      );
      expect(result.isSuccess, isTrue);
    });

    test('publication gate validates the approved case', () {
      final approved =
          kesavananda.copyWith(editorialStatus: 'APPROVED');
      final gate = service.validatePublicationGate(approved);
      expect(gate.isPassed, isTrue);
      expect(gate.blockingReasons, isEmpty);
    });

    test('publishes an approved case', () {
      final approved =
          kesavananda.copyWith(editorialStatus: 'APPROVED');
      final published = service.publish(
        approved,
        actorId: 'editor_001',
        actorName: 'Chief Editor',
      );
      expect(published.editorialStatus, equals('PUBLISHED'));
      expect(published.version, greaterThanOrEqualTo(approved.version));
    });

    test('intelligence appears in the editorial bridge metadata', () {
      final ko = kesavananda.toGarudaKnowledgeObject();
      expect(ko.metadata['judgmentIntelligence'], isA<Map<String, dynamic>>());
      final intel = ko.metadata['judgmentIntelligence'] as Map<String, dynamic>;
      expect(intel['caseId'], 'KESAVANANDA');
    });
  });
}
