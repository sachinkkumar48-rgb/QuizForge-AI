import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('Concept Engine Domain Models', () {
    test('Concept model serialization and immutability', () {
      final now = DateTime(2024, 1, 1);
      final concept = Concept(
        id: 'C_RIGHT_TO_EQUALITY',
        name: 'Right to Equality',
        aliases: const ['Article 14 Rights', 'Equality Before Law'],
        description: 'Guarantees equality before law and equal protection of laws.',
        subject: 'Polity',
        module: 'Constitutional Framework',
        topic: 'Fundamental Rights',
        subtopic: 'Right to Equality',
        keywords: const ['Equality', 'Rule of Law'],
        difficulty: 'Medium',
        knowledgeObjectIds: const ['KO_ART_14'],
        createdAt: now,
        updatedAt: now,
      );

      final json = concept.toJson();
      expect(json['id'], equals('C_RIGHT_TO_EQUALITY'));
      expect(json['aliases'], contains('Article 14 Rights'));

      final restored = Concept.fromJson(json);
      expect(restored.id, equals(concept.id));
      expect(restored.knowledgeObjectIds, contains('KO_ART_14'));
    });

    test('ConfidenceScore categorization rules', () {
      expect(const ConfidenceScore(0.95).category, equals(ConfidenceCategory.exactMatch));
      expect(const ConfidenceScore(0.90).category, equals(ConfidenceCategory.exactMatch));
      expect(const ConfidenceScore(0.85).category, equals(ConfidenceCategory.strongMatch));
      expect(const ConfidenceScore(0.75).category, equals(ConfidenceCategory.strongMatch));
      expect(const ConfidenceScore(0.60).category, equals(ConfidenceCategory.possibleMatch));
      expect(const ConfidenceScore(0.50).category, equals(ConfidenceCategory.possibleMatch));
      expect(const ConfidenceScore(0.45).category, equals(ConfidenceCategory.rejected));
      expect(const ConfidenceScore(0.45).isAccepted, isFalse);
    });

    test('Question attributes extension (CognitiveLevel & QuestionNature)', () {
      final source = QuestionSource(
        sourceType: SourceType.officialPdf,
        publisher: 'UPSC',
        retrievedDate: DateTime.now(),
        checksum: '111',
      );

      final q = Question(
        id: 'Q_CONCEPT_TEST',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        originalQuestion: 'Which Article guarantees Equality?',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        garudaExplanation: 'Exp',
        source: source,
        conceptsTested: const ['C_RIGHT_TO_EQUALITY'],
        cognitiveLevel: CognitiveLevel.analyze,
        questionNature: QuestionNature.statementBased,
        examWeight: 2.5,
        frequency: 3,
      );

      expect(q.conceptsTested, contains('C_RIGHT_TO_EQUALITY'));
      expect(q.cognitiveLevel, equals(CognitiveLevel.analyze));
      expect(q.questionNature, equals(QuestionNature.statementBased));
      expect(q.examWeight, equals(2.5));
      expect(q.frequency, equals(3));
    });
  });
}
