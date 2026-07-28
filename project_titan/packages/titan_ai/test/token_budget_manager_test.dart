import 'package:test/test.dart';
import 'package:titan_ai/titan_ai.dart';

void main() {
  group('TokenBudgetManager Tests', () {
    late TokenBudgetManager manager;

    setUp(() {
      manager = TokenBudgetManager(defaultMaxContextTokens: 100);
    });

    test('estimates token count heuristically', () {
      final estimate =
          manager.estimateTokens('This is a test prompt for UPSC preparation.');
      expect(estimate, greaterThan(0));
    });

    test('tracks and resets token usage', () {
      manager.trackUsage(50);
      manager.trackUsage(30);
      expect(manager.accumulatedTokenUsage, equals(80));

      manager.resetUsage();
      expect(manager.accumulatedTokenUsage, equals(0));
    });

    test('trims long prompts exceeding budget', () {
      final longPrompt = 'word ' * 200;
      final trimmed = manager.trimPrompt(longPrompt, maxTokens: 20);
      expect(trimmed.length, lessThan(longPrompt.length));
    });

    test('trims conversation history starting from oldest messages', () {
      final history = [
        {'role': 'system', 'content': 'System prompt'},
        {'role': 'user', 'content': 'First query'},
        {'role': 'assistant', 'content': 'First answer'},
        {'role': 'user', 'content': 'Second query'},
      ];

      final trimmed = manager.trimConversationHistory(history, maxTokens: 30);
      expect(trimmed.isNotEmpty, isTrue);
      expect(trimmed.any((m) => m['role'] == 'system'), isTrue);
    });
  });
}
