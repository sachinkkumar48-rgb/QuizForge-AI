import '../engine/spaced_repetition_engine.dart';
import '../models/revision_models.dart';
import 'revision_repository.dart';

/// Concrete implementation of [RevisionRepository] orchestrating spaced repetition
/// schedules and personalized revision queues.
class RevisionRepositoryImpl implements RevisionRepository {
  final Map<String, RevisionItem> _items = {};
  final SpacedRepetitionEngine _engine;

  RevisionRepositoryImpl({
    List<RevisionItem>? initialItems,
    SpacedRepetitionEngine engine = const SpacedRepetitionEngine(),
  }) : _engine = engine {
    if (initialItems != null && initialItems.isNotEmpty) {
      for (final item in initialItems) {
        _items[item.id] = item;
      }
    } else {
      _seedDefaultRevisionItems();
    }
  }

  void _seedDefaultRevisionItems() {
    final now = DateTime.now();

    final item1 = RevisionItem(
      id: 'rev_polity_01',
      topic: 'Indian Polity',
      subtopic: 'Fundamental Rights & Writs (Art. 32)',
      questionId: 'q_polity_32',
      questionText:
          'Which writ is issued to safeguard personal liberty against illegal detention?',
      easeFactor: 2.3,
      intervalDays: 1,
      repetitions: 1,
      nextReviewDate: now.subtract(const Duration(hours: 4)), // Overdue
      lastReviewedAt: now.subtract(const Duration(days: 1)),
      qualityRating: 2,
      masteryLevel: 'Novice',
      priority: 'Urgent',
      sourceTag: 'Quiz Mistake',
    );

    final item2 = RevisionItem(
      id: 'rev_economy_01',
      topic: 'Indian Economy',
      subtopic: 'RBI Monetary Policy & Repo Rate',
      questionId: 'q_econ_repo',
      questionText:
          'What is the impact of raising Repo Rate on market liquidity and inflation?',
      easeFactor: 2.5,
      intervalDays: 2,
      repetitions: 2,
      nextReviewDate: now.add(const Duration(hours: 2)), // Due today
      lastReviewedAt: now.subtract(const Duration(days: 2)),
      qualityRating: 4,
      masteryLevel: 'Learning',
      priority: 'High',
      sourceTag: 'AI Mentor',
    );

    final item3 = RevisionItem(
      id: 'rev_history_01',
      topic: 'Modern History',
      subtopic: 'Non-Cooperation Movement (1920)',
      questionId: 'q_hist_1920',
      questionText:
          'Analyze the significance of the Chauri Chaura incident on the NCM suspension.',
      easeFactor: 2.6,
      intervalDays: 6,
      repetitions: 3,
      nextReviewDate: now.add(const Duration(days: 3)),
      lastReviewedAt: now.subtract(const Duration(days: 3)),
      qualityRating: 5,
      masteryLevel: 'Proficient',
      priority: 'Medium',
      sourceTag: 'PYQ High Yield',
    );

    final item4 = RevisionItem(
      id: 'rev_env_01',
      topic: 'Environment',
      subtopic: 'Ramsar Wetlands & Biodiversity Hotspots',
      questionId: 'q_env_ramsar',
      questionText:
          'Which wetland site in Rajasthan is designated under the Montreux Record?',
      easeFactor: 2.7,
      intervalDays: 14,
      repetitions: 4,
      nextReviewDate: now.add(const Duration(days: 10)),
      lastReviewedAt: now.subtract(const Duration(days: 4)),
      qualityRating: 5,
      masteryLevel: 'Master',
      priority: 'Low',
      sourceTag: 'User Saved',
    );

    _items[item1.id] = item1;
    _items[item2.id] = item2;
    _items[item3.id] = item3;
    _items[item4.id] = item4;
  }

