import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/widgets/organize_pages_dialog.dart';

void main() {
  group('Phase 6A: OrganizePagesDialog Widget Tests', () {
    testWidgets('Renders page grid and allows page selection and actions',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OrganizePagesDialog(
                filePath: 'dummy.pdf',
                initialPageCount: 4,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Organize Pages'), findsOneWidget);
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);
      expect(find.text('Page 3'), findsOneWidget);
      expect(find.text('Page 4'), findsOneWidget);
      expect(find.text('Rotate 90°'), findsOneWidget);
      expect(find.text('Insert Blank'), findsOneWidget);

      // Select Page 1
      await tester.tap(find.text('Page 1'));
      await tester.pumpAndSettle();

      // Tap Rotate 90°
      await tester.tap(find.text('Rotate 90°'));
      await tester.pumpAndSettle();

      expect(find.text('90°'), findsOneWidget);

      // Tap Insert Blank
      await tester.tap(find.text('Insert Blank'));
      await tester.pumpAndSettle();

      expect(find.text('Page 5'), findsOneWidget);
    });
  });
}
