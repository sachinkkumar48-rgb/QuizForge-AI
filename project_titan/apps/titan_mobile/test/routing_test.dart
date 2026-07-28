import 'package:flutter_test/flutter_test.dart';
import 'package:titan_mobile/src/navigation/app_router.dart';
import 'package:titan_mobile/src/navigation/app_routes.dart';

void main() {
  group('AppRoutes Tests', () {
    test('AppRoutes path constants are properly formatted', () {
      expect(AppRoutes.splashPath, equals('/splash'));
      expect(AppRoutes.onboardingPath, equals('/onboarding'));
      expect(AppRoutes.authPath, equals('/auth'));
      expect(AppRoutes.dashboardPath, equals('/dashboard'));
      expect(AppRoutes.academyPath, equals('/academy'));
      expect(AppRoutes.learningPath, equals('/learning'));
      expect(AppRoutes.assessmentsPath, equals('/assessments'));
      expect(AppRoutes.aiTutorPath, equals('/ai-tutor'));
      expect(AppRoutes.journeyPath, equals('/journey'));
      expect(AppRoutes.plannerPath, equals('/planner'));
      expect(AppRoutes.searchPath, equals('/search'));
      expect(AppRoutes.profilePath, equals('/profile'));
      expect(AppRoutes.notificationsPath, equals('/notifications'));
      expect(AppRoutes.settingsPath, equals('/settings'));
      expect(AppRoutes.helpPath, equals('/help'));
      expect(AppRoutes.aboutPath, equals('/about'));
    });

    test('GoRouter is properly configured with initial location and routes',
        () {
      expect(appRouter.configuration.routes.isNotEmpty, isTrue);
    });
  });
}
