import '../../indexing/knowledge_index_manager.dart';
import '../../pipeline/knowledge_registration_pipeline.dart';
import '../../repositories/knowledge_repository.dart';
import '../models/knowledge_document.dart';
import '../models/knowledge_editorial_status.dart';
import '../models/knowledge_import_result.dart';
import '../models/knowledge_import_session.dart';
import '../models/knowledge_ingestion_report.dart';
import '../processors/default_knowledge_processor.dart';
import '../processors/knowledge_processor.dart';
import '../publication/knowledge_publication_service.dart';
import '../sources/constitution_source_adapter.dart';
import '../sources/economic_survey_adapter.dart';
import '../sources/gazette_notification_adapter.dart';
import '../sources/knowledge_source_adapter.dart';
import '../sources/ministry_report_adapter.dart';
import '../sources/pib_release_adapter.dart';
import '../sources/prs_report_adapter.dart';
import '../sources/supreme_court_judgment_adapter.dart';
import '../sources/union_budget_adapter.dart';
import '../sources/upsc_answer_key_adapter.dart';
import '../sources/upsc_question_paper_adapter.dart';
import '../validators/composite_ingestion_validator.dart';
import '../validators/duplicate_document_validator.dart';

/// Master Ingestion Orchestrator Service for GARUDA National Knowledge Ingestion Framework.
class KnowledgeIngestionService {
  final KnowledgeRegistrationPipeline registrationPipeline;
  final KnowledgeRepository repository;
  final KnowledgeIndexManager indexManager;
  final KnowledgePublicationService publicationService;
  final KnowledgeProcessor processor;
  final CompositeIngestionValidator validator;
  final DuplicateDocumentValidator duplicateValidator;

  final List<KnowledgeSourceAdapter> adapters;

  factory KnowledgeIngestionService({
    required KnowledgeRegistrationPipeline registrationPipeline,
    required KnowledgeRepository repository,
    required KnowledgeIndexManager indexManager,
    required KnowledgePublicationService publicationService,
    KnowledgeProcessor? processor,
    CompositeIngestionValidator? validator,
    DuplicateDocumentValidator? duplicateValidator,
    List<KnowledgeSourceAdapter>? customAdapters,
  }) {
    final dupVal = duplicateValidator ?? DuplicateDocumentValidator();
    final val = validator ?? CompositeIngestionValidator(duplicateValidator: dupVal);
    final proc = processor ?? DefaultKnowledgeProcessor();
    final adpts = customAdapters ??
        [
          ConstitutionSourceAdapter(),
          GazetteNotificationAdapter(),
          UpscQuestionPaperAdapter(),
          UpscAnswerKeyAdapter(),
          PibReleaseAdapter(),
          PrsReportAdapter(),
          SupremeCourtJudgmentAdapter(),
          MinistryReportAdapter(),
          EconomicSurveyAdapter(),
          UnionBudgetAdapter(),
        ];

    return KnowledgeIngestionService._(
      registrationPipeline: registrationPipeline,
      repository: repository,
      indexManager: indexManager,
      publicationService: publicationService,
      processor: proc,
      validator: val,
      duplicateValidator: dupVal,
      adapters: adpts,
    );
  }

  KnowledgeIngestionService._({
    required this.registrationPipeline,
    required this.repository,
    required this.indexManager,
    required this.publicationService,
    required this.processor,
    required this.validator,
    required this.duplicateValidator,
    required this.adapters,
  });

  /// Resolves the appropriate source adapter for a document.
  KnowledgeSourceAdapter resolveAdapter(KnowledgeDocument document) {
    for (final adapter in adapters) {
      if (adapter.supports(document)) {
        return adapter;
      }
    }
    // Default fallback adapter using default strategy
    return ConstitutionSourceAdapter();
  }

  /// Bulk Ingest a batch of KnowledgeDocuments into GARUDA.
  Future<KnowledgeIngestionReport> ingestBatch(
    List<KnowledgeDocument> documents, {
    String packageName = 'national_bulk_ingestion',
    KnowledgeEditorialStatus autoPublicationStatus = KnowledgeEditorialStatus.draft,
  }) async {
    final session = KnowledgeImportSession.create(packageName: packageName);
    final stopwatch = Stopwatch()..start();
    final results = <KnowledgeImportResult>[];

    for (final doc in documents) {
      final docResult = await ingestSingle(
        doc,
        session: session,
        autoPublicationStatus: autoPublicationStatus,
      );
      results.add(docResult);
    }

    stopwatch.stop();
    final totalDurationMs = stopwatch.elapsedMicroseconds / 1000.0;

    return KnowledgeIngestionReport.generate(
      session: session,
      results: results,
      totalDurationMs: totalDurationMs,
    );
  }

