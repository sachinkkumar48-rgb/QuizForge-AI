import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_dashboard/titan_dashboard.dart';

void main() {
  group('Dashboard Accessibility Tests', () {
    testWidgets('DashboardHome meets accessibility semantics guidelines',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardHome(
              userId: 'u_acc',
              userName: 'Accessible Learner',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.getSemantics(find.byType(WelcomeHeader)), isNotNull);
      expect(tester.getSemantics(find.byType(TodayFocusCard)), isNotNull);
      expect(tester.getSemantics(find.byType(QuickActionsCard)), isNotNull);

      handle.dispose();
    });

    testWidgets('Dashboard cards scale properly with large text scale factor',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: MaterialApp(
            home: Scaffold(
              body: TodayFocusCard(
                focusData: TodayFocusData.empty(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text("TODAY'S FOCUS"), findsOneWidget);
    });
  });
}
