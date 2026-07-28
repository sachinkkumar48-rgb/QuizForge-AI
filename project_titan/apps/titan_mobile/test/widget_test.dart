import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_mobile/src/widgets/empty_state_widget.dart';
import 'package:titan_mobile/src/widgets/error_state_widget.dart';
import 'package:titan_mobile/src/widgets/offline_banner.dart';
import 'package:titan_mobile/src/widgets/skeleton_loader.dart';

void main() {
  group('Shell Component Widget Tests', () {
    testWidgets('EmptyStateWidget renders title, description and action button',
        (WidgetTester tester) async {
      bool actionTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.search_off,
              title: 'No Items Found',
              description: 'Try adjusting your search criteria.',
              actionLabel: 'Reset',
              onAction: () => actionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('No Items Found'), findsOneWidget);
      expect(find.text('Try adjusting your search criteria.'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      expect(actionTapped, isTrue);
    });

    testWidgets('ErrorStateWidget renders error description and retry button',
        (WidgetTester tester) async {
      bool retryTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              description: 'Failed to connect to network server.',
              onRetry: () => retryTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed to connect to network server.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retryTapped, isTrue);
    });

    testWidgets('OfflineBanner displays message when offline',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(isOffline: true),
          ),
        ),
      );

      expect(
          find.text('Offline Mode • Working from local cache'), findsOneWidget);
    });

    testWidgets('SkeletonLoader renders placeholder boxes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(height: 40, width: 200),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });
}
