import 'package:flutter/material.dart';

import '../../controllers/pyq_controller.dart';
import '../../models/daily_revision_queue.dart';
import '../../models/pyq_question_model.dart';
import '../../models/revision_schedule.dart';
import '../../services/spaced_repetition_scheduler.dart';
import 'pyq_attempt_page.dart';

/// Intelligent Spaced Repetition Revision Page.
/// Features 4 category tabs: Today's Revision, Overdue Revision, Bookmarked Revision, and Weak Topic Revision.
/// Includes Priority Scoring, Revision Calendar, and Smart Recommendations.
class PyqSmartRevisionPage extends StatefulWidget {
  const PyqSmartRevisionPage({super.key});

  @override
  State<PyqSmartRevisionPage> createState() => _PyqSmartRevisionPageState();
}

class _PyqSmartRevisionPageState extends State<PyqSmartRevisionPage> {
  final PyqController pyqController = PyqController();

  DailyRevisionQueue? _dailyQueue;
  List<PyqQuestionModel> _allQuestions = [];
  final Map<String, RevisionSchedule> _scheduleMap = {};
  bool _isLoadingQueue = true;
  bool _isGenerating = false;
  int _sessionLength = 20;

  @override
  void initState() {
    super.initState();
    _loadDailyQueue();
  }

  Future<void> _loadDailyQueue() async {
    setState(() => _isLoadingQueue = true);
    final queue = await pyqController.getDailyRevisionQueue();
    final questions = await pyqController.getAllQuestions();

    if (mounted) {
      setState(() {
        _dailyQueue = queue;
        _allQuestions = questions;
        _isLoadingQueue = false;
      });
    }
  }

