library;

import '../domain/entities/editorial_status.dart';
import '../domain/entities/knowledge_object.dart';

class EditorialSearchQuery {
  final EditorialStatus? status;
  final String? reviewerId;
  final String? package;
  final String? knowledgeType;
  final int? minPriority;
  final double? minQualityScore;
  final String? keyword;

  const EditorialSearchQuery({
    this.status,
    this.reviewerId,
    this.package,
    this.knowledgeType,
    this.minPriority,
    this.minQualityScore,
    this.keyword,
  });
}

class EditorialSearchEngine {
  static List<KnowledgeObject> search({
    required List<KnowledgeObject> objects,
    required EditorialSearchQuery query,
    Map<String, String>? reviewerAssignments,
    Map<String, double>? qualityScores,
  }) {
    return objects.where((obj) {
      if (query.status != null && obj.status != query.status) {
        return false;
      }

      if (query.reviewerId != null && reviewerAssignments != null) {
        final assigned = reviewerAssignments[obj.id];
        if (assigned != query.reviewerId) return false;
      }

      if (query.package != null && obj.package.toLowerCase() != query.package!.toLowerCase()) {
        return false;
      }

      if (query.knowledgeType != null &&
          obj.knowledgeType.toLowerCase() != query.knowledgeType!.toLowerCase()) {
        return false;
      }

      if (query.minQualityScore != null && qualityScores != null) {
        final score = qualityScores[obj.id] ?? 0.0;
        if (score < query.minQualityScore!) return false;
      }

      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final kw = query.keyword!.toLowerCase();
        final match = obj.title.toLowerCase().contains(kw) ||
            obj.content.toLowerCase().contains(kw) ||
            obj.subject.toLowerCase().contains(kw) ||
            obj.topic.toLowerCase().contains(kw);
        if (!match) return false;
      }

      return true;
    }).toList();
  }
}
