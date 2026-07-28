import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';

void main() {
  group('FlashcardEngine Tests', () {
    late FlashcardEngine flashcardEngine;

    setUp(() {
      flashcardEngine = FlashcardEngine();
    });

    test('Generates flashcards from concepts and glossary items', () {
      final obj = KnowledgeObject(
        id: 'k_polity_03',
        title: 'Judicial Review',
        source: 'judiciary.md',
        concepts: [
          KnowledgeConcept(
            id: 'c1',
            name: 'Basic Structure Doctrine',
            type: ConceptType.definition,
            description:
                'Judicial principle establishing unamendable core of constitution',
          ),
        ],
        glossary: [
          GlossaryItem(
              term: 'Locus Standi', definition: 'Right to bring an action'),
        ],
        contentBlocks: const [
          ParagraphBlock(id: 'b1', text: 'Judicial review power of SC.')
        ],
      );

      final cards = flashcardEngine.generate(obj);

      expect(cards.length, equals(2));
      expect(cards.first.sourceKnowledgeObjectId, equals('k_polity_03'));
      expect(cards.first.front, contains('Basic Structure Doctrine'));
      expect(cards.last.front, contains('Locus Standi'));
    });
  });
}
