import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_kmp/titan_kmp.dart';

void main() {
  group('KMP Master Package Tests', () {
    test('KmpUserRole permissions logic', () {
      const editor = KmpUserSession(
        userId: 'u1',
        userName: 'Editor User',
        email: 'editor@titan.org',
        role: KmpUserRole.editor,
      );

      expect(editor.role.canAuthor, isTrue);
      expect(editor.role.canPublish, isFalse);

      const admin = KmpUserSession(
        userId: 'u2',
        userName: 'Admin User',
        email: 'admin@titan.org',
        role: KmpUserRole.administrator,
      );

      expect(admin.role.canAuthor, isTrue);
      expect(admin.role.canPublish, isTrue);
      expect(admin.role.canAdminister, isTrue);
    });

    testWidgets('KmpDashboardScreen renders header and subsystem tiles',
        (tester) async {
      const session = KmpUserSession(
        userId: 'admin_1',
        userName: 'Chief Editor',
        email: 'editor@titan.org',
        role: KmpUserRole.publisher,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: KmpDashboardScreen(session: session),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TITAN KMP Admin Console'), findsOneWidget);
      expect(
          find.textContaining('Knowledge Management Platform'), findsWidgets);
      expect(find.text('Course Management'), findsOneWidget);
      expect(find.text('Question Bank'), findsOneWidget);
      expect(find.text('Media Library'), findsOneWidget);
    });
  });
}
