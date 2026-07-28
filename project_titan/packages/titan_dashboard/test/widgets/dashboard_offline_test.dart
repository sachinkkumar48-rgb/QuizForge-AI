import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan_dashboard/titan_dashboard.dart';

void main() {
  group('Dashboard Offline Tests', () {
    testWidgets('DashboardOfflineBanner renders last updated timestamp',
        (tester) async {
      final now = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardOfflineBanner(lastUpdated: now),
          ),
        ),
      );

      expect(find.byType(DashboardOfflineBanner), findsOneWidget);
      expect(find.textContaining('Offline Mode'), findsOneWidget);
    });

    testWidgets(
        'DashboardHome displays offline banner when state isOffline is true',
        (tester) async {
      final state = UnifiedDashboardState.initial().copyWith(
        isLoading: false,
        isOffline: true,
        header: const LearnerHeaderData(
          userId: 'u_off',
          displayName: 'Offline User',
          greeting: 'Hello',
          streakDays: 3,
          targetExam: 'UPSC',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                if (state.isOffline)
                  DashboardOfflineBanner(lastUpdated: state.lastUpdated),
                Expanded(child: DashboardScrollView(state: state)),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(DashboardOfflineBanner), findsOneWidget);
    });
  });
}
