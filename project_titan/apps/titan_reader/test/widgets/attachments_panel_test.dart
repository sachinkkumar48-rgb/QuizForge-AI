import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_embedded_file.dart';
import 'package:titan_reader/src/providers/attachment_providers.dart';
import 'package:titan_reader/src/services/pdf_attachment_service.dart';
import 'package:titan_reader/src/widgets/attachments_panel.dart';

class _FakeAttachmentService extends PdfAttachmentService {
  final List<PdfEmbeddedFile> mockAttachments;

  _FakeAttachmentService({required this.mockAttachments});

  @override
  Future<List<PdfEmbeddedFile>> listAttachments(
      {required String filePath}) async {
    return mockAttachments;
  }

  @override
  Future<PdfAttachmentExtractionResult> extractAttachment({
    required String sourceFilePath,
    required PdfEmbeddedFile attachment,
    required String targetDirectoryPath,
    bool overwrite = false,
  }) async {
    return PdfAttachmentExtractionResult.completed(
      outputPath: '$targetDirectoryPath/${attachment.filename}',
      extractedBytesCount: attachment.displaySize ?? 1024,
    );
  }

  @override
  Future<List<PdfAttachmentExtractionResult>> extractAllAttachments({
    required String sourceFilePath,
    required String targetDirectoryPath,
    bool overwrite = false,
  }) async {
    return [
      for (final a in mockAttachments)
        PdfAttachmentExtractionResult.completed(
          outputPath: '$targetDirectoryPath/${a.filename}',
          extractedBytesCount: a.displaySize ?? 1024,
        ),
    ];
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('titan_panel_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildSubject({
    required List<PdfEmbeddedFile> attachments,
    String? extractDir,
  }) {
    return ProviderScope(
      overrides: [
        pdfAttachmentServiceProvider.overrideWithValue(
          _FakeAttachmentService(mockAttachments: attachments),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AttachmentsPanel(
            filePath: '${tempDir.path}/test_doc.pdf',
            documentTitle: 'Annual Report.pdf',
            targetExtractionDirectory: extractDir ?? tempDir.path,
          ),
        ),
      ),
    );
  }

  group('AttachmentsPanel Widget Tests', () {
    testWidgets('renders empty state when document has no attachments',
        (tester) async {
      await tester.pumpWidget(buildSubject(attachments: []));
      await tester.pumpAndSettle();

      expect(find.text('Embedded Attachments'), findsOneWidget);
      expect(find.text('Annual Report.pdf'), findsOneWidget);
      expect(find.text('No embedded attachments found'), findsOneWidget);
      expect(find.byKey(const Key('extract-all-attachments-button')),
          findsNothing);
    });

    testWidgets(
        'renders attachment list with items, metadata, and extract buttons',
        (tester) async {
      final attachments = [
        const PdfEmbeddedFile(
          id: 'emb_1_0',
          filename: 'financials.xlsx',
          description: 'Quarterly financial balance sheet',
          mimeType: 'application/vnd.ms-excel',
          actualSize: 1024 * 50,
          streamObjectNumber: 1,
        ),
        const PdfEmbeddedFile(
          id: 'emb_2_0',
          filename: 'chart.png',
          mimeType: 'image/png',
          actualSize: 1024 * 200,
          sourceLocation: PdfAttachmentSourceLocation.annotation,
          pageNumber: 3,
          streamObjectNumber: 2,
        ),
      ];

      await tester.pumpWidget(buildSubject(attachments: attachments));
      await tester.pumpAndSettle();

      expect(find.text('financials.xlsx'), findsOneWidget);
      expect(find.text('50.0 KB • application/vnd.ms-excel'), findsOneWidget);
      expect(find.text('Quarterly financial balance sheet'), findsOneWidget);

      expect(find.text('chart.png'), findsOneWidget);
      expect(find.text('200.0 KB • image/png • Page 3'), findsOneWidget);

      expect(find.byKey(const Key('extract-all-attachments-button')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('extract-btn-emb_1_0')), findsOneWidget);

      // Tap extract on first attachment
      await tester.tap(find.byKey(const ValueKey('extract-btn-emb_1_0')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Extracted "financials.xlsx" to:'),
          findsOneWidget);
    });

    testWidgets('extracts all attachments when Extract All is tapped',
        (tester) async {
      final attachments = [
        const PdfEmbeddedFile(
          id: 'emb_10_0',
          filename: 'readme.txt',
          actualSize: 500,
          streamObjectNumber: 10,
        ),
      ];

      await tester.pumpWidget(buildSubject(attachments: attachments));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('extract-all-attachments-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Extracted 1 of 1 attachments to:'),
          findsOneWidget);
    });
  });
}
