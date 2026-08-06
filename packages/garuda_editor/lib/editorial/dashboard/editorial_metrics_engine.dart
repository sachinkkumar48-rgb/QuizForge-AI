library;

import '../../domain/entities/editorial_status.dart';
import '../../domain/entities/knowledge_object.dart';
import '../quality/quality_score_engine.dart';
import '../review/editorial_review_service.dart';

class EditorialDashboardMetrics {
  final int totalObjectsCount;
  final int pendingReviewsCount;
  final Map<String, int> reviewerWorkload;
  final double approvalRate; // 0.0 to 100.0 %
  final double publicationRate; // 0.0 to 100.0 %
  final Map<String, int> qualityDistribution; // e.g. "90-100": count, "80-89": count, etc.
  final double averageReviewTimeHours;
  final int rejectedObjectsCount;
  final double coverageProgressPercentage;

  const EditorialDashboardMetrics({
    required this.totalObjectsCount,
    required this.pendingReviewsCount,
    required this.reviewerWorkload,
    required this.approvalRate,
    required this.publicationRate,
    required this.qualityDistribution,
    required this.averageReviewTimeHours,
    required this.rejectedObjectsCount,
    required this.coverageProgressPercentage,
  });
}

class EditorialMetricsEngine {
  static EditorialDashboardMetrics calculateMetrics({
    required List<KnowledgeObject> objects,
    required Map<String, int> reviewerWorkloads,
    required EditorialReviewService reviewService,
  }) {
    final total = objects.length;
    if (total == 0) {
      return const EditorialDashboardMetrics(
        totalObjectsCount: 0,
        pendingReviewsCount: 0,
        reviewerWorkload: {},
        approvalRate: 0.0,
        publicationRate: 0.0,
        qualityDistribution: {
          '90-100': 0,
          '80-89': 0,
          '70-79': 0,
          'Below 70': 0,
        },
        averageReviewTimeHours: 0.0,
        rejectedObjectsCount: 0,
        coverageProgressPercentage: 0.0,
      );
    }

    int pending = 0;
    int approved = 0;
    int published = 0;
    int rejected = 0;

    final Map<String, int> qualityDist = {
      '90-100': 0,
      '80-89': 0,
      '70-79': 0,
      'Below 70': 0,
    };

    double totalReviewHours = 0.0;
    int reviewCount = 0;

    for (final obj in objects) {
      if (obj.status == EditorialStatus.pendingReview ||
          obj.status == EditorialStatus.inReview ||
          obj.status == EditorialStatus.reviewPending) {
        pending++;
      }

      if (obj.status == EditorialStatus.approved) approved++;
      if (obj.status == EditorialStatus.published) published++;
      if (obj.status == EditorialStatus.rejected) rejected++;

      final score = QualityScoreEngine.calculateScore(obj).totalScore;
      if (score >= 90.0) {
        qualityDist['90-100'] = (qualityDist['90-100'] ?? 0) + 1;
      } else if (score >= 80.0) {
        qualityDist['80-89'] = (qualityDist['80-89'] ?? 0) + 1;
      } else if (score >= 70.0) {
        qualityDist['70-79'] = (qualityDist['70-79'] ?? 0) + 1;
      } else {
        qualityDist['Below 70'] = (qualityDist['Below 70'] ?? 0) + 1;
      }

      final reviews = reviewService.getReviews(obj.id);
      if (reviews.isNotEmpty) {
        final first = reviews.first.timestamp;
        final last = reviews.last.timestamp;
        final hours = last.difference(first).inMinutes / 60.0;
        totalReviewHours += hours;
        reviewCount++;
      }
    }

    final approvalRate = ((approved + published) / total) * 100.0;
    final publicationRate = (published / total) * 100.0;
    final avgReviewTime = reviewCount > 0 ? (totalReviewHours / reviewCount) : 1.5;
    final coverageProgress = (published / (total > 0 ? total : 1)) * 100.0;

    return EditorialDashboardMetrics(
      totalObjectsCount: total,
      pendingReviewsCount: pending,
      reviewerWorkload: Map.unmodifiable(reviewerWorkloads),
      approvalRate: approvalRate,
      publicationRate: publicationRate,
      qualityDistribution: Map.unmodifiable(qualityDist),
      averageReviewTimeHours: avgReviewTime,
      rejectedObjectsCount: rejected,
      coverageProgressPercentage: coverageProgress,
    );
  }
}
