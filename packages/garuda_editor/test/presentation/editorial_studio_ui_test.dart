import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart';

void main() {
  group('EditorialStudio UI Widget & Navigation Tests', () {
    late EditorialStudioController controller;

    setUp(() {
      controller = EditorialStudioController();
    });

    testWidgets('Renders EditorialStudioShell and navigates tabs via NavigationRail', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(EditorialStudioShell(controller: controller));
      await tester.pumpAndSettle();

      // Verify Dashboard is rendered initially
      expect(find.text('GARUDA Editorial Overview'), findsOneWidget);
      expect(find.text('Pending Evidence'), findsOneWidget);

      // Tap Evidence Inbox NavigationRail item (index 1)
      await tester.tap(find.byIcon(Icons.inbox_outlined));
      await tester.pumpAndSettle();

      expect(controller.currentTabIndex, equals(1));
      expect(find.textContaining('Incoming Evidence Inbox'), findsOneWidget);

      // Tap Knowledge Object Manager (index 2)
      await tester.tap(find.byIcon(Icons.folder_outlined));
      await tester.pumpAndSettle();

      expect(controller.currentTabIndex, equals(2));
      expect(find.textContaining('Knowledge Objects'), findsOneWidget);
    });

    testWidgets('Dashboard metric card taps navigate to correct screens', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(EditorialStudioShell(controller: controller));
      await tester.pumpAndSettle();

      // Tap Pending Evidence metric card
      await tester.tap(find.text('Pending Evidence'));
      await tester.pumpAndSettle();

      expect(controller.currentTabIndex, equals(1));
    });
  });
}
