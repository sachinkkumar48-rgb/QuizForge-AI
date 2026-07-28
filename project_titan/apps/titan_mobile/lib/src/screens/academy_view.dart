import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_academy/titan_academy.dart';

class AcademyView extends ConsumerWidget {
  const AcademyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instructor = Instructor(
      id: 'inst_1',
      name: 'Dr. V. Sharma',
      title: 'Senior Faculty',
      bio: 'Faculty for Civil Services Examination',
      avatarUrl: '',
      qualifications: const ['M.A. Polity', 'Ph.D.'],
      rating: 4.9,
      studentCount: 5000,
    );

    final courses = <Course>[
      Course(
        id: 'c1',
        title: 'Polity & Governance Masterclass',
        description:
            'Comprehensive coverage of Indian Constitution & Governance',
        subject: 'Polity',
        level: 'Intermediate',
        instructor: instructor,
        modules: const [],
        estimatedHours: 40.0,
        rating: 4.8,
        enrolledCount: 1250,
        imageUrl: '',
        tags: const ['Polity', 'UPSC'],
      ),
      Course(
        id: 'c2',
        title: 'Indian Economy & Budgeting',
        description: 'Macroeconomics, Fiscal Policy, and Economic Survey',
        subject: 'Economy',
        level: 'Advanced',
        instructor: instructor,
        modules: const [],
        estimatedHours: 35.0,
        rating: 4.7,
        enrolledCount: 980,
        imageUrl: '',
        tags: const ['Economy', 'Budget'],
      ),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TITAN Academy Courses',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...courses.map((course) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: CourseCard(course: course),
                )),
          ],
        ),
      ),
    );
  }
}
