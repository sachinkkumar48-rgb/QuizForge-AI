import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_encryption_options.dart';
import 'package:titan_reader/src/widgets/encryption/protect_pdf_dialog.dart';

void main() {
  Widget buildSubject({required String documentTitle}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<PdfEncryptionConfig>(
              context: context,
              builder: (context) =>
                  ProtectPdfDialog(documentTitle: documentTitle),
            ),
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  group('ProtectPdfDialog Widget Tests', () {
    testWidgets('renders dialog with password fields and cancel button',
        (tester) async {
      await tester
          .pumpWidget(buildSubject(documentTitle: 'Confidential Report.pdf'));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Protect PDF with Password'), findsOneWidget);
      expect(find.text('Confidential Report.pdf'), findsOneWidget);
      expect(
          find.byKey(const Key('encrypt-user-password-field')), findsOneWidget);
      expect(find.byKey(const Key('encrypt-confirm-password-field')),
          findsOneWidget);
      expect(find.byKey(const Key('encrypt-cancel-button')), findsOneWidget);
      expect(find.byKey(const Key('encrypt-confirm-button')), findsOneWidget);

      // Tap cancel
      await tester.tap(find.byKey(const Key('encrypt-cancel-button')));
      await tester.pumpAndSettle();

      expect(find.text('Protect PDF with Password'), findsNothing);
    });

    testWidgets('validates password mismatch and prevents submission',
        (tester) async {
      await tester.pumpWidget(buildSubject(documentTitle: 'Doc.pdf'));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('encrypt-user-password-field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('encrypt-confirm-password-field')),
        'wrongpassword',
      );

      await tester.tap(find.byKey(const Key('encrypt-confirm-button')));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('enables owner password and submits valid config',
        (tester) async {
      PdfEncryptionConfig? resultConfig;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                resultConfig = await showDialog<PdfEncryptionConfig>(
                  context: context,
                  builder: (context) =>
                      const ProtectPdfDialog(documentTitle: 'Doc.pdf'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter user password
      await tester.enterText(
        find.byKey(const Key('encrypt-user-password-field')),
        'userPass',
      );
      await tester.enterText(
        find.byKey(const Key('encrypt-confirm-password-field')),
        'userPass',
      );

      // Enable owner password
      await tester.tap(find.byKey(const Key('encrypt-enable-owner-password')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('encrypt-owner-password-field')),
          findsOneWidget);
      expect(find.text('Allow Printing'), findsOneWidget);
      expect(find.text('Allow Copying & Text Extraction'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('encrypt-owner-password-field')),
        'ownerSecret',
      );

      // Submit
      await tester.tap(find.byKey(const Key('encrypt-confirm-button')));
      await tester.pumpAndSettle();

      expect(resultConfig, isNotNull);
      expect(resultConfig!.userPassword, 'userPass');
      expect(resultConfig!.ownerPassword, 'ownerSecret');
      expect(resultConfig!.algorithm, PdfEncryptionAlgorithm.aes128);
    });
  });
}
