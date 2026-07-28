import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../navigation/app_routes.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Adaptive Learning Journey',
      'description':
          'Orchestrates courses, assessments, notes, and revision into one personalized roadmap.',
      'icon': 'school',
    },
    {
      'title': 'AI Tutor & Socratic Mentor',
      'description':
          'Instant concept resolution, misconception detection, and motivational coaching.',
      'icon': 'psychology',
    },
    {
      'title': 'Smart Assessment & Analytics',
      'description':
          'Real-time exam readiness score, skill gap analysis, and spaced repetition.',
      'icon': 'insights',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).completeOnboarding();
                  context.go(AppRoutes.dashboardPath);
                },
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  IconData iconData = Icons.school;
                  if (item['icon'] == 'psychology') iconData = Icons.psychology;
                  if (item['icon'] == 'insights') iconData = Icons.insights;

                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            iconData,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          item['title']!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['description']!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (idx) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == idx ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == idx
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      ref.read(authProvider.notifier).completeOnboarding();
                      context.go(AppRoutes.dashboardPath);
                    }
                  },
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
