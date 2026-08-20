import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/data/mock_ai_reading_provider.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_models.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_task.dart';
import 'package:titan_reader/src/providers/ai_reading_providers.dart';
import 'package:titan_reader/src/providers/reader_providers.dart';
import 'package:titan_reader/src/services/ai_reading_service.dart';
import 'package:titan_reader/src/widgets/ai_assistant_panel.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('Phase 5: AIAssistantPanel Widget Tests', () {
    late InMemoryStorageService storage;
    late MockAIReadingProvider mockProvider;

    setUp(() async {
      storage = InMemoryStorageService();
      await storage.initialize();
      mockProvider = MockAIReadingProvider(
        scriptedResponse:
            'Explanation: This is an explanation of relativity.\n\n'
            'Key Concept: Spacetime curvature.\n'
            'Important Terms: Spacetime, Curvature.',
      );
    });

    Widget createTestApp({
      required String text,
      AIReadingTask task = AIReadingTask.explain,
      String? documentId,
      int? pageNumber,
      void Function(int)? onNavigateToPage,
    }) {
      return ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          aiReadingServiceProvider.overrideWith((ref) {
            final configRepo = ref.watch(aiConfigRepositoryProvider);
            final cacheRepo = ref.watch(aiCacheRepositoryProvider);
            final convRepo = ref.watch(aiConversationRepositoryProvider);
            final flashcardRepo = ref.watch(aiFlashcardRepositoryProvider);
            return AIReadingService(
              configRepo: configRepo,
              cacheRepo: cacheRepo,
              conversationRepo: convRepo,
              flashcardRepo: flashcardRepo,
              providers: {
                AIProviderType.localOllama: mockProvider,
                AIProviderType.mock: mockProvider,
              },
              initialConfig: const AIConfig(providerType: AIProviderType.mock),
            );
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AIAssistantPanel(
              text: text,
              initialTask: task,
              documentId: documentId ?? 'doc_test',
              pageNumber: pageNumber ?? 1,
              onNavigateToPage: onNavigateToPage,
            ),
          ),
        ),
      );
    }

    testWidgets('Renders header, task tabs, and model badge', (tester) async {
      await tester.pumpWidget(createTestApp(text: 'Sample text to explain.'));
      await tester.pumpAndSettle();

      expect(find.text('AI Assistant'), findsOneWidget);
      expect(find.byKey(const Key('ai-panel-model-badge')), findsOneWidget);
      expect(find.text('Explain'), findsOneWidget);
      expect(find.text('Simplify'), findsOneWidget);
      expect(find.text('Summarize'), findsOneWidget);
      expect(find.text('Ask AI (Q&A)'), findsOneWidget);
    });

    testWidgets('Streams and displays AI response', (tester) async {
      await tester.pumpWidget(createTestApp(
          text:
              'General relativity postulates that gravity is spacetime curvature.'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai-response-text')), findsOneWidget);
      expect(find.textContaining('This is an explanation of relativity'),
          findsOneWidget);
    });

    testWidgets('Action buttons: Copy, Save Note, and Regenerate are present',
        (tester) async {
      await tester
          .pumpWidget(createTestApp(text: 'Text for action buttons test.'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai-copy-button')), findsOneWidget);
      expect(find.byKey(const Key('ai-save-note-button')), findsOneWidget);
      expect(find.byKey(const Key('ai-regenerate-button')), findsOneWidget);
    });

    testWidgets('Switching task tab triggers task execution', (tester) async {
      await tester
          .pumpWidget(createTestApp(text: 'Complex text for simplify.'));
      await tester.pumpAndSettle();

      mockProvider.scriptedResponse = 'Simplified text version.';
      await tester.tap(find.text('Simplify'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Simplified text version'), findsOneWidget);
    });

    testWidgets('Q&A input allows asking questions and displays results',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        text: 'Document context.',
        task: AIReadingTask.askQuestion,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai-question-input')), findsOneWidget);

      mockProvider.scriptedResponse =
          'Answer: Gravitational waves were predicted by Einstein.';
      await tester.enterText(find.byKey(const Key('ai-question-input')),
          'What are gravitational waves?');
      await tester.tap(find.byKey(const Key('ai-question-submit-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gravitational waves were predicted'),
          findsOneWidget);
    });

    testWidgets('Renders error card when provider fails', (tester) async {
      mockProvider.errorToThrow = Exception('Ollama failed to respond');

      await tester
          .pumpWidget(createTestApp(text: 'Text with failing provider.'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai-error-message')), findsOneWidget);
      expect(find.textContaining('Ollama failed to respond'), findsOneWidget);
    });
  });
}
