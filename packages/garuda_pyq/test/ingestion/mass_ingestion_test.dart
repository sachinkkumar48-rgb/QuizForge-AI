import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('OfficialPaperLoader Tests', () {
    test('loadFromText creates verified PaperDocumentBuffer with valid checksum', () {
      final buffer = OfficialPaperLoader.loadFromText(
        filename: 'upsc_2024_gs1.txt',
        textContent: 'Q1. What is the fundamental right under Article 14?\nA. Equality before law\nB. Freedom of speech\nC. Right to life\nD. Right to education',
        inputType: PaperInputType.pdf,
        metadata: {'examId': 'upsc_cse', 'year': 2024},
      );

      expect(buffer.id.startsWith('DOC_'), isTrue);
      expect(buffer.filename, equals('upsc_2024_gs1.txt'));
      expect(buffer.checksum.isNotEmpty, isTrue);
      expect(buffer.rawText.contains('Article 14'), isTrue);
    });

    test('loadFromBytes throws ArgumentError when bytes are empty', () {
      expect(
        () => OfficialPaperLoader.loadFromBytes(
          filename: 'empty.pdf',
          bytes: [],
          inputType: PaperInputType.pdf,
        ),
        throwsArgumentError,
      );
    });
  });

  group('OCREngine Architecture Tests', () {
    test('OCREngineStub returns valid OCRResult', () async {
      const stub = OCREngineStub();
      final result = await stub.processImage([1, 2, 3, 4]);

      expect(result.fullText.isNotEmpty, isTrue);
      expect(result.averageConfidence, greaterThanOrEqualTo(0.90));
    });
  });

  group('Parser Components Tests', () {
    test('QuestionExtractor extracts question text and raw options', () {
      const text = '''
Q1. Consider the following statements regarding the Preamble:
1. It is based on Objective Resolution.
2. It is non-justiciable.
A. 1 only
B. 2 only
C. Both 1 and 2
D. Neither 1 nor 2
''';
      final blocks = QuestionExtractor.extractBlocks(text);
      expect(blocks.isNotEmpty, isTrue);
      expect(blocks.first.questionNumber, equals(1));
      expect(blocks.first.rawOptions.length, equals(4));
    });

    test('OptionExtractor parses option keys and flags correct option', () {
      final raw = ['A: 1 only', 'B: 2 only', 'C: Both 1 and 2', 'D: Neither 1 nor 2'];
      final options = OptionExtractor.extractOptions(raw, correctKey: 'C');

      expect(options.length, equals(4));
      expect(options.firstWhere((o) => o.key == 'C').isCorrect, isTrue);
    });

    test('MetadataExtractor infers exam ID, year, and subject correctly', () {
      final meta = MetadataExtractor.extract(
        filename: 'upsc_cds_2023_polity.pdf',
        headerText: 'CDS Examination 2023 General Studies Indian Polity',
      );

      expect(meta.examId, equals('upsc_cds'));
      expect(meta.year, equals(2023));
      expect(meta.subject, equals('Polity'));
    });

    test('QuestionNormalizer cleans whitespace and prefix headers', () {
      final normalized = QuestionNormalizer.normalizeText('Q.15   Which article of the Constitution...   ');
      expect(normalized, equals('Which article of the Constitution...'));
    });
  });

  group('OfficialAnswerKeyMerger Tests', () {
    test('Merges official answer key and flags verified status', () {
      const draft = ParsedQuestionDraft(
        questionNumber: 1,
        originalQuestion: 'Test Question 1',
        rawOptions: ['A: Opt 1', 'B: Opt 2', 'C: Opt 3', 'D: Opt 4'],
        metadata: ParsedMetadata(
          examId: 'upsc_cse',
          year: 2024,
          stage: 'Prelims',
          paper: 'GS Paper I',
          subject: 'Polity',
          topic: 'Fundamental Rights',
        ),
      );

      final merged = OfficialAnswerKeyMerger.mergeAnswerKeys(
        drafts: [draft],
        answerKeyMap: {
          1: const AnswerKeyEntry(questionNumber: 1, correctOptionKey: 'B'),
        },
      );

      expect(merged.length, equals(1));
      expect(merged.first.isAnswerVerified, isTrue);
      expect(merged.first.answer.correctOptionKeys.first, equals('B'));
    });
  });

  group('PYQIngestionValidator Tests', () {
    test('Detects corrupted or empty paper buffer', () {
      final buffer = OfficialPaperLoader.loadFromText(
        filename: 'bad.txt',
        textContent: '   ',
        inputType: PaperInputType.pdf,
      );

      final errors = PYQIngestionValidator.validateDocument(buffer);
      expect(errors.any((e) => e.errorType == IngestionValidationErrorType.corruptedDocument), isTrue);
    });
  });

  group('ImportProgressTracker & ResumeManager Tests', () {
    test('ImportProgressTracker records metrics accurately', () {
      final tracker = ImportProgressTracker(totalExpected: 10);
      tracker.recordSuccess();
      tracker.recordSuccess();
      tracker.recordFailure();

      expect(tracker.processed, equals(3));
      expect(tracker.succeeded, equals(2));
      expect(tracker.failed, equals(1));
      expect(tracker.progressPercentage, equals(30.0));
    });

    test('ResumeManager saves and restores checkpoints', () {
      final rm = ResumeManager();
      final cp = IngestionCheckpoint(
        batchId: 'BATCH_001',
        lastProcessedQuestionNumber: 25,
        importedQuestionIds: {'Q001', 'Q002'},
        timestamp: DateTime.now(),
      );

      rm.saveCheckpoint(cp);
      final restored = rm.getCheckpoint('BATCH_001');

      expect(restored, isNotNull);
      expect(restored!.lastProcessedQuestionNumber, equals(25));
    });
  });

  group('PYQMassIngestionService Pipeline Integration Tests', () {
    late OfflinePYQRepository repo;
    late PYQMassIngestionService service;

    setUp(() {
      repo = OfflinePYQRepository();
      service = PYQMassIngestionService(repository: repo);
    });

    test('ingestOfficialPaper runs end-to-end pipeline cleanly', () async {
      final buffer = OfficialPaperLoader.loadFromText(
        filename: 'upsc_2024_gs1_official.pdf',
        textContent: '''
Q1. With reference to Fundamental Rights in India, consider Article 14.
A. Statement 1
B. Statement 2
C. Both Statement 1 and 2
D. Neither 1 nor 2
''',
        inputType: PaperInputType.pdf,
        metadata: {
          'examId': 'upsc_cse',
          'year': 2024,
          'subject': 'Polity',
        },
      );

      final report = await service.ingestOfficialPaper(
        document: buffer,
        answerKeyMap: {
          1: const AnswerKeyEntry(questionNumber: 1, correctOptionKey: 'C'),
        },
        batchId: 'MASS_TEST_BATCH_001',
      );

      expect(report.questionsImported, equals(1));
      expect(report.coveragePercentage, equals(100.0));

      final qCount = await repo.getQuestionCount();
      expect(qCount, equals(1));

      final coverage = await service.getMasterCoverageReport();
      expect(coverage.totalQuestionsInCorpus, equals(1));
      expect(coverage.coverageByExam['upsc_cse'], equals(1));
    });
  });
}
