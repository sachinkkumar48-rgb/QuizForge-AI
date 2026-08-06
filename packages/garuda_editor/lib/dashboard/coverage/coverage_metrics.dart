import 'coverage_filter.dart';

/// Section 1: National Overview Metrics
class NationalOverviewMetrics {
  final int totalQuestions;
  final int verifiedQuestions;
  final int publishedQuestions;
  final int goldQuestions;
  final int silverQuestions;
  final int bronzeQuestions;
  final int draftQuestions;
  final double coveragePercentage;

  const NationalOverviewMetrics({
    required this.totalQuestions,
    required this.verifiedQuestions,
    required this.publishedQuestions,
    required this.goldQuestions,
    required this.silverQuestions,
    required this.bronzeQuestions,
    required this.draftQuestions,
    required this.coveragePercentage,
  });

  Map<String, dynamic> toJson() => {
        'totalQuestions': totalQuestions,
        'verifiedQuestions': verifiedQuestions,
        'publishedQuestions': publishedQuestions,
        'goldQuestions': goldQuestions,
        'silverQuestions': silverQuestions,
        'bronzeQuestions': bronzeQuestions,
        'draftQuestions': draftQuestions,
        'coveragePercentage': coveragePercentage,
      };
}

/// Section 2: Exam Coverage Item
class ExamCoverageItem {
  final String examId;
  final String examName;
  final String code;
  final int yearsCovered;
  final int yearsMissing;
  final int questionsImported;
  final int questionsVerified;
  final int questionsPublished;
  final double coveragePercentage;

  const ExamCoverageItem({
    required this.examId,
    required this.examName,
    required this.code,
    required this.yearsCovered,
    required this.yearsMissing,
    required this.questionsImported,
    required this.questionsVerified,
    required this.questionsPublished,
    required this.coveragePercentage,
  });

  Map<String, dynamic> toJson() => {
        'examId': examId,
        'examName': examName,
        'code': code,
        'yearsCovered': yearsCovered,
        'yearsMissing': yearsMissing,
        'questionsImported': questionsImported,
        'questionsVerified': questionsVerified,
        'questionsPublished': questionsPublished,
        'coveragePercentage': coveragePercentage,
      };
}

/// Section 3: Subject Coverage Item
class SubjectCoverageItem {
  final String subject;
  final int imported;
  final int verified;
  final int mapped;
  final int published;
  final int remaining;
  final double coveragePercentage;

  const SubjectCoverageItem({
    required this.subject,
    required this.imported,
    required this.verified,
    required this.mapped,
    required this.published,
    required this.remaining,
    required this.coveragePercentage,
  });

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'imported': imported,
        'verified': verified,
        'mapped': mapped,
        'published': published,
        'remaining': remaining,
        'coveragePercentage': coveragePercentage,
      };
}

/// Section 4: Topic Coverage Item
class TopicCoverageItem {
  final String subject;
  final String topic;
  final int questions;
  final double coveragePercentage;
  final int missing;

  const TopicCoverageItem({
    required this.subject,
    required this.topic,
    required this.questions,
    required this.coveragePercentage,
    required this.missing,
  });

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'topic': topic,
        'questions': questions,
        'coveragePercentage': coveragePercentage,
        'missing': missing,
      };
}

/// Section 5: Year Matrix Status
enum YearCoverageStatus {
  missing,
  partial,
  complete,
}

extension YearCoverageStatusX on YearCoverageStatus {
  String get label {
    switch (this) {
      case YearCoverageStatus.missing:
        return 'Missing';
      case YearCoverageStatus.partial:
        return 'Partial';
      case YearCoverageStatus.complete:
        return 'Complete';
    }
  }
}

class YearMatrixItem {
  final int year;
  final YearCoverageStatus status;
  final int totalQuestions;
  final int verifiedQuestions;

  const YearMatrixItem({
    required this.year,
    required this.status,
    required this.totalQuestions,
    required this.verifiedQuestions,
  });

  Map<String, dynamic> toJson() => {
        'year': year,
        'status': status.name,
        'totalQuestions': totalQuestions,
        'verifiedQuestions': verifiedQuestions,
      };
}

/// Section 6: Editorial Queue Metrics
class EditorialQueueMetrics {
  final int pendingVerification;
  final int pendingMapping;
  final int pendingReview;
  final int pendingPublication;
  final int rejected;
  final int flagged;

