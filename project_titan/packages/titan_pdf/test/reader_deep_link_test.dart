import 'package:test/test.dart';
import 'package:titan_pdf/titan_pdf.dart';

void main() {
  group('Phase 8C: Reader Deep Link Navigation Contract Tests', () {
    test(
        '1. ReaderDeepLinkRequest initializes with correct parameters and chunk/text detection',
        () {
      final req1 = ReaderDeepLinkRequest(
        documentId: 'doc_123',
        pageNumber: 5,
        chunkId: 'chk_456',
        selectedText: 'Article 21 of the Constitution',
        source: 'quizforge_assessment',
      );

      expect(req1.documentId, 'doc_123');
      expect(req1.pageNumber, 5);
      expect(req1.chunkId, 'chk_456');
      expect(req1.hasChunk, isTrue);
      expect(req1.hasSelectedText, isTrue);
      expect(req1.source, 'quizforge_assessment');

      final req2 = ReaderDeepLinkRequest(
        documentId: 'doc_123',
        pageNumber: 5,
      );

      expect(req2.hasChunk, isFalse);
      expect(req2.hasSelectedText, isFalse);
    });

    test('2. ReaderDeepLinkRequest equality and hashCode work as expected', () {
      final fixedDate = DateTime(2026, 8, 23, 12, 0, 0);
      final req1 = ReaderDeepLinkRequest.constRequest(
        documentId: 'doc_abc',
        pageNumber: 3,
        chunkId: 'chunk_1',
        selectedText: 'Preamble',
        boundingRegion: const {'x': 10.0, 'y': 20.0, 'w': 100.0, 'h': 50.0},
        source: 'remedial_loop',
        createdAt: fixedDate,
      );

      final req2 = ReaderDeepLinkRequest.constRequest(
        documentId: 'doc_abc',
        pageNumber: 3,
        chunkId: 'chunk_1',
        selectedText: 'Preamble',
        boundingRegion: const {'x': 10.0, 'y': 20.0, 'w': 100.0, 'h': 50.0},
        source: 'remedial_loop',
        createdAt: fixedDate,
      );

      expect(req1, equals(req2));
      expect(req1.hashCode, equals(req2.hashCode));
    });

    test(
        '3. InMemoryReaderDeepLinkHandler captures requests and triggers callbacks',
        () async {
      final handler = InMemoryReaderDeepLinkHandler();

      final request = ReaderDeepLinkRequest(
        documentId: 'doc_constitution',
        pageNumber: 10,
        chunkId: 'chunk_10_1',
      );

      expect(handler.handledRequests.isEmpty, isTrue);

      final result = await handler.openReaderToSource(request);
      expect(result, isTrue);
      expect(handler.handledRequests.length, 1);
      expect(handler.handledRequests.first, equals(request));

      // With custom callback
      var callbackInvoked = false;
      handler.onNavigate = (req) {
        callbackInvoked = true;
        return req.pageNumber > 0;
      };

      final result2 = await handler.openReaderToSource(request);
      expect(result2, isTrue);
      expect(callbackInvoked, isTrue);
      expect(handler.handledRequests.length, 2);

      handler.clear();
      expect(handler.handledRequests.isEmpty, isTrue);
    });
  });
}
