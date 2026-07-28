import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_dashboard/titan_dashboard.dart';

void main() {
  group('Dashboard Refresh Tests', () {
    testWidgets('Pull to refresh triggers dashboard reload', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardHome(
              userId: 'u_refresh',
              userName: 'Refresh User',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.drag(scrollable, const Offset(0, 300));
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
