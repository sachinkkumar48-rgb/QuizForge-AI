import 'package:flutter/material.dart';
import '../data/lesson_repository.dart';
import '../widgets/knowledge_node.dart';
import '../widgets/knowledge_path.dart';
import '../widgets/module_progress_card.dart';
import 'lesson_player_page.dart';

/// Knowledge Map Screen visualizing learning journey micro-lessons as a progression tree.
class KnowledgeMapPage extends StatefulWidget {
  final List<String> completedLessonIds;

  const KnowledgeMapPage({
    super.key,
    this.completedLessonIds = const ['POL.FR.001'],
  });

  @override
  State<KnowledgeMapPage> createState() => _KnowledgeMapPageState();
}

class _KnowledgeMapPageState extends State<KnowledgeMapPage> {
  final LessonRepository _repository = LessonRepository();
  List<Map<String, String>> _lessons = [];
  bool _isLoading = true;
  String _subject = 'Indian Polity';
  final String _moduleTitle = 'Module 7: Fundamental Rights';

  @override
  void initState() {
    super.initState();
    _loadManifestData();
  }

  Future<void> _loadManifestData() async {
    try {
      final manifest = await _repository.getLessonManifest();
      setState(() {
        _lessons = manifest;
        if (manifest.isNotEmpty) {
          _subject = manifest.first['subject'] ?? 'Indian Polity';
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  NodeState _getNodeState(int index, String lessonId) {
    if (widget.completedLessonIds.contains(lessonId)) {
      return NodeState.completed;
    }

    // First uncompleted lesson is "Current"
    final firstUncompletedIndex = _lessons.indexWhere(
      (l) => !widget.completedLessonIds.contains(l['id']),
    );

    if (index == (firstUncompletedIndex != -1 ? firstUncompletedIndex : 0)) {
      return NodeState.current;
    }

    return NodeState.locked;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = widget.completedLessonIds.length;
    final totalLessons = _lessons.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Knowledge Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadManifestData();
            },
            tooltip: 'Reload Manifest',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadManifestData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Module Progress Card
                    ModuleProgressCard(
                      subject: _subject,
                      moduleTitle: _moduleTitle,
                      completedLessons: completedCount,
                      totalLessons: totalLessons,
                    ),
                    const SizedBox(height: 24.0),

                    // Section Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_tree_rounded,
                            color: theme.colorScheme.primary,
                            size: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'Learning Journey Progression Tree',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Progression Tree Vertical List of Nodes & Paths
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _lessons.length,
                      itemBuilder: (context, index) {
                        final lesson = _lessons[index];
                        final lessonId = lesson['id'] ?? 'POL.FR.001';
                        final title = lesson['title'] ?? '';
                        final estimatedTime = lesson['estimatedTime'] ?? '15 Mins';
                        final difficulty = lesson['difficulty'] ?? 'Intermediate';
                        final nodeState = _getNodeState(index, lessonId);
                        final isLastNode = index == _lessons.length - 1;

                        return Column(
                          children: [
                            KnowledgeNode(
                              lessonId: lessonId,
                              title: title,
                              estimatedTime: estimatedTime,
                              difficulty: difficulty,
                              state: nodeState,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LessonPlayerPage(
                                      lessonId: lessonId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (!isLastNode)
                              KnowledgePath(
                                isCompleted: nodeState == NodeState.completed,
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32.0),
                  ],
                ),
              ),
            ),
    );
  }
}
