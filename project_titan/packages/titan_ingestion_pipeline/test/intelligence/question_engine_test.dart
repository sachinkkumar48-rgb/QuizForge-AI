import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';
import 'package:titan_question_bank/titan_question_bank.dart';

void main() {
  group('QuestionEngine Tests', () {
    late QuestionEngine questionEngine;

    setUp(() {
      questionEngine = QuestionEngine();
    });

    test(
        'Generates 8 question types across Easy, Medium, and Hard difficulties',
        () async {
      final obj = KnowledgeObject(
        id: 'k_polity_02',
        title: 'Directive Principles',
        source: 'dpsp.md',
        concepts: [
          KnowledgeConcept(
            id: 'c1',
            name: 'Article 39A',
            type: ConceptType.article,
            description: 'Equal justice and free legal aid',
          ),
        ],
        contentBlocks: const [
          ParagraphBlock(id: 'b1', text: 'DPSP details state policies.')
        ],
      );

      final questions = await questionEngine.generate(obj);

      expect(questions.length, equals(8));
      expect(questions.any((q) => q.type == KmpQuestionType.mcq), isTrue);
      expect(questions.any((q) => q.type == KmpQuestionType.assertionReason),
          isTrue);
      expect(
          questions.any((q) => q.type == KmpQuestionType.subjective), isTrue);
      expect(questions.any((q) => q.type == KmpQuestionType.pyq), isTrue);
      expect(questions.any((q) => q.type == KmpQuestionType.caseStudy), isTrue);
      expect(questions.any((q) => q.type == KmpQuestionType.trueFalse), isTrue);
      expect(
          questions.any((q) => q.type == KmpQuestionType.fillInBlanks), isTrue);

      expect(questions.any((q) => q.difficulty == 'Easy'), isTrue);
      expect(questions.any((q) => q.difficulty == 'Medium'), isTrue);
      expect(questions.any((q) => q.difficulty == 'Hard'), isTrue);
    });
  });
}