  void _startRevisionSession(List<RevisionQueueItem> items, String title) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No items currently due for $title!")),
      );
      return;
    }

    setState(() => _isGenerating = true);
    final questions =
        items.take(_sessionLength).map((i) => i.question).toList();
    setState(() => _isGenerating = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PyqAttemptPage(
          questions: questions,
          title: title,
        ),
      ),
    ).then((_) => _loadDailyQueue());
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.amber.shade800;
      case 'Low':
      default:
        return Colors.blue;
    }
  }

  void _showRevisionCalendarModal(BuildContext context) {
    final calendar = SpacedRepetitionScheduler.buildRevisionCalendar(
      questions: _allQuestions,
      scheduleMap: _scheduleMap,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final dateKeys = calendar.keys.toList()..sort();

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.indigo),
                      const SizedBox(width: 10),
                      Text(
                        'Revision Calendar Breakdown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: dateKeys.isEmpty
                        ? const Center(
                            child: Text('No scheduled reviews in calendar.'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: dateKeys.length,
                            itemBuilder: (context, idx) {
                              final dateStr = dateKeys[idx];
                              final itemsForDate = calendar[dateStr] ?? [];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ExpansionTile(
                                  leading: const Icon(Icons.event,
                                      color: Colors.blue),
                                  title: Text(
                                    'Date: $dateStr',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${itemsForDate.length} questions scheduled for review',
                                  ),
                                  children: itemsForDate.map((item) {
                                    final color =
                                        _getTierColor(item.priorityTier);
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        item.question.question,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                          '${item.question.subject} • Score: ${item.priorityScore.toStringAsFixed(0)}'),
                                      trailing: Chip(
                                        label: Text(
                                          item.priorityTier,
                                          style: TextStyle(
                                              color: color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        backgroundColor: color.withAlpha(30),
                                        padding: EdgeInsets.zero,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queue = _dailyQueue;
    final allItems = queue?.items ?? [];

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";

    // Categorize into the 4 UI tabs:
    // 1. Today's Revision
    final todayItems = allItems.where((i) {
      final due = i.schedule.nextReviewDue;
      return due.isBefore(now) ||
          (due.year == now.year &&
              due.month == now.month &&
              due.day == now.day);
    }).toList();

    // 2. Overdue Revision
    final overdueItems = allItems.where((i) {
      final due = i.schedule.nextReviewDue;
      final dueStr = "${due.year}-${due.month}-${due.day}";
      return due.isBefore(now) && dueStr != todayStr;
    }).toList();

    // 3. Bookmarked Revision
    final bookmarkedItems =
        allItems.where((i) => i.question.isBookmarked).toList();

    // 4. Weak Topic Revision
    final weakTopicItems = allItems.where((i) {
      return i.schedule.mistakeCount > 0 ||
          i.priorityTier == 'Critical' ||
          i.priorityTier == 'High';
    }).toList();

    final smartRecs = queue != null
        ? SpacedRepetitionScheduler.buildSmartRecommendations(items: allItems)
        : <String>[];

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Intelligent Revision Engine"),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () => _showRevisionCalendarModal(context),
              tooltip: "Revision Calendar",
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDailyQueue,
              tooltip: "Refresh Queue",
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.today), text: "Today's Revision"),
              Tab(icon: Icon(Icons.warning_amber), text: "Overdue Revision"),
              Tab(icon: Icon(Icons.bookmark), text: "Bookmarked"),
              Tab(icon: Icon(Icons.psychology), text: "Weak Topics"),
            ],
          ),
        ),
        body: _isLoadingQueue
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab 1: Today's Revision
                  _buildQueueListTab(
                    context: context,
                    theme: theme,
                    title: "Today's Revision Queue",
                    items: todayItems,
                    smartRecs: smartRecs,
                    queue: queue,
                  ),

                  // Tab 2: Overdue Revision
                  _buildQueueListTab(
                    context: context,
                    theme: theme,
                    title: "Overdue Revision Queue",
                    items: overdueItems,
                    smartRecs: smartRecs,
                    queue: queue,
                  ),

                  // Tab 3: Bookmarked Revision
                  _buildQueueListTab(
                    context: context,
                    theme: theme,
                    title: "Bookmarked Questions Queue",
                    items: bookmarkedItems,
                    smartRecs: smartRecs,
                    queue: queue,
                  ),

                  // Tab 4: Weak Topic Revision
                  _buildQueueListTab(
                    context: context,
                    theme: theme,
                    title: "Weak Topic & High Mistake Queue",
                    items: weakTopicItems,
                    smartRecs: smartRecs,
                    queue: queue,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQueueListTab({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required List<RevisionQueueItem> items,
    required List<String> smartRecs,
    required DailyRevisionQueue? queue,
  }) {
    return RefreshIndicator(
      onRefresh: _loadDailyQueue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Smart Reminder & AI Recommendations Card
            if (queue != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(100),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(70),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active,
                        color: theme.colorScheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        queue.smartReminderMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Smart Recommendations
              if (smartRecs.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.purple.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Colors.purple, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Smart Recommendations',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.purple.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...smartRecs.map((rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              '• $rec',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.purple.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],

            // Action Header & Session Size Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "$title (${items.length})",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 4,
                  children: [10, 20, 30].map((count) {
                    return ChoiceChip(
                      label: Text("$count Qs",
                          style: const TextStyle(fontSize: 11)),
                      selected: _sessionLength == count,
                      onSelected: (sel) {
                        if (sel) setState(() => _sessionLength = count);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Start Revision Session Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: (items.isEmpty || _isGenerating)
                    ? null
                    : () => _startRevisionSession(items, title),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bolt),
                label: Text(
                  _isGenerating
                      ? "Building Session..."
                      : "Start Session (${items.length} Available)",
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Question Queue List
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text("No questions due in this revision queue."),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final tierColor = _getTierColor(item.priorityTier);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: tierColor.withAlpha(35),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${item.priorityTier} Priority (${item.priorityScore.toStringAsFixed(0)} pts)",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: tierColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              "${item.question.subject} • ${item.question.year}",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.question.question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.reason,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
