library;

import '../repository/pyq_repository_interface.dart';
import '../search/pyq_search_engine.dart';
import 'answer_keys/official_answer_key_merger.dart';
import 'batch_importer.dart';
import 'pdf/official_paper_loader.dart';
import 'parser/official_paper_parser.dart';
import 'progress/import_progress_tracker.dart';
import 'progress/resume_manager.dart';
import 'reporting/coverage_report.dart';
import 'reporting/import_report.dart';
import 'validation/pyq_ingestion_validator.dart';

class PYQMassIngestionService {
  final IPYQRepository repository;
  final PYQSearchEngine? searchEngine;
  final ResumeManager resumeManager = ResumeManager();

  PYQMassIngestionService({
    required this.repository,
    this.searchEngine,
  });

  /// Execute end-to-end ingestion pipeline for an official examination paper document.
  Future<ImportReport> ingestOfficialPaper({
    required PaperDocumentBuffer document,
    Map<int, AnswerKeyEntry> answerKeyMap = const {},
    String? batchId,
  }) async {
    final startTime = DateTime.now();
    final effectiveBatchId = batchId ?? document.id;

    // Check for previous resume checkpoint
    final checkpoint = resumeManager.getCheckpoint(effectiveBatchId);
    final lastProcessedQ = checkpoint?.lastProcessedQuestionNumber ?? 0;

    // Validate raw document
    final docErrors = PYQIngestionValidator.validateDocument(document);
    if (docErrors.isNotEmpty) {
      return ImportReport(
        batchId: effectiveBatchId,
        questionsExpected: 0,
        questionsImported: 0,
        questionsFailed: 0,
        duplicatesCount: 0,
        missingAnswersCount: 0,
        coveragePercentage: 0.0,
        processingTime: DateTime.now().difference(startTime),
        validationErrors: docErrors,
      );
    }

    // Step 1: Parse paper
    final drafts = OfficialPaperParser.parsePaper(document);
    final totalExpected = drafts.length;

    // Filter out already processed questions if resuming
    final activeDrafts = drafts.where((d) => d.questionNumber > lastProcessedQ).toList();

    // Step 2: Merge official answer key
    final mergedResults = OfficialAnswerKeyMerger.mergeAnswerKeys(
      drafts: activeDrafts,
      answerKeyMap: answerKeyMap,
    );

    // Step 3: Fetch existing repository questions for duplicate check
    final existing = await repository.getAllQuestions();

    // Step 4: Batch Processing & Validation
    final batchResult = BatchImporter.processBatch(
      mergedResults: mergedResults,
      document: document,
      existingQuestions: existing,
    );

    // Step 5: Save valid questions into offline repository & auto search indexing
    if (batchResult.validQuestions.isNotEmpty) {
      await repository.saveQuestions(batchResult.validQuestions);
    }

    // Step 6: Progress Tracker & Resume Manager Checkpoint Update
    final tracker = ImportProgressTracker(totalExpected: totalExpected);
    for (int i = 0; i < batchResult.validQuestions.length; i++) {
      tracker.recordSuccess();
    }
    for (int i = 0; i < batchResult.editorialQueue.length; i++) {
      tracker.recordFailure();
    }

    final newLastQ = activeDrafts.isNotEmpty ? activeDrafts.last.questionNumber : lastProcessedQ;
    final importedIds = batchResult.validQuestions.map((q) => q.id).toSet();

    resumeManager.saveCheckpoint(IngestionCheckpoint(
      batchId: effectiveBatchId,
      lastProcessedQuestionNumber: newLastQ,
      importedQuestionIds: importedIds,
      timestamp: DateTime.now(),
    ));

    final totalImported = batchResult.validQuestions.length;

    return ImportReport(
      batchId: effectiveBatchId,
      questionsExpected: totalExpected,
      questionsImported: totalImported,
      questionsFailed: batchResult.editorialQueue.length,
      duplicatesCount: batchResult.duplicateCount,
      missingAnswersCount: batchResult.missingAnswerCount,
      coveragePercentage: totalExpected > 0 ? (totalImported / totalExpected) * 100.0 : 0.0,
      processingTime: DateTime.now().difference(startTime),
      validationErrors: batchResult.validationErrors,
    );
  }

  /// Generates master coverage report across the repository.
  Future<CoverageReport> getMasterCoverageReport() async {
    return CoverageReport.generate(repository);
  }
}