  @override
  Future<RevisionQueue> getPersonalizedRevisionQueue({
    String? category,
    bool? overdueOnly,
  }) async {
    var itemsList = _items.values.toList();

    if (category != null && category.trim().isNotEmpty && category != 'All') {
      itemsList = itemsList
          .where((i) => i.topic.toLowerCase() == category.toLowerCase())
          .toList();
    }

    if (overdueOnly == true) {
      itemsList = itemsList.where((i) => i.isOverdue).toList();
    }

    // Sort by Urgency Priority (Urgent > High > Medium > Low) then nextReviewDate
    itemsList.sort((a, b) {
      final pOrder = {'Urgent': 0, 'High': 1, 'Medium': 2, 'Low': 3};
      final pA = pOrder[a.priority] ?? 4;
      final pB = pOrder[b.priority] ?? 4;
      if (pA != pB) return pA.compareTo(pB);
      return a.nextReviewDate.compareTo(b.nextReviewDate);
    });

    final now = DateTime.now();
    final overdueCount = itemsList.where((i) => i.isOverdue).length;
    final dueTodayCount =
        itemsList.where((i) => i.isDueToday || i.isOverdue).length;
    final masteredCount =
        itemsList.where((i) => i.masteryLevel == 'Master').length;

    final summary = overdueCount > 0
        ? 'You have $overdueCount overdue concept${overdueCount == 1 ? "" : "s"} requiring immediate active recall.'
        : 'Great job! Your active recall queue is up to date.';

    return RevisionQueue(
      id: 'queue_${now.millisecondsSinceEpoch}',
      userId: 'user_titan',
      generatedAt: now,
      items: itemsList,
      dueTodayCount: dueTodayCount,
      overdueCount: overdueCount,
      masteredCount: masteredCount,
      summary: summary,
    );
  }

  @override
  Future<RevisionItem> recordRevisionAttempt(
    String itemId,
    int qualityRating,
  ) async {
    final item = _items[itemId];
    if (item == null) {
      throw Exception('Revision item [$itemId] not found.');
    }

    final schedule = _engine.calculateNextSchedule(item, qualityRating);
    final updated = schedule.updatedItem;
    _items[itemId] = updated;
    return updated;
  }

  @override
  Future<RevisionItem> addTopicToRevision({
    required String topic,
    String? subtopic,
    String? questionId,
    String? questionText,
    String priority = 'High',
    String sourceTag = 'Quiz Mistake',
  }) async {
    final now = DateTime.now();
    final id = 'rev_${now.millisecondsSinceEpoch}';

    final newItem = RevisionItem(
      id: id,
      topic: topic,
      subtopic: subtopic,
      questionId: questionId,
      questionText: questionText,
      easeFactor: 2.5,
      intervalDays: 1,
      repetitions: 0,
      nextReviewDate: now, // Due immediately
      lastReviewedAt: now,
      qualityRating: 2,
      masteryLevel: 'Novice',
      priority: priority,
      sourceTag: sourceTag,
    );

    _items[id] = newItem;
    return newItem;
  }

  @override
  Future<List<RevisionItem>> getOverdueItems() async {
    return _items.values.where((i) => i.isOverdue).toList();
  }

  @override
  Future<Map<String, double>> getTopicMasteryOverview() async {
    final Map<String, List<RevisionItem>> grouped = {};
    for (final item in _items.values) {
      grouped.putIfAbsent(item.topic, () => []).add(item);
    }

    final Map<String, double> overview = {};
    grouped.forEach((topic, itemList) {
      double totalScore = 0.0;
      for (final item in itemList) {
        switch (item.masteryLevel) {
          case 'Master':
            totalScore += 100.0;
            break;
          case 'Proficient':
            totalScore += 75.0;
            break;
          case 'Learning':
            totalScore += 45.0;
            break;
          default:
            totalScore += 20.0;
        }
      }
      final avg = itemList.isNotEmpty ? totalScore / itemList.length : 0.0;
      overview[topic] = double.parse(avg.toStringAsFixed(1));
    });

    return overview;
  }
}
