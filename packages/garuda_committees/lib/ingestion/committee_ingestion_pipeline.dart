library;

import '../domain/entities/committee_knowledge_object.dart';

import '../repositories/committee_repository.dart';
import '../services/committee_editorial_service.dart';
import '../validators/committee_validator.dart';

class CommitteeIngestionResult {
  final int totalProcessed;
  final int totalValidated;
  final List<CommitteeKnowledgeObject> objects;
  final List<CommitteeValidationReport> validationReports;

  const CommitteeIngestionResult({
    required this.totalProcessed,
    required this.totalValidated,
    required this.objects,
    required this.validationReports,
  });
}

class CommitteeIngestionPipeline {
  final CommitteeRepository repository;
  final CommitteeEditorialService editorialService;

  CommitteeIngestionPipeline({
    required this.repository,
    CommitteeEditorialService? editorialService,
  }) : editorialService = editorialService ?? CommitteeEditorialService();

  /// Process raw Committee JSON maps through full ingestion pipeline.
  Future<CommitteeIngestionResult> ingestRawPayloads(
      List<Map<String, dynamic>> rawPayloads) async {
    final objects = <CommitteeKnowledgeObject>[];
    final reports = <CommitteeValidationReport>[];

    final existing = await repository.getAllCommittees();

    for (final payload in rawPayloads) {
      final obj = CommitteeKnowledgeObject.fromJson(payload);

      final valReport = CommitteeValidator.validate(
        obj,
        existingCommittees: [...existing, ...objects],
      );
      reports.add(valReport);

      editorialService.submitToEditorialWorkflow(obj);

      if (valReport.isValid) {
        objects.add(obj);
        await repository.saveCommittee(obj);
      }
    }

    return CommitteeIngestionResult(
      totalProcessed: rawPayloads.length,
      totalValidated: objects.length,
      objects: objects,
      validationReports: reports,
    );
  }
}
