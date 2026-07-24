import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/knowledge_engine.dart';

void main() {
  group('KnowledgeIngestionPipeline Tests', () {
    late KnowledgeIngestionPipeline pipeline;

    setUp(() {
      pipeline = KnowledgeIngestionPipeline();
    });

    test('handles empty input gracefully', () async {
      final result = await pipeline.process(
        rawText: '   \n\t  ',
        title: 'Empty Doc',
        type: KnowledgeType.other,
      );

      expect(result.isSuccess, isTrue);
      expect(result.objects, isEmpty);
      expect(result.warnings.length, equals(1));
      expect(result.statistics.originalCharCount, equals(7));
      expect(result.statistics.chunkCount, equals(0));
    });

    test('ingests multi-paragraph document into KnowledgeObjects', () async {
      final rawText = '''
        # Chapter 1: Introduction to Ancient History
        
        Ancient Indian History spans from the prehistoric era to the early medieval period.
        
        The Indus Valley Civilization flourished around 2500 BCE in northwestern South Asia.
        
        The Vedic Period saw the composition of the Vedas and the foundation of social structures.
      ''';

      final result = await pipeline.process(
        rawText: rawText,
        title: 'Ancient History Notes',
        type: KnowledgeType.book,
        source: 'history_book.pdf',
        subjects: ['History'],
        topics: ['Ancient History'],
        chunkOptions: const KnowledgeChunkOptions(maxChunkSize: 300),
      );

      expect(result.isSuccess, isTrue);
      expect(result.objects.isNotEmpty, isTrue);
      expect(result.statistics.originalCharCount, equals(rawText.length));
      expect(result.statistics.chunkCount, equals(result.objects.length));
      expect(result.statistics.totalWords, greaterThan(20));

      final firstObj = result.objects.first;
      expect(firstObj.type, equals(KnowledgeType.book));
      expect(firstObj.source, equals('history_book.pdf'));
      expect(firstObj.subjects, equals(['History']));
    });

    test('supports very large input deterministically', () async {
      final largeText =
          List.generate(50, (i) => 'Paragraph $i: ${'Data snippet text ' * 30}')
              .join('\n\n');

      final result = await pipeline.process(
        rawText: largeText,
        title: 'Large Report',
        type: KnowledgeType.report,
        chunkOptions:
            const KnowledgeChunkOptions(maxChunkSize: 500, overlap: 50),
      );

      expect(result.isSuccess, isTrue);
      expect(result.objects.length, greaterThan(10));
      expect(result.statistics.chunkCount, equals(result.objects.length));
    });
  });
}
