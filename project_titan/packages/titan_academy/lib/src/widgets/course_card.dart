import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/enrollment.dart';

/// Material 3 course card widget displaying course image, category badge, rating,
/// instructor details, and progress if enrolled.
class CourseCard extends StatelessWidget {
  final Course course;
  final Enrollment? enrollment;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.course,
    this.enrollment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progressPercentage =
        enrollment?.progress.overallProgressPercentage ?? 0.0;

    return Card(
      elevation: 1.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 90.0,
              width: double.infinity,
              color: _getSubjectColor(course.subject, colorScheme),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _getSubjectIcon(course.subject),
                      size: 48.0,
                      color:
                          colorScheme.onPrimaryContainer.withValues(alpha: 0.4),
                    ),
                  ),
                  Positioned(
                    top: 10.0,
                    left: 10.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Text(
                        course.subject,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10.0,
                    right: 10.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 12.0, color: Colors.amber),
                          const SizedBox(width: 2.0),
                          Text(
                            course.rating.toStringAsFixed(1),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14.0),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          course.instructor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      const Icon(Icons.schedule, size: 14.0),
                      const SizedBox(width: 2.0),
                      Text(
                        '${course.estimatedHours.toStringAsFixed(0)}h',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11.0,
                        ),
                      ),
                    ],
                  ),
                  if (enrollment != null) ...[
                    const SizedBox(height: 6.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${progressPercentage.toStringAsFixed(0)}% Done',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Flexible(
                          child: Text(
                            enrollment!.status == 'completed'
                                ? 'Done'
                                : 'Active',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.secondary,
                              fontSize: 10.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    LinearProgressIndicator(
                      value: progressPercentage / 100.0,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject, ColorScheme colorScheme) {
    switch (subject.toLowerCase()) {
      case 'polity':
        return colorScheme.primaryContainer;
      case 'history':
        return colorScheme.secondaryContainer;
      case 'economy':
        return colorScheme.tertiaryContainer;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'polity':
        return Icons.gavel_rounded;
      case 'history':
        return Icons.account_balance_rounded;
      case 'economy':
        return Icons.trending_up_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }
}
