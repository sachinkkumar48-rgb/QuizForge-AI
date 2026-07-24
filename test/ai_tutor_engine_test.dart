import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/services/ai/ai_provider.dart';
import 'package:quizforge_upsc/services/ai/ai_provider_factory.dart';
import 'package:quizforge_upsc/services/ai/ai_tutor_engine.dart';
import 'package:quizforge_upsc/services/ai/providers/claude_provider.dart';
import 'package:quizforge_upsc/services/ai/providers/gemini_provider.dart';
import 'package:quizforge_upsc/services/ai/providers/local_llm_provider.dart';
import 'package:quizforge_upsc/services/ai/providers/openai_provider.dart';

class MockAiProvider implements AIProvider {
  final String id;
  final String name;

  MockAiProvider(this.id, this.name);

  @override
  String get providerId => id;

  @override
  String get providerName => name;

  @override
  Future<bool> isConfigured() async => true;

  @override
  Future<String> explainAnswer({
    required String question,
    required String selectedAnswer,
    required String correctAnswer,
    String? context,
  }) async =>
      "[$name] Explanation for $question: Correct answer is $correctAnswer.";

  @override
  Future<String> generateMnemonic({
    required String topic,
    required String concept,
  }) async =>
      "[$name] Mnemonic for $topic: $concept -> MEM-123.";

  @override
  Future<String> suggestRevisionPlan({
    required List<String> weakTopics,
    required int totalDaysAvailable,
  }) async =>
      "[$name] $totalDaysAvailable-Day Plan: Focus on ${weakTopics.join(', ')}.";

  @override
  Future<List<String>> recommendPyqs({
    required List<String> weakConcepts,
    required List<String> availablePyqTitles,
  }) async =>
      availablePyqTitles.take(2).toList();

  @override
  Future<List<Map<String, dynamic>>> generateSimilarQuestions({
    required String questionText,
    required String subject,
    required String topic,
    int count = 3,
  }) async =>
      List.generate(
        count,
        (i) => {
          "question": "[$name] Similar Q${i + 1} for $topic",
          "options": ["A", "B", "C", "D"],
          "answer": "A",
          "explanation": "Exp",
          "difficulty": "Medium",
        },
      );

  @override
  Future<List<String>> identifyWeakConcepts({
    required Map<String, dynamic> analyticsSummary,
  }) async =>
      ["Polity Preamble", "Monetary Policy"];

  @override
  Future<String> answerUserDoubt({
    required String doubtText,
    String? questionContext,
  }) async =>
      "[$name] Answer to doubt '$doubtText'.";
}

void main() {
  group('AI Tutor Architecture & Multi-Provider Tests', () {
    late MockAiProvider mockGemini;
    late MockAiProvider mockOpenAi;

    setUp(() {
      AiProviderFactory.reset();
      mockGemini = MockAiProvider('gemini', 'Mock Gemini');
      mockOpenAi = MockAiProvider('openai', 'Mock OpenAI');

      AiProviderFactory.registerProvider(AiProviderType.gemini, mockGemini);
      AiProviderFactory.registerProvider(AiProviderType.openAi, mockOpenAi);
    });

    test('Verifies all 7 AI Tutor Capabilities through AiTutorEngine',
        () async {
      final engine = AiTutorEngine();

      // 1. Explain Answer
      final explanation = await engine.explainAnswer(
        question: "What is Preamble?",
        selectedAnswer: "B",
        correctAnswer: "A",
      );
      expect(explanation, contains('Mock Gemini'));
      expect(explanation, contains('Correct answer is A'));

      // 2. Generate Mnemonic
      final mnemonic = await engine.generateMnemonic(
        topic: "Polity",
        concept: "Fundamental Rights",
      );
      expect(mnemonic, contains('MEM-123'));

      // 3. Suggest Revision Plan
      final plan = await engine.suggestRevisionPlan(
        weakTopics: ["Polity", "Economy"],
        totalDaysAvailable: 7,
      );
      expect(plan, contains('7-Day Plan'));

      // 4. Recommend PYQs
      final pyqs = await engine.recommendPyqs(
        weakConcepts: ["Monetary Policy"],
        availablePyqTitles: ["PYQ 2024 #1", "PYQ 2023 #2", "PYQ 2022 #3"],
      );
      expect(pyqs.length, equals(2));

      // 5. Generate Similar Questions
      final questions = await engine.generateSimilarQuestions(
        questionText: "Sample question?",
        subject: "Polity",
        topic: "Preamble",
        count: 3,
      );
      expect(questions.length, equals(3));

      // 6. Identify Weak Concepts
      final weakConcepts = await engine.identifyWeakConcepts(
        analyticsSummary: {"polityAccuracy": 40.0},
      );
      expect(weakConcepts, contains("Polity Preamble"));

      // 7. Answer User Doubt
      final doubtAnswer = await engine.answerUserDoubt(
        doubtText: "What is Article 32?",
      );
      expect(doubtAnswer, contains("Answer to doubt"));
    });

    test('Seamless Provider Switching (Gemini -> OpenAI)', () async {
      final engine = AiTutorEngine();

      // Active is Gemini by default
      final geminiRes = await engine.explainAnswer(
        question: "Q1",
        selectedAnswer: "A",
        correctAnswer: "A",
      );
      expect(geminiRes, contains('Mock Gemini'));

      // Switch active provider to OpenAI
      AiProviderFactory.setActiveProvider(AiProviderType.openAi);

      final openAiRes = await engine.explainAnswer(
        question: "Q1",
        selectedAnswer: "A",
        correctAnswer: "A",
      );
      expect(openAiRes, contains('Mock OpenAI'));
    });

    test(
        'Instantiates real provider classes for Gemini, OpenAI, Claude, Local LLM',
        () {
      final gemini = GeminiProvider();
      final openAi = OpenAiProvider(apiKey: 'test_key');
      final claude = ClaudeProvider(apiKey: 'test_key');
      final localLlm = LocalLlmProvider();

      expect(gemini.providerId, equals('gemini'));
      expect(openAi.providerId, equals('openai'));
      expect(claude.providerId, equals('claude'));
      expect(localLlm.providerId, equals('local_llm'));
    });
  });
}