  const EditorialQueueMetrics({
    required this.pendingVerification,
    required this.pendingMapping,
    required this.pendingReview,
    required this.pendingPublication,
    required this.rejected,
    required this.flagged,
  });

  Map<String, dynamic> toJson() => {
        'pendingVerification': pendingVerification,
        'pendingMapping': pendingMapping,
        'pendingReview': pendingReview,
        'pendingPublication': pendingPublication,
        'rejected': rejected,
        'flagged': flagged,
      };
}

/// Section 7: Knowledge Graph Status Metrics
class KnowledgeGraphMetrics {
  final int questionsLinked;
  final int articlesLinked;
  final int actsLinked;
  final int casesLinked;
  final int committeesLinked;
  final int reportsLinked;
  final int currentAffairsLinked;
  final int knowledgeObjectsLinked;
  final int conceptsLinked;
  final int microConceptsLinked;

  const KnowledgeGraphMetrics({
    required this.questionsLinked,
    required this.articlesLinked,
    required this.actsLinked,
    required this.casesLinked,
    required this.committeesLinked,
    required this.reportsLinked,
    required this.currentAffairsLinked,
    required this.knowledgeObjectsLinked,
    required this.conceptsLinked,
    required this.microConceptsLinked,
  });

  Map<String, dynamic> toJson() => {
        'questionsLinked': questionsLinked,
        'articlesLinked': articlesLinked,
        'actsLinked': actsLinked,
        'casesLinked': casesLinked,
        'committeesLinked': committeesLinked,
        'reportsLinked': reportsLinked,
        'currentAffairsLinked': currentAffairsLinked,
        'knowledgeObjectsLinked': knowledgeObjectsLinked,
        'conceptsLinked': conceptsLinked,
        'microConceptsLinked': microConceptsLinked,
      };
}

/// Section 8: Quality Dashboard Metrics
class QualityDashboardMetrics {
  final double trapAnalysisPercentage;
  final double learningObjectivesPercentage;
  final double conceptMappingPercentage;
  final double editorialReviewPercentage;
  final double knowledgeLinksPercentage;
  final double evidenceLinksPercentage;

  const QualityDashboardMetrics({
    required this.trapAnalysisPercentage,
    required this.learningObjectivesPercentage,
    required this.conceptMappingPercentage,
    required this.editorialReviewPercentage,
    required this.knowledgeLinksPercentage,
    required this.evidenceLinksPercentage,
  });

  Map<String, dynamic> toJson() => {
        'trapAnalysisPercentage': trapAnalysisPercentage,
        'learningObjectivesPercentage': learningObjectivesPercentage,
        'conceptMappingPercentage': conceptMappingPercentage,
        'editorialReviewPercentage': editorialReviewPercentage,
        'knowledgeLinksPercentage': knowledgeLinksPercentage,
        'evidenceLinksPercentage': evidenceLinksPercentage,
      };
}

/// Complete Aggregated Coverage Report for GARUDA
class CoverageReport {
  final CoverageFilter appliedFilter;
  final DateTime generatedAt;
  final NationalOverviewMetrics nationalOverview;
  final List<ExamCoverageItem> examCoverage;
  final List<SubjectCoverageItem> subjectCoverage;
  final List<TopicCoverageItem> topicCoverage;
  final List<YearMatrixItem> yearMatrix;
  final EditorialQueueMetrics editorialQueue;
  final KnowledgeGraphMetrics knowledgeGraph;
  final QualityDashboardMetrics qualityDashboard;

  const CoverageReport({
    required this.appliedFilter,
    required this.generatedAt,
    required this.nationalOverview,
    required this.examCoverage,
    required this.subjectCoverage,
    required this.topicCoverage,
    required this.yearMatrix,
    required this.editorialQueue,
    required this.knowledgeGraph,
    required this.qualityDashboard,
  });

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'nationalOverview': nationalOverview.toJson(),
        'examCoverage': examCoverage.map((e) => e.toJson()).toList(),
        'subjectCoverage': subjectCoverage.map((s) => s.toJson()).toList(),
        'topicCoverage': topicCoverage.map((t) => t.toJson()).toList(),
        'yearMatrix': yearMatrix.map((y) => y.toJson()).toList(),
        'editorialQueue': editorialQueue.toJson(),
        'knowledgeGraph': knowledgeGraph.toJson(),
        'qualityDashboard': qualityDashboard.toJson(),
      };
}
