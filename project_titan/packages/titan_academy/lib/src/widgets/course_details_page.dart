import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/lesson.dart';
import 'chapter_list.dart';

/// Comprehensive Material 3 details screen for viewing course info, syllabus,
/// instructor credentials, enrollment actions, knowledge graph, and AI mentor guidance.
class CourseDetailsPage extends StatelessWidget {
  final Course course;
  final Enrollment? enrollment;
  final VoidCallback? onEnrollTap;
  final void Function(Lesson lesson)? onLessonTap;
  final VoidCallback? onAskMentorTap;
  final VoidCallback? onExploreKnowledgeGraphTap;

  const CourseDetailsPage({
    super.key,
    required this.course,
    this.enrollment,
    this.onEnrollTap,
    this.onLessonTap,
    this.onAskMentorTap,
    this.onExploreKnowledgeGraphTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnrolled = enrollment != null;

    final allChapters = course.modules.expand((m) => m.chapters).toList();
    final activeLessonId = enrollment?.progress.lastAccessedLessonId;

    return Scaffold(
      appBar: AppBar(
        title: Text(course.subject),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Container
            Container(
              height: 160.0,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.school_rounded,
                      size: 80.0,
                      color:
                          colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
                    ),
                  ),
                  Positioned(
                    bottom: 16.0,
                    left: 16.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text(
                        '${course.level} Level',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              course.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 18.0, color: Colors.amber),
                const SizedBox(width: 4.0),
                Text(
                  '${course.rating.toStringAsFixed(1)} Rating',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12.0),
                Text('•',
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
                const SizedBox(width: 12.0),
                const Icon(Icons.group_outlined, size: 16.0),
                const SizedBox(width: 4.0),
                Text(
                  '${course.enrolledCount} Learners',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12.0),
                Text('•',
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
                const SizedBox(width: 12.0),
                const Icon(Icons.schedule_outlined, size: 16.0),
                const SizedBox(width: 4.0),
                Text(
                  '${course.estimatedHours.toStringAsFixed(0)} Hours',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              course.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20.0),

            // AI Mentor & Knowledge Graph Action Cards
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAskMentorTap,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18.0),
                    label: const Text('Ask AI Mentor'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExploreKnowledgeGraphTap,
                    icon: const Icon(Icons.hub_outlined, size: 18.0),
                    label: const Text('Knowledge Map'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24.0),
            // Instructor Card
            Card(
              elevation: 0.0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26.0,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        course.instructor.name.substring(0, 1),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.instructor.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            course.instructor.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            course.instructor.bio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24.0),
            Text(
              'Course Syllabus',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12.0),
            ChapterList(
              chapters: allChapters,
              activeLessonId: activeLessonId,
              onLessonTap: onLessonTap,
            ),
            const SizedBox(height: 80.0), // Padding for sticky bottom button
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10.0,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52.0,
          child: FilledButton(
            onPressed: isEnrolled ? null : onEnrollTap,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
            child: Text(
              isEnrolled ? 'Enrolled in Course' : 'Enroll Now in Course',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
