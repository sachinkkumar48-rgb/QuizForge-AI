import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/widgets/merge_pdfs_dialog.dart';

void main() {
  group('Phase 6A: MergePdfsDialog Widget Tests', () {
    testWidgets('Renders empty state when no initial files provided',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MergePdfsDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Merge PDF Documents'), findsOneWidget);
      expect(find.text('No PDFs added yet.'), findsOneWidget);
      expect(find.text('0 file(s) selected'), findsOneWidget);
      expect(find.text('Add PDF Files'), findsOneWidget);
    });

    testWidgets('Renders file list and controls when initial files provided',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MergePdfsDialog(
                initialFiles: [
                  'C:/docs/fileA.pdf',
                  'C:/docs/fileB.pdf',
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('fileA.pdf'), findsOneWidget);
      expect(find.text('fileB.pdf'), findsOneWidget);
      expect(find.text('2 file(s) selected'), findsOneWidget);
      expect(find.text('Merge Documents'), findsOneWidget);
    });
  });
}
