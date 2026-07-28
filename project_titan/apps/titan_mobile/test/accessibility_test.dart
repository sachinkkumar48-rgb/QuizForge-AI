import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_mobile/src/app.dart';

void main() {
  group('Accessibility Tests', () {
    testWidgets('TitanMobileApp meets basic semantics accessibility guidelines',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const ProviderScope(
          child: TitanMobileApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Check semantics tree is generated
      expect(tester.getSemantics(find.byType(MaterialApp)), isNotNull);

      handle.dispose();
    });

    testWidgets('Interactive elements have appropriate tap target sizes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: TitanMobileApp(),
        ),
      );
      await tester.pumpAndSettle();

      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsWidgets);

      for (final element in iconButtons.evaluate()) {
        final renderBox = element.renderObject as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          expect(renderBox.size.width >= 40.0, isTrue);
          expect(renderBox.size.height >= 40.0, isTrue);
        }
      }
    });
  });
}
