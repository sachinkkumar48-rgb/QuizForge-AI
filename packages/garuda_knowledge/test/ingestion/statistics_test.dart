import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('Ingestion Statistics & Reporting', () {
    test('KnowledgeIngestionReport compiles metrics correctly', () {
      final session = KnowledgeImportSession.create(packageName: 'test_pkg');
      final object = KnowledgeObject(
        id: const KnowledgeObjectId('OBJ-1'),
        type: KnowledgeObjectType.custom,
        title: 'Title',
        content: 'Content',
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Initial',
          author: 'System',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'System',
        ),
      );

      final results = [
        KnowledgeImportResult.success(documentId: 'DOC-1', object: object),
        KnowledgeImportResult.updated(documentId: 'DOC-2', object: object),
        KnowledgeImportResult.duplicate(documentId: 'DOC-3'),
        KnowledgeImportResult.failure(documentId: 'DOC-4', message: 'Failed due to missing title'),
      ];

      final report = KnowledgeIngestionReport.generate(
        session: session,
        results: results,
        totalDurationMs: 125.5,
      );

      expect(report.statistics.totalProcessed, equals(4));
      expect(report.statistics.objectsCreated, equals(1));
      expect(report.statistics.objectsUpdated, equals(1));
      expect(report.statistics.duplicates, equals(1));
      expect(report.statistics.failures, equals(1));
      expect(report.statistics.processingTimeMs, equals(125.5));
      expect(report.errorLogs.length, equals(1));
    });
  });
}
