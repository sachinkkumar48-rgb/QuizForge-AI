import 'package:test/test.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';

void main() {
  group('QuizPromptBuilder Tests', () {
    const builder = QuizPromptBuilder();

    test('buildSystemPrompt returns JSON schema instructions and exam rules',
        () {
      final sysPrompt = builder.buildSystemPrompt();
      expect(sysPrompt, contains('JSON schema'));
      expect(sysPrompt, contains('"title":'));
      expect(sysPrompt, contains('"questions":'));
      expect(sysPrompt, contains('"correctAnswer":'));
    });

    test(
        'buildUserPrompt formats difficulty, language, category, question count, and text',
        () {
      final request = QuizGenerationRequest(
        documentId: 'doc_polity_101',
        category: QuizCategory.upsc,
        difficulty: QuizDifficulty.hard,
        language: QuizLanguage.english,
        questionsPerChunk: 5,
      );

      final userPrompt = builder.buildUserPrompt(
        sourceText:
            'Article 32 of the Indian Constitution provides the Right to Constitutional Remedies...',
        request: request,
      );

      expect(userPrompt, contains('UPSC Civil Services Examination'));
      expect(userPrompt, contains('Hard'));
      expect(userPrompt, contains('English'));
      expect(userPrompt, contains('Number of Questions: 5'));
      expect(userPrompt, contains('Article 32 of the Indian Constitution'));
    });

    test('buildUserPrompt throws PromptException if sourceText is empty', () {
      final request = QuizGenerationRequest(documentId: 'doc_1');
      expect(
        () => builder.buildUserPrompt(sourceText: '   ', request: request),
        throwsA(isA<PromptException>()),
      );
    });
  });
}
