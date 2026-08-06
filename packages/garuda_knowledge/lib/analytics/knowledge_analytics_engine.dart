import '../domain/enums/knowledge_object_type.dart';
import '../repositories/knowledge_repository.dart';
import '../validators/broken_reference_validator.dart';

class KnowledgeAnalyticsReport {
  final int totalObjects;
  final Map<KnowledgeObjectType, int> typeDistribution;
  final int totalRelationships;
  final int orphanObjectsCount;
  final int evidenceBackedCount;
  final double evidenceCoveragePercentage;
  final int brokenReferencesCount;
  final double averageVersionsPerObject;

  const KnowledgeAnalyticsReport({
    required this.totalObjects,
    required this.typeDistribution,
    required this.totalRelationships,
    required this.orphanObjectsCount,
    required this.evidenceBackedCount,
    required this.evidenceCoveragePercentage,
    required this.brokenReferencesCount,
    required this.averageVersionsPerObject,
  });

  Map<String, dynamic> toJson() => {
        'totalObjects': totalObjects,
        'typeDistribution':
            typeDistribution.map((k, v) => MapEntry(k.name, v)),
        'totalRelationships': totalRelationships,
        'orphanObjectsCount': orphanObjectsCount,
        'evidenceBackedCount': evidenceBackedCount,
        'evidenceCoveragePercentage': evidenceCoveragePercentage,
        'brokenReferencesCount': brokenReferencesCount,
        'averageVersionsPerObject': averageVersionsPerObject,
      };
}

class KnowledgeAnalyticsEngine {
  final KnowledgeRepository _repository;
  final BrokenReferenceValidator _brokenRefValidator = BrokenReferenceValidator();

  KnowledgeAnalyticsEngine(this._repository);

  Future<KnowledgeAnalyticsReport> generateReport() async {
    final objects = await _repository.bulkExport();
    final totalObjects = objects.length;

    final typeDist = <KnowledgeObjectType, int>{};
    int totalRels = 0;
    int orphanCount = 0;
    int evidenceCount = 0;
    int totalVersions = 0;

    final allTargetIds = <String>{};
    for (final obj in objects) {
      typeDist[obj.type] = (typeDist[obj.type] ?? 0) + 1;
      totalRels += obj.relationships.length;
      totalVersions += obj.versionHistory.length + 1;

      if (obj.evidenceReferences.isNotEmpty ||
          obj.citations.isNotEmpty ||
          obj.sources.isNotEmpty) {
        evidenceCount++;
      }

      for (final rel in obj.relationships) {
        allTargetIds.add(rel.targetId.value);
        allTargetIds.add(rel.sourceId.value);
      }
    }

    for (final obj in objects) {
      if (obj.relationships.isEmpty && !allTargetIds.contains(obj.id.value)) {
        orphanCount++;
      }
    }

    final brokenRes = _brokenRefValidator.validate(objects);
    final brokenCount = brokenRes.issues.length;

    final coveragePct =
        totalObjects > 0 ? (evidenceCount / totalObjects) * 100.0 : 0.0;
    final avgVersions =
        totalObjects > 0 ? totalVersions / totalObjects : 0.0;

    return KnowledgeAnalyticsReport(
      totalObjects: totalObjects,
      typeDistribution: typeDist,
      totalRelationships: totalRels,
      orphanObjectsCount: orphanCount,
      evidenceBackedCount: evidenceCount,
      evidenceCoveragePercentage: coveragePct,
      brokenReferencesCount: brokenCount,
      averageVersionsPerObject: avgVersions,
    );
  }
}
