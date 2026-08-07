import 'package:flutter/material.dart';
import '../data/lesson_repository.dart';
import 'lesson_player_page.dart';

/// Learning Journey Selector Page allowing candidates to select micro-lessons.
class LearningJourneySelectorPage extends StatefulWidget {
  const LearningJourneySelectorPage({super.key});

  @override
  State<LearningJourneySelectorPage> createState() =>
      _LearningJourneySelectorPageState();
}

class _LearningJourneySelectorPageState
    extends State<LearningJourneySelectorPage> {
  final LessonRepository _repository = LessonRepository();
  List<Map<String, String>> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadManifest();
  }

  Future<void> _loadManifest() async {
    try {
      final manifest = await _repository.getLessonManifest();
      setState(() {
        _lessons = manifest;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SARTHI Learning Journey',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(50),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: theme.colorScheme.primary.withAlpha(100),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: theme.colorScheme.primary,
                          size: 32.0,
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Module 7: Fundamental Rights',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                'Master constitutional provisions, judicial review & landmark precedents step-by-step.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Text(
                    'Available Micro-Lessons',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _lessons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                      itemBuilder: (context, index) {
                        final lesson = _lessons[index];
                        final lessonId = lesson['id'] ?? 'POL.FR.001';
                        final title = lesson['title'] ?? '';
                        final estimatedTime = lesson['estimatedTime'] ?? '';

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Text(
                                      lessonId,
                                      style: TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14.0,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    estimatedTime,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            trailing: Icon(
                              Icons.play_circle_fill_rounded,
                              color: theme.colorScheme.primary,
                              size: 28.0,
                            ),
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
