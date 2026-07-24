import 'ai_provider.dart';
import 'ai_provider_factory.dart';

class AiTutorEngine {
  final AIProvider? _overrideProvider;

  AiTutorEngine({AIProvider? provider}) : _overrideProvider = provider;

  AIProvider get _provider =>
      _overrideProvider ?? AiProviderFactory.getActiveProvider();

  /// 1. Explain Answer
  Future<String> explainAnswer({
    required String question,
    required String selectedAnswer,
    required String correctAnswer,
    String? context,
  }) async {
    return await _provider.explainAnswer(
      question: question,
      selectedAnswer: selectedAnswer,
      correctAnswer: correctAnswer,
      context: context,
    );
  }

  /// 2. Generate Mnemonic
  Future<String> generateMnemonic({
    required String topic,
    required String concept,
  }) async {
    return await _provider.generateMnemonic(
      topic: topic,
      concept: concept,
    );
  }

  /// 3. Suggest Revision Plan
  Future<String> suggestRevisionPlan({
    required List<String> weakTopics,
    required int totalDaysAvailable,
  }) async {
    return await _provider.suggestRevisionPlan(
      weakTopics: weakTopics,
      totalDaysAvailable: totalDaysAvailable,
    );
  }

  /// 4. Recommend PYQs
  Future<List<String>> recommendPyqs({
    required List<String> weakConcepts,
    required List<String> availablePyqTitles,
  }) async {
    return await _provider.recommendPyqs(
      weakConcepts: weakConcepts,
      availablePyqTitles: availablePyqTitles,
    );
  }

  /// 5. Generate Similar Questions
  Future<List<Map<String, dynamic>>> generateSimilarQuestions({
    required String questionText,
    required String subject,
    required String topic,
    int count = 3,
  }) async {
    return await _provider.generateSimilarQuestions(
      questionText: questionText,
      subject: subject,
      topic: topic,
      count: count,
    );
  }

  /// 6. Identify Weak Concepts
  Future<List<String>> identifyWeakConcepts({
    required Map<String, dynamic> analyticsSummary,
  }) async {
    return await _provider.identifyWeakConcepts(
      analyticsSummary: analyticsSummary,
    );
  }

  /// 7. Answer User Doubt
  Future<String> answerUserDoubt({
    required String doubtText,
    String? questionContext,
  }) async {
    return await _provider.answerUserDoubt(
      doubtText: doubtText,
      questionContext: questionContext,
    );
  }
}
