import 'package:test/test.dart';
import 'package:garuda_evidence/garuda_evidence.dart';

void main() {
  group('Lifecycle, Versioning, and Lineage Tests', () {
    final now = DateTime.now();

    test('EvidenceLifecycle transitions and JSON roundtrip', () {
      var lifecycle = EvidenceLifecycle(
        currentState: EvidenceLifecycleState.discovered,
        updatedAt: now,
      );

      lifecycle = lifecycle.transitionTo(
        EvidenceLifecycleState.collected,
        by: 'PIBCollector',
        notes: 'Ingested raw html',
      );

      lifecycle = lifecycle.transitionTo(
        EvidenceLifecycleState.parsed,
        by: 'HTMLParser',
      );

      expect(lifecycle.currentState, equals(EvidenceLifecycleState.parsed));
      expect(lifecycle.history.length, equals(2));

      final json = lifecycle.toJson();
      final restored = EvidenceLifecycle.fromJson(json);
      expect(restored.currentState, equals(EvidenceLifecycleState.parsed));
      expect(restored.history.length, equals(2));
    });

    test('EvidenceVersion snapshot and history tracking', () {
      final v1 = EvidenceVersion(
        versionNumber: 1,
        createdAt: now,
        createdBy: 'ingestion_engine',
        reason: 'Initial Ingestion',
        checksum: 'abc123hash',
      );

      final v1Previous = v1.markPrevious();
      expect(v1Previous.isCurrentVersion, isFalse);

      final v2 = EvidenceVersion(
        versionNumber: 2,
        createdAt: now.add(const Duration(hours: 1)),
        createdBy: 'editor',
        reason: 'Typo correction in title',
        checksum: 'xyz456hash',
        previousVersion: 1,
        isCurrentVersion: true,
      );

      expect(v2.previousVersion, equals(1));
      expect(v2.isCurrentVersion, isTrue);

      final restored = EvidenceVersion.fromJson(v2.toJson());
      expect(restored.versionNumber, equals(2));
      expect(restored.reason, equals('Typo correction in title'));
    });

    test('EvidenceLineage tracking and serialization', () {
      const lineage = EvidenceLineage(
        originalSource: 'Supreme Court Judgments',
        originalUrl: 'https://sci.gov.in/judgment/101.pdf',
        originalPdf: 'https://sci.gov.in/judgment/101.pdf',
        parserVersion: '2.1.0',
        validatorVersion: '1.5.0',
        knowledgeObjectsGenerated: ['KO-POLITY-01'],
        lessonsGenerated: ['LES-CONSTITUTION-05'],
        mcqsGenerated: ['MCQ-SC-2026-001'],
        flashcardsGenerated: ['FC-SC-01'],
        revisionAssetsGenerated: ['REV-CARD-01'],
      );

      expect(lineage.knowledgeObjectsGenerated, contains('KO-POLITY-01'));
      expect(lineage.mcqsGenerated, contains('MCQ-SC-2026-001'));

      final json = lineage.toJson();
      final restored = EvidenceLineage.fromJson(json);
      expect(restored.originalSource, equals('Supreme Court Judgments'));
      expect(restored.mcqsGenerated, contains('MCQ-SC-2026-001'));
    });
  });
}
