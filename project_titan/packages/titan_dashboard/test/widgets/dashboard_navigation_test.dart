import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan_dashboard/titan_dashboard.dart';

void main() {
  group('Dashboard Navigation Tests', () {
    testWidgets('QuickActionsCard fires route callback on button tap',
        (tester) async {
      String? tappedRoute;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsCard(
              onActionSelected: (route) {
                tappedRoute = route;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Continue Learning'));
      await tester.pump();

      expect(tappedRoute, equals('/learning'));
    });

    testWidgets('TodayFocusCard fires start action callback', (tester) async {
      bool startTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayFocusCard(
              focusData: TodayFocusData.empty(),
              onStartTap: () {
                startTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start Study'));
      await tester.pump();

      expect(startTapped, isTrue);
    });
  });
}
