import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/models/explanation.dart';
import 'package:quizforge_upsc/models/view/question_with_details.dart';
import 'package:quizforge_upsc/models/question.dart';

void main() {
  group('Explanation Source Metadata & Serialization Tests', () {
    test(
        'Explanation entity correctly parses and serializes full source metadata',
        () {
      final now = DateTime(2025, 7, 18, 12, 0, 0);

      final explanation = Explanation(
        explanationId: 'exp_upsc_2025_001_off',
        questionId: 'UPSC_PRE_GS1_2025_Q001',
        explanationType: 'Official UPSC',
        content:
            'Kesavananda Bharati case 1973 established Preamble basic structure.',
        source: 'Official UPSC Answer Key 2025',
        author: 'UPSC Examination Board',
        version: '1.2.0',
        language: 'English',
        lastUpdated: now,
      );

      expect(explanation.id, equals('exp_upsc_2025_001_off'));
      expect(explanation.explanationType, equals('Official UPSC'));
      expect(explanation.source, equals('Official UPSC Answer Key 2025'));
      expect(explanation.author, equals('UPSC Examination Board'));
      expect(explanation.version, equals('1.2.0'));
      expect(explanation.language, equals('English'));
      expect(explanation.lastUpdated, equals(now));

      final json = explanation.toJson();
      expect(json['source'], equals('Official UPSC Answer Key 2025'));
      expect(json['author'], equals('UPSC Examination Board'));
      expect(json['version'], equals('1.2.0'));
      expect(json['language'], equals('English'));

      final reconstructed = Explanation.fromJson(json);
      expect(reconstructed.source, equals('Official UPSC Answer Key 2025'));
      expect(reconstructed.author, equals('UPSC Examination Board'));
      expect(reconstructed.version, equals('1.2.0'));
      expect(reconstructed.language, equals('English'));
    });

    test(
        'Supports multiple explanations per question (Official, AI, Editorial, Hindi, Notes)',
        () {
      final question = Question(
        id: 'UPSC_PRE_GS1_2025_Q001',
        exam: 'UPSC CSE Prelims',
        year: 2025,
        paper: 'GS Paper 1',
        subject: 'Polity',
        topic: 'Preamble',
        difficulty: 'Medium',
        question: 'Preamble question text',
        options: ['A', 'B'],
        correctAnswer: 'A',
      );

      final explanationsList = [
        Explanation(
          explanationId: 'exp_1',
          questionId: question.id,
          explanationType: 'Official',
          content: 'Official UPSC Key Content',
          source: 'Official UPSC Key',
          author: 'UPSC',
        ),
        Explanation(
          explanationId: 'exp_2',
          questionId: question.id,
          explanationType: 'AI_Generated',
          content: 'AI Explanation Content',
          source: 'Gemini 1.5 Flash',
          author: 'Gemini AI',
        ),
        Explanation(
          explanationId: 'exp_3',
          questionId: question.id,
          explanationType: 'Editorial',
          content: 'Editorial Analysis',
          source: 'QuizForge Experts',
          author: 'Subject Expert',
        ),
        Explanation(
          explanationId: 'exp_4',
          questionId: question.id,
          explanationType: 'Translated_Hindi',
          content: 'प्रस्तावना संविधान का अभिन्न अंग है।',
          source: 'QuizForge Hindi Team',
          language: 'Hindi',
          author: 'Hindi Editor',
        ),
      ];

      final details = QuestionWithDetails(
        question: question,
        explanations: explanationsList,
      );

      expect(details.explanations.length, equals(4));
      expect(details.officialExplanation, isNotNull);
      expect(details.officialExplanation!.source, equals('Official UPSC Key'));
      expect(details.aiExplanation, isNotNull);
      expect(details.aiExplanation!.source, equals('Gemini 1.5 Flash'));
      expect(details.editorialExplanation, isNotNull);
      expect(details.editorialExplanation!.source, equals('QuizForge Experts'));
    });
  });
}
