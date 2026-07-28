import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_mobile/src/app.dart';

void main() {
  testWidgets('Navigation Shell renders shell layout and navigates tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TitanMobileApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial app rendering
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify AppBar header title
    expect(find.text('TITAN'), findsOneWidget);

    // Tap Academy tab icon
    final academyIcon = find.byIcon(Icons.school_outlined);
    expect(academyIcon, findsWidgets);
    await tester.tap(academyIcon.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Academy course title appears
    expect(find.text('TITAN Academy Courses'), findsOneWidget);

    // Tap Learning tab icon
    final learningIcon = find.byIcon(Icons.menu_book_outlined);
    expect(learningIcon, findsWidgets);
    await tester.tap(learningIcon.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Learning view title
    expect(find.text('Indian Polity & Governance'), findsOneWidget);

    // Tap Profile tab icon
    final profileIcon = find.byIcon(Icons.person_outline);
    expect(profileIcon, findsWidgets);
    await tester.tap(profileIcon.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Profile details
    expect(find.text('UPSC Aspirant'), findsWidgets);
  });

  testWidgets('Adaptive Navigation changes layout based on screen width',
      (WidgetTester tester) async {
    // Set mobile size
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: TitanMobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    // On mobile, bottom navigation bar should be visible
    expect(find.byType(NavigationBar), findsOneWidget);

    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
  });
}
