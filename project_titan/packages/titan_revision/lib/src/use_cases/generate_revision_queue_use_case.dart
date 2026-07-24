import 'package:titan_analytics/titan_analytics.dart';
import '../models/revision_models.dart';
import '../repository/revision_repository.dart';

/// Clean Architecture Use Case for generating personalized, prioritized study revision queues.
class GenerateRevisionQueueUseCase {
  final RevisionRepository _repository;

  const GenerateRevisionQueueUseCase(this._repository);

  /// Generates a personalized revision queue, optionally filtering by subject category or overdue items.
  ///
  /// Can incorporate [ResultAnalytics] from a completed quiz session to ingest weak topics into the queue.
  Future<RevisionQueue> execute({
    String? category,
    bool? overdueOnly,
    ResultAnalytics? quizAnalytics,
  }) async {
    if (quizAnalytics != null) {
      // Ingest weak topics from Quiz Result Analytics into revision queue
      for (final topicPerf in quizAnalytics.topicPerformances) {
        if (topicPerf.accuracy < 70.0) {
          await _repository.addTopicToRevision(
            topic: topicPerf.topic,
            subtopic:
                'Quiz Accuracy: ${topicPerf.accuracy.toStringAsFixed(0)}%',
            priority: topicPerf.accuracy < 50.0 ? 'Urgent' : 'High',
            sourceTag: 'Quiz Mistake',
          );
        }
      }
    }

    return _repository.getPersonalizedRevisionQueue(
      category: category,
      overdueOnly: overdueOnly,
    );
  }

  /// Retrieves overall topic mastery scores.
  Future<Map<String, double>> getTopicMastery() {
    return _repository.getTopicMasteryOverview();
  }
}