  /// Ingest a single KnowledgeDocument through the 11-stage pipeline.
  Future<KnowledgeImportResult> ingestSingle(
    KnowledgeDocument document, {
    KnowledgeImportSession? session,
    KnowledgeEditorialStatus autoPublicationStatus = KnowledgeEditorialStatus.draft,
  }) async {
    final stopwatch = Stopwatch()..start();
    final warnings = <String>[];

    try {
      // Stage 1: Preprocessing & Normalization
      final procRes = processor.process(document);
      if (!procRes.isSuccess) {
        return KnowledgeImportResult.failure(
          documentId: document.documentId,
          message: procRes.errorMessage ?? 'Document preprocessing failed',
          durationMs: stopwatch.elapsedMicroseconds / 1000.0,
        );
      }
      final processedDoc = procRes.processedDocument;

      // Stage 2: Document Validation
      final valRes = await validator.validate(processedDoc);
      if (!valRes.isValid) {
        final criticalMsg = valRes.issues
            .where((i) => i.isCritical)
            .map((i) => i.toString())
            .join('; ');
        if (criticalMsg.isNotEmpty) {
          return KnowledgeImportResult.failure(
            documentId: document.documentId,
            message: 'Validation failed: $criticalMsg',
            warnings: valRes.issues.where((i) => !i.isCritical).map((i) => i.toString()).toList(),
            durationMs: stopwatch.elapsedMicroseconds / 1000.0,
          );
        } else {
          warnings.addAll(valRes.issues.map((i) => i.toString()));
        }
      }

      // Stage 3: Resolve Source Adapter
      final adapter = resolveAdapter(processedDoc);

      // Stage 4: Parse Document
      final parseRes = adapter.parser.parse(processedDoc);
      if (!parseRes.isSuccess) {
        return KnowledgeImportResult.failure(
          documentId: document.documentId,
          message: 'Parser error: ${parseRes.errorMessage}',
          durationMs: stopwatch.elapsedMicroseconds / 1000.0,
        );
      }

      // Stage 5: Extract Metadata, Content, Evidence & Concepts
      final extractionRes = adapter.extractor.extract(
        document: processedDoc,
        parseResult: parseRes,
      );

      // Stage 6: Map to Knowledge Object & Relationships
      final mappingRes = adapter.mapper.map(
        document: processedDoc,
        extraction: extractionRes,
      );
      final kObject = mappingRes.knowledgeObject;

      // Stage 7: Register through 12-Stage Registration Pipeline
      final pipelineRes = await registrationPipeline.process(
        kObject,
        packageName: session?.packageName ?? 'ingestion_service',
      );

      if (!pipelineRes.isSuccess) {
        return KnowledgeImportResult.failure(
          documentId: document.documentId,
          message: 'Registration pipeline failed: ${pipelineRes.errorMessage}',
          warnings: warnings,
          durationMs: stopwatch.elapsedMicroseconds / 1000.0,
        );
      }

      // Stage 8: Update Index Manager
      indexManager.indexObject(kObject);

      // Stage 9: Register Document with Duplicate Validator Store
      duplicateValidator.registerDocument(processedDoc);

      // Stage 10: Editorial Queue & Publication Service
      publicationService.queueForReview(
        kObject,
        initialStatus: autoPublicationStatus,
      );
      if (autoPublicationStatus != KnowledgeEditorialStatus.draft) {
        await publicationService.transitionStatus(
          objectId: kObject.id.value,
          newStatus: autoPublicationStatus,
          reviewerNotes: 'Auto-published during ingestion',
        );
      }

      stopwatch.stop();
      final durationMs = stopwatch.elapsedMicroseconds / 1000.0;

      return KnowledgeImportResult.success(
        documentId: document.documentId,
        object: kObject,
        relationships: mappingRes.relationships,
        warnings: warnings,
        durationMs: durationMs,
      );
    } catch (e) {
      stopwatch.stop();
      return KnowledgeImportResult.failure(
        documentId: document.documentId,
        message: 'Unhandled exception during ingestion: $e',
        warnings: warnings,
        durationMs: stopwatch.elapsedMicroseconds / 1000.0,
      );
    }
  }
}
