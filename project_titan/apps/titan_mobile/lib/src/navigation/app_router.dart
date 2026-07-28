import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/about_screen.dart';
import '../screens/academy_view.dart';
import '../screens/assessments_view.dart';
import '../screens/auth_screen.dart';
import '../screens/dashboard_view.dart';
import '../screens/help_feedback_screen.dart';
import '../screens/journey_view.dart';
import '../screens/learning_view.dart';
import '../screens/notification_center_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/planner_view.dart';
import '../screens/profile_view.dart';
import '../screens/search_view.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/tutor_view.dart';
import '../shell/home_shell.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splashPath,
  routes: <RouteBase>[
    GoRoute(
      name: AppRoutes.splash,
      path: AppRoutes.splashPath,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      name: AppRoutes.onboarding,
      path: AppRoutes.onboardingPath,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      name: AppRoutes.auth,
      path: AppRoutes.authPath,
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      name: AppRoutes.notifications,
      path: AppRoutes.notificationsPath,
      builder: (context, state) => const NotificationCenterScreen(),
    ),
    GoRoute(
      name: AppRoutes.settings,
      path: AppRoutes.settingsPath,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      name: AppRoutes.help,
      path: AppRoutes.helpPath,
      builder: (context, state) => const HelpFeedbackScreen(),
    ),
    GoRoute(
      name: AppRoutes.about,
      path: AppRoutes.aboutPath,
      builder: (context, state) => const AboutScreen(),
    ),

    // StatefulShellRoute for 9 main sections
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomeShell(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        // 0: Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoutes.dashboard,
              path: AppRoutes.dashboardPath,
              builder: (context, state) => const DashboardView(),
            ),
          ],
        ),
        // 1: Academy
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoutes.academy,
              path: AppRoutes.academyPath,
              builder: (context, state) => const AcademyView(),
            ),
          ],
        ),
        // 2: Learning
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoutes.learning,
              path: AppRoutes.learningPath,
              builder: (context, state) => const LearningView(),
            ),
          ],
        ),
        // 3: Assessments
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoutes.assessments,
              path: AppRoutes.assessmentsPath,
              builder: (context, state) => const AssessmentsView(),
            ),
          ],
        ),
        // 4: AI Tutor
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoutes.aiTutor,
              path: AppRoutes.aiTutorPath,
              builder: (context, state) => const TutorView(),
            ),
          ],
        ),
        // 5: Journey
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoutes.journey,
              path: AppRoutes.journeyPath,
              builder: (context, state) => const JourneyView(),
            ),
          ],
        ),
        // 6: Planner
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoutes.planner,
              path: AppRoutes.plannerPath,
              builder: (context, state) => const PlannerView(),
            ),
          ],
        ),
        // 7: Search
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoutes.search,
              path: AppRoutes.searchPath,
              builder: (context, state) => const SearchView(),
            ),
          ],
        ),
        // 8: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoutes.profile,
              path: AppRoutes.profilePath,
              builder: (context, state) => const ProfileView(),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Navigation Error')),
    body: Center(
      child: Text('Route not found: ${state.uri.toString()}'),
    ),
  ),
);
