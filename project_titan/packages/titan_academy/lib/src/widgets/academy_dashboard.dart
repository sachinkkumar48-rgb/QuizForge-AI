import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/lesson.dart';
import 'continue_learning_card.dart';
import 'course_card.dart';

/// Central Material 3 dashboard screen for TITAN Academy.
class AcademyDashboard extends StatefulWidget {
  final List<Course> catalog;
  final List<Enrollment> enrollments;
  final Course? activeCourse;
  final Lesson? activeLesson;
  final Enrollment? activeEnrollment;
  final void Function(String query)? onSearchChanged;
  final void Function(String category)? onCategorySelected;
  final void Function(Course course)? onCourseTap;
  final VoidCallback? onResumeTap;

  const AcademyDashboard({
    super.key,
    required this.catalog,
    required this.enrollments,
    this.activeCourse,
    this.activeLesson,
    this.activeEnrollment,
    this.onSearchChanged,
    this.onCategorySelected,
    this.onCourseTap,
    this.onResumeTap,
  });

  @override
  State<AcademyDashboard> createState() => _AcademyDashboardState();
}

class _AcademyDashboardState extends State<AcademyDashboard> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = const [
    'All',
    'Polity',
    'History',
    'Economy',
    'Environment'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final enrolledCourseIds = widget.enrollments.map((e) => e.courseId).toSet();
    final enrolledCourses =
        widget.catalog.where((c) => enrolledCourseIds.contains(c.id)).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            pinned: true,
            title: const Text('TITAN Academy'),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  SearchBar(
                    controller: _searchController,
                    hintText: 'Search courses, topics, subjects...',
                    leading: const Icon(Icons.search_rounded),
                    onChanged: widget.onSearchChanged,
                    elevation: const WidgetStatePropertyAll(0.0),
                    backgroundColor:
                        WidgetStatePropertyAll(colorScheme.surfaceContainerLow),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(category),
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                              widget.onCategorySelected?.call(category);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Continue Learning Hero Section
                  if (widget.activeCourse != null &&
                      widget.activeLesson != null &&
                      widget.activeEnrollment != null) ...[
                    ContinueLearningCard(
                      course: widget.activeCourse!,
                      lesson: widget.activeLesson!,
                      enrollment: widget.activeEnrollment!,
                      onResumeTap: widget.onResumeTap,
                    ),
                    const SizedBox(height: 24.0),
                  ],

                  // Enrolled Courses Section
                  if (enrolledCourses.isNotEmpty) ...[
                    Text(
                      'Enrolled Courses',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    SizedBox(
                      height: 220.0,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: enrolledCourses.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12.0),
                        itemBuilder: (context, index) {
                          final course = enrolledCourses[index];
                          final enrollment = widget.enrollments.firstWhere(
                            (e) => e.courseId == course.id,
                          );
                          return SizedBox(
                            width: 280.0,
                            child: CourseCard(
                              course: course,
                              enrollment: enrollment,
                              onTap: () => widget.onCourseTap?.call(course),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24.0),
                  ],

                  // All Courses / Recommended Catalog
                  Text(
                    'Course Catalog',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340.0,
                mainAxisExtent: 220.0,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final course = widget.catalog[index];
                  final enrollment =
                      widget.enrollments.cast<Enrollment?>().firstWhere(
                            (e) => e?.courseId == course.id,
                            orElse: () => null,
                          );
                  return CourseCard(
                    course: course,
                    enrollment: enrollment,
                    onTap: () => widget.onCourseTap?.call(course),
                  );
                },
                childCount: widget.catalog.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 40.0),
          ),
        ],
      ),
    );
  }
}
