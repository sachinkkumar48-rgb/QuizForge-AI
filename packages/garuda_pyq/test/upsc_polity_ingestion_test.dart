import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('Official UPSC CSE Polity Ingestion Tests', () {
    late OfflinePYQRepository pyqRepo;
    late OfficialPaperIngestionPipeline pipeline;

    setUp(() {
      pyqRepo = OfflinePYQRepository();
      pipeline = OfficialPaperIngestionPipeline(pyqRepo);
    });

    test('processAndIngestDataset ingests official UPSC Polity PYQs with full metadata', () async {
      final dataset = UPSCPolityDataset.getOfficialPolityQuestions();
      expect(dataset.length, greaterThanOrEqualTo(2));

      final report = await pipeline.processAndIngestDataset(dataset);

      expect(report.totalQuestionsExtracted, equals(dataset.length));
      expect(report.totalVerified, equals(dataset.length));
      expect(report.totalConceptMapped, equals(dataset.length));
      expect(report.totalKnowledgeLinked, equals(dataset.length));
      expect(report.totalReadyForPublication, equals(dataset.length));

      final q2024 = await pyqRepo.getQuestionById('PYQ_UPSC_CSE_2024_GS1_Q014');
      expect(q2024, isNotNull);
      expect(q2024!.source.sourceType, equals(SourceType.officialPdf));
      expect(q2024.source.checksum.isNotEmpty, isTrue);
      expect(q2024.officialAnswer.correctOptionKeys, contains('B'));
      expect(q2024.trap, isNotNull);
      expect(q2024.trap!.trapType, contains('Qualifier Trap'));
      expect(q2024.learningObjectives, isNotNull);
    });
  });
}
