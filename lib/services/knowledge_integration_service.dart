import 'package:flutter/foundation.dart';
import 'package:knowledge_engine/knowledge_engine.dart';

/// Integration service bridging QuizForge AI content ingestion with the
/// TITAN Knowledge Intelligence Engine (KIE).
class KnowledgeIntegrationService {
  final KnowledgeIngestionPipeline _pipeline;
  final KnowledgeRepository? _repository;

  /// Constructs a [KnowledgeIntegrationService].
  ///
  /// Accepts an optional [KnowledgeIngestionPipeline], [KnowledgeRepository],
  /// or concrete [RepositoryCoordinator] for persisting [KnowledgeObject] entities.
  KnowledgeIntegrationService({
    KnowledgeIngestionPipeline? pipeline,
    KnowledgeRepository? repository,
    RepositoryCoordinator? repositoryCoordinator,
  })  : _pipeline = pipeline ?? KnowledgeIngestionPipeline(),
        _repository = repositoryCoordinator ?? repository;

  /// Ingests raw extracted PDF text into the Knowledge Intelligence Engine.
  ///
  /// Normalizes, chunks, and transforms [pdfText] into canonical [KnowledgeObject]
  /// entities, persists them using [RepositoryCoordinator] / [KnowledgeRepository]
  /// (if available), and returns the detailed [PipelineResult].
  Future<PipelineResult> ingestPdf({
    required String pdfText,
    required String pdfTitle,
    String pdfSourcePath = '',
    Map<String, dynamic> metadata = const {},
  }) async {
    debugPrint("KIE Integration: Starting ingestion for '$pdfTitle'...");

    final result = await _pipeline.process(
      rawText: pdfText,
      title: pdfTitle,
      type: KnowledgeType.pdf,
      source: pdfSourcePath,
      metadata: {
        'importedVia': 'QuizForge_PDF_Importer',
        ...metadata,
      },
    );

    debugPrint(
      "KIE Integration: Ingestion complete. Generated ${result.objects.length} KnowledgeObjects in ${result.processingDuration.inMilliseconds}ms.",
    );

    // Persist objects using RepositoryCoordinator if configured
    if (_repository != null && result.objects.isNotEmpty) {
      try {
        for (final object in result.objects) {
          await _repository!.save(object);
        }
        debugPrint(
          "KIE Integration: Successfully persisted ${result.objects.length} KnowledgeObjects to RepositoryCoordinator.",
        );
      } catch (e) {
        debugPrint(
          "KIE Integration: Warning - Failed to persist to RepositoryCoordinator: $e",
        );
      }
    }

    return result;
  }
}
