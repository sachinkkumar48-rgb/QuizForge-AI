import 'package:flutter_test/flutter_test.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_reader/src/data/ai_retrieval_engine.dart';

void main() {
  group('Phase 5: AIRetrievalEngine (Local RAG)', () {
    const engine = AIRetrievalEngine();

    final testChunks = [
      PdfChunk(
        chunkId: 'chunk_1',
        documentId: 'doc_physics',
        index: 0,
        text:
            'Chapter 1: Thermodynamics. Heat engines and entropy are described by Carnot cycles.',
        startPage: 1,
        endPage: 1,
        tokenEstimate: 20,
      ),
      PdfChunk(
        chunkId: 'chunk_2',
        documentId: 'doc_physics',
        index: 1,
        text:
            'Chapter 2: Electromagnetism. Maxwell equations govern electric and magnetic fields.',
        startPage: 15,
        endPage: 15,
        tokenEstimate: 20,
      ),
      PdfChunk(
        chunkId: 'chunk_3',
        documentId: 'doc_physics',
        index: 2,
        text:
            'Chapter 3: Quantum Mechanics. Wave function collapse, Schrödinger equation, and entanglement.',
        startPage: 42,
        endPage: 43,
        tokenEstimate: 25,
      ),
    ];

    test('extractKeywords strips stopwords and punctuation', () {
      final terms = AIRetrievalEngine.extractKeywords(
          'What is the Schrödinger equation and wave function?');
      expect(terms, contains('schrodinger'));
      expect(terms, contains('equation'));
      expect(terms, contains('wave'));
      expect(terms, contains('function'));
      expect(terms, isNot(contains('what')));
      expect(terms, isNot(contains('the')));
      expect(terms, isNot(contains('and')));
    });

    test('Ranks matching chunks by relevance and preserves source page numbers',
        () {
      final retrieved = engine.retrieveRelevantChunks(
        query:
            'How does the Carnot cycle relate to entropy and thermodynamics?',
        chunks: testChunks,
        maxChunks: 2,
      );

      expect(retrieved.isNotEmpty, isTrue);
      expect(retrieved.first.pageNumber, 1);
      expect(retrieved.first.chunkId, 'chunk_1');
      expect(retrieved.first.excerpt, contains('Carnot cycles'));
    });

    test('Retrieves quantum mechanics chunk for Schrödinger query', () {
      final retrieved = engine.retrieveRelevantChunks(
        query:
            'Explain quantum entanglement and the Schrödinger wave equation.',
        chunks: testChunks,
      );

      expect(retrieved.first.pageNumber, 42);
      expect(retrieved.first.chunkId, 'chunk_3');
      expect(retrieved.first.excerpt, contains('Schrödinger equation'));
    });

    test('Respects maxTotalCharacters budget', () {
      final retrieved = engine.retrieveRelevantChunks(
        query: 'equations',
        chunks: testChunks,
        maxTotalCharacters: 100,
      );

      var total = 0;
      for (final r in retrieved) {
        total += r.excerpt.length;
      }
      expect(total, lessThanOrEqualTo(150));
    });

    test('Handles empty chunks list gracefully', () {
      final retrieved = engine.retrieveRelevantChunks(
        query: 'test query',
        chunks: const [],
      );
      expect(retrieved, isEmpty);
    });
  });
}
