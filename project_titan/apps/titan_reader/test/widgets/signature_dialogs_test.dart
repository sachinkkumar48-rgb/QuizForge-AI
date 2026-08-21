import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/pdf_visual_signature.dart';
import 'package:titan_reader/src/services/signature_service.dart';
import 'package:titan_reader/src/widgets/signatures/signature_dialogs.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('SignatureDrawingPad Widget', () {
    testWidgets('captures pan strokes, undos, and clears', (tester) async {
      List<List<PdfSignaturePoint>> capturedStrokes = [];
      final key = GlobalKey<SignatureDrawingPadState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignatureDrawingPad(
              key: key,
              onStrokesChanged: (s) => capturedStrokes = s,
            ),
          ),
        ),
      );

      expect(find.text('Sign here with finger or mouse'), findsOneWidget);

      // Perform pan drag
      final gesture = await tester.startGesture(const Offset(50, 50));
      await gesture.moveBy(const Offset(50, 50));
      await gesture.up();
      await tester.pump();

      expect(capturedStrokes.isNotEmpty, isTrue);
      expect(find.text('Sign here with finger or mouse'), findsNothing);

      // Undo stroke
      key.currentState?.undo();
      await tester.pump();
      expect(capturedStrokes.isEmpty, isTrue);

      // Add another stroke and clear
      final gesture2 = await tester.startGesture(const Offset(60, 60));
      await gesture2.moveBy(const Offset(30, 30));
      await gesture2.up();
      await tester.pump();

      expect(capturedStrokes.isNotEmpty, isTrue);
      key.currentState?.clear();
      await tester.pump();
      expect(capturedStrokes.isEmpty, isTrue);
    });
  });

  group('SignatureCreationDialog Widget', () {
    testWidgets('creates typed signature successfully', (tester) async {
      PdfVisualSignature? savedSig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignatureCreationDialog(
              initialName: 'Personal Sign',
              onSave: (s) => savedSig = s,
            ),
          ),
        ),
      );

      expect(find.text('Create Signature'), findsOneWidget);
      expect(find.text('Personal Sign'), findsOneWidget);

      // Switch to Type tab
      await tester.tap(find.text('Type'));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(
          find.byKey(const Key('signature-typed-input')), 'Alice Smith');
      await tester.pump();

      expect(find.text('Alice Smith'), findsWidgets);

      // Save
      await tester.tap(find.byKey(const Key('save-signature-button')));
      await tester.pumpAndSettle();

      expect(savedSig, isNotNull);
      expect(savedSig!.name, 'Personal Sign');
      expect(savedSig!.type, PdfSignatureType.typed);
      expect(savedSig!.typedText, 'Alice Smith');
    });

    testWidgets('creates drawn signature via drawing pad and toolbar buttons',
        (tester) async {
      PdfVisualSignature? savedSig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignatureCreationDialog(
              initialName: 'Drawn Sign',
              onSave: (s) => savedSig = s,
            ),
          ),
        ),
      );

      // Draw stroke on drawing pad
      final padFinder = find.byType(SignatureDrawingPad);
      expect(padFinder, findsOneWidget);
      final center = tester.getCenter(padFinder);

      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(50, 20));
      await gesture.up();
      await tester.pump();

      // Test undo
      await tester.tap(find.byKey(const Key('signature-undo-button')));
      await tester.pump();

      // Re-draw stroke
      final gesture2 = await tester.startGesture(center);
      await gesture2.moveBy(const Offset(40, 30));
      await gesture2.up();
      await tester.pump();

      // Save
      await tester.tap(find.byKey(const Key('save-signature-button')));
      await tester.pumpAndSettle();

      expect(savedSig, isNotNull);
      expect(savedSig!.name, 'Drawn Sign');
      expect(savedSig!.type, PdfSignatureType.drawn);
      expect(savedSig!.strokes.isNotEmpty, isTrue);
    });

    testWidgets('creates image signature successfully via upload tab',
        (tester) async {
      PdfVisualSignature? savedSig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignatureCreationDialog(
              initialName: 'Company Seal',
              onSave: (s) => savedSig = s,
            ),
          ),
        ),
      );

      // Switch to Upload tab
      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();

      // Enter base64 image data
      await tester.enterText(
        find.byKey(const Key('signature-image-input')),
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      );
      await tester.pump();

      // Save
      await tester.tap(find.byKey(const Key('save-signature-button')));
      await tester.pumpAndSettle();

      expect(savedSig, isNotNull);
      expect(savedSig!.name, 'Company Seal');
      expect(savedSig!.type, PdfSignatureType.image);
      expect(savedSig!.imageBase64.contains('iVBORw0KGgo'), isTrue);
    });
  });

  group('SignatureLibraryDialog Widget', () {
    testWidgets('renders saved signatures, handles delete and selection',
        (tester) async {
      final storage = InMemoryStorageService();
      await storage.initialize();
      final service = SignatureService(storage);
      final sig1 = PdfVisualSignature.typed(
        id: 'sig_lib_1',
        name: 'My Initials',
        text: 'AS',
      );
      final sig2 = PdfVisualSignature.typed(
        id: 'sig_lib_2',
        name: 'To Delete',
        text: 'TD',
      );
      await service.saveSignature(sig1);
      await service.saveSignature(sig2);

      PdfVisualSignature? selectedSig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignatureLibraryDialog(
              service: service,
              onSignatureSelected: (s) => selectedSig = s,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Signature Library'), findsOneWidget);
      expect(find.text('My Initials'), findsOneWidget);
      expect(find.text('To Delete'), findsOneWidget);

      // Delete sig2
      await tester.tap(find.descendant(
        of: find.byKey(const Key('signature-item-sig_lib_2')),
        matching: find.byIcon(Icons.delete_outline),
      ));
      await tester.pumpAndSettle();

      expect(find.text('To Delete'), findsNothing);
      expect(service.getSignatureById('sig_lib_2'), isNull);

      // Tap Place button on sig1
      await tester.tap(find.text('Place'));
      await tester.pumpAndSettle();

      expect(selectedSig, isNotNull);
      expect(selectedSig!.id, 'sig_lib_1');
    });
  });

  group('SignaturePlacementOverlay Widget', () {
    testWidgets('handles dragging, resizing and confirming stamp placement',
        (tester) async {
      final sig = PdfVisualSignature.typed(
        id: 'sig_place_1',
        name: 'Stamp Preview',
        text: 'Dr. Watson',
      );

      NormalizedPageRect? confirmedRect;
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 1000,
              child: SignaturePlacementOverlay(
                signature: sig,
                onConfirm: (r) => confirmedRect = r,
                onCancel: () => cancelled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Place "Stamp Preview"'), findsOneWidget);
      expect(find.text('Dr. Watson'), findsOneWidget);

      // Drag to reposition
      final center = tester.getCenter(find.text('Dr. Watson'));
      final moveGesture = await tester.startGesture(center);
      await moveGesture.moveBy(const Offset(40, 40));
      await moveGesture.up();
      await tester.pump();

      // Resize via handle
      final resizeHandle = find.byIcon(Icons.aspect_ratio);
      expect(resizeHandle, findsOneWidget);
      final resizeGesture =
          await tester.startGesture(tester.getCenter(resizeHandle));
      await resizeGesture.moveBy(const Offset(20, 20));
      await resizeGesture.up();
      await tester.pump();

      // Confirm placement
      await tester
          .tap(find.byKey(const Key('confirm-signature-placement-button')));
      await tester.pump();

      expect(confirmedRect, isNotNull);
      expect(confirmedRect!.left, greaterThan(0.0));
      expect(confirmedRect!.right, greaterThan(confirmedRect!.left));
      expect(confirmedRect!.bottom, greaterThan(confirmedRect!.top));
      expect(cancelled, isFalse);
    });

    testWidgets('cancels placement when Cancel is tapped', (tester) async {
      final sig = PdfVisualSignature.typed(
        id: 'sig_place_2',
        name: 'Cancel Test',
        text: 'Cancel Me',
      );

      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 1000,
              child: SignaturePlacementOverlay(
                signature: sig,
                onConfirm: (_) {},
                onCancel: () => cancelled = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cancelled, isTrue);
    });
  });
}
