import 'package:meta/meta.dart';
import '../domain/entities/knowledge_object.dart';
import '../domain/enums/knowledge_object_type.dart';

/// Strongly typed multi-criteria filter specification for Knowledge Object queries.
@immutable
class KnowledgeFilter {
  final KnowledgeObjectType? type;
  final String? package;
  final String? subject;
  final String? topic;
  final int? year;
  final String? exam;
  final String? article;
  final String? act;
  final String? caseName;
  final String? doctrine;
  final String? editorialStatus;
  final bool? hasEvidence;
  final String? version;
  final String? language;

  const KnowledgeFilter({
    this.type,
    this.package,
    this.subject,
    this.topic,
    this.year,
    this.exam,
    this.article,
    this.act,
    this.caseName,
    this.doctrine,
    this.editorialStatus,
    this.hasEvidence,
    this.version,
    this.language,
  });

  /// Evaluates whether a KnowledgeObject satisfies all filter constraints.
  bool matches(KnowledgeObject object) {
    if (type != null && object.type != type) return false;

    if (package != null &&
        object.metadata.packageOrigin.toLowerCase() != package!.toLowerCase()) {
      return false;
    }

    if (subject != null) {
      final objSubject =
          object.metadata.customAttributes['subject'] ?? object.category?.name;
      if (objSubject == null ||
          !objSubject.toString().toLowerCase().contains(subject!.toLowerCase())) {
        return false;
      }
    }

    if (topic != null) {
      final objTopic = object.metadata.customAttributes['topic'];
      if (objTopic == null ||
          !objTopic.toString().toLowerCase().contains(topic!.toLowerCase())) {
        return false;
      }
    }

    if (year != null) {
      final objYear = object.metadata.customAttributes['year'];
      if (objYear == null || objYear != year) {
        return false;
      }
    }

    if (exam != null) {
      final objExam = object.metadata.customAttributes['exam'];
      if (objExam == null ||
          !objExam.toString().toLowerCase().contains(exam!.toLowerCase())) {
        return false;
      }
    }

    if (article != null) {
      final objArt = object.metadata.customAttributes['article_number'];
      if (objArt == null ||
          !objArt.toString().toLowerCase().contains(article!.toLowerCase())) {
        return false;
      }
    }

    if (act != null) {
      final objAct = object.metadata.customAttributes['act'];
      if (objAct == null ||
          !objAct.toString().toLowerCase().contains(act!.toLowerCase())) {
        return false;
      }
    }

    if (caseName != null) {
      final objCase = object.metadata.customAttributes['case_name'];
      if (objCase == null ||
          !objCase.toString().toLowerCase().contains(caseName!.toLowerCase())) {
        return false;
      }
    }

    if (doctrine != null) {
      final objDoc = object.metadata.customAttributes['doctrine'];
      if (objDoc == null ||
          !objDoc.toString().toLowerCase().contains(doctrine!.toLowerCase())) {
        return false;
      }
    }

    if (editorialStatus != null) {
      final status =
          object.metadata.customAttributes['editorial_status'] ?? 'published';
      if (status.toString().toLowerCase() != editorialStatus!.toLowerCase()) {
        return false;
      }
    }

    if (hasEvidence != null) {
      final containsEvidence = object.evidenceReferences.isNotEmpty;
      if (containsEvidence != hasEvidence) return false;
    }

    if (version != null &&
        object.currentVersion.versionString.toLowerCase() !=
            version!.toLowerCase()) {
      return false;
    }

    if (language != null) {
      final lang = object.metadata.customAttributes['language'] ?? 'en';
      if (lang.toString().toLowerCase() != language!.toLowerCase()) {
        return false;
      }
    }

    return true;
  }
}
