import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_dashboard/titan_dashboard.dart';

void main() {
  group('Dashboard Widget Tests', () {
    Widget buildTestableWidget(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('DashboardHome renders all key dashboard section cards',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(
          const DashboardHome(
            userId: 'user_001',
            userName: 'Sachin Kumar',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sachin Kumar'), findsOneWidget);
      expect(find.text("TODAY'S FOCUS"), findsOneWidget);
      expect(find.text('CONTINUE LEARNING'), findsOneWidget);
      expect(find.text('REVISION DUE'), findsOneWidget);
      expect(find.text('AI TUTOR'), findsOneWidget);
      expect(find.text('RECOMMENDED FOR YOU'), findsOneWidget);
      expect(find.text('LEARNING JOURNEY'), findsOneWidget);
      expect(find.text('ASSESSMENT READINESS'), findsOneWidget);
      expect(find.text('WEEKLY ANALYTICS'), findsOneWidget);
      expect(find.text('UPCOMING EVENTS'), findsOneWidget);
      expect(find.text('ACHIEVEMENTS'), findsOneWidget);
      expect(find.text('QUICK ACTIONS'), findsOneWidget);
    });

    testWidgets('DashboardScrollView adapts layout for mobile viewport',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = UnifiedDashboardState.initial().copyWith(
        isLoading: false,
        header: const LearnerHeaderData(
          userId: 'u1',
          displayName: 'Test Learner',
          greeting: 'Hello',
          streakDays: 5,
          targetExam: 'UPSC',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScrollView(state: state),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(WelcomeHeader), findsOneWidget);
      expect(find.byType(QuickActionsCard), findsOneWidget);
    });
  });
}
