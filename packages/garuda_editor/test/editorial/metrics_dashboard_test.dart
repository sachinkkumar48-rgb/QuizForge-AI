import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart' hide CoverageReport;

void main() {
  group('EditorialMetricsEngine & Dashboard Metrics Tests', () {
    late EditorialReviewService reviewService;
    late List<KnowledgeObject> sampleObjects;

    setUp(() {
      reviewService = EditorialReviewService();
      sampleObjects = [
        KnowledgeObject(
          id: 'ko_1',
          title: 'Article 14 Right to Equality',
          content: 'Content text 1.',
          subject: 'Polity',
          topic: 'Fundamental Rights',
          officialSource: 'PIB Release',
          evidenceIds: const ['ev_1'],
          status: EditorialStatus.published,
          isVerified: true,
        ),
        KnowledgeObject(
          id: 'ko_2',
          title: 'Article 19 Freedom of Speech',
          content: 'Content text 2.',
          subject: 'Polity',
          topic: 'Fundamental Rights',
          officialSource: 'PIB Release',
          evidenceIds: const ['ev_2'],
          status: EditorialStatus.approved,
          isVerified: true,
        ),
        KnowledgeObject(
          id: 'ko_3',
          title: 'Draft Economic Reforms',
          content: 'Content text 3.',
          subject: 'Economy',
          topic: 'Reforms',
          officialSource: '',
          status: EditorialStatus.pendingReview,
        ),
      ];
    });

    test('EditorialMetricsEngine calculates metrics accurately', () {
      final metrics = EditorialMetricsEngine.calculateMetrics(
        objects: sampleObjects,
        reviewerWorkloads: {'rev_1': 2, 'rev_2': 1},
        reviewService: reviewService,
      );

      expect(metrics.totalObjectsCount, equals(3));
      expect(metrics.pendingReviewsCount, equals(1));
      expect(metrics.approvalRate, closeTo(66.66, 0.5));
      expect(metrics.publicationRate, closeTo(33.33, 0.5));
      expect(metrics.reviewerWorkload['rev_1'], equals(2));
    });
  });
}
