import 'dart:async';
import 'package:test/test.dart';
import 'package:titan_ai/titan_ai.dart';
import 'package:titan_core/titan_core.dart';
import 'package:titan_network/titan_network.dart';

class _MockAIProvider implements AIProvider {
  final String _name;
  bool _initialized = false;

  _MockAIProvider({String name = 'mock_provider'}) : _name = name;

  @override
  String get name => _name;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  List<AIModel> models() => const [
        AIModel(
          id: 'mock-model-1',
          displayName: 'Mock Model 1',
          contextWindow: 4096,
          maxOutputTokens: 1024,
        )
      ];

  @override
  AIModel defaultModel() => models().first;

  @override
  Future<AIResponse<T>> generate<T>(AIRequest request) async {
    if (!_initialized) {
      throw const AIInitializationException('Provider not initialized.');
    }
    return AIResponse<T>(
      text: 'Completion for: ${request.prompt}',
      usage: const AITokenUsage(
          promptTokens: 10, completionTokens: 5, totalTokens: 15),
      model: request.model ?? defaultModel().id,
      provider: name,
      finishReason: 'STOP',
    );
  }

  @override
  Stream<String> generateStream(AIRequest request) async* {
    yield 'Completion for: ${request.prompt}';
  }

  @override
  Future<void> close() async {
    _initialized = false;
  }
}

class _MockNetworkService implements NetworkService {
  bool _initialized = false;
  NetworkRequest? lastPostRequest;
  int statusCodeToReturn = 200;
  Object? bodyToReturn;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<NetworkResponse<T>> post<T>(NetworkRequest request) async {
    lastPostRequest = request;
    final defaultBody = <String, dynamic>{
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': 'Mock Gemini Response'}
            ]
          },
          'finishReason': 'STOP'
        }
      ],
      'usageMetadata': {
        'promptTokenCount': 12,
        'candidatesTokenCount': 8,
        'totalTokenCount': 20
      }
    };

    return NetworkResponse<T>(
      statusCode: statusCodeToReturn,
      body: (bodyToReturn ?? defaultBody) as T?,
      request: request,
    );
  }

  @override
  Future<NetworkResponse<T>> get<T>(NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<NetworkResponse<T>> put<T>(NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<NetworkResponse<T>> patch<T>(NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<NetworkResponse<T>> delete<T>(NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<NetworkResponse<T>> head<T>(NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<NetworkResponse<T>> request<T>(NetworkRequest request) async =>
      throw UnimplementedError();

  @override
  Future<void> close() async {
    _initialized = false;
  }
}

void main() {
  group('Titan AI Foundation Tests', () {
    late TitanServiceLocator locator;

    setUp(() {
      locator = TitanServiceLocator.instance;
      locator.reset();
      TitanBootstrap.reset();
    });

    tearDown(() {
      locator.reset();
      TitanBootstrap.reset();
    });

    test('1. AIRequest immutability and copyWith', () {
      final request = AIRequest(
        prompt: 'Generate 5 MCQs on Indian History',
        systemPrompt: 'You are an expert UPSC tutor',
        temperature: 0.7,
        maxTokens: 500,
        metadata: const {'subject': 'History'},
      );

      expect(request.prompt, equals('Generate 5 MCQs on Indian History'));
      expect(request.systemPrompt, equals('You are an expert UPSC tutor'));
      expect(request.temperature, equals(0.7));
      expect(request.maxTokens, equals(500));
      expect(request.metadata['subject'], equals('History'));

      final modified = request.copyWith(temperature: 0.2);
      expect(modified.temperature, equals(0.2));
      expect(modified.prompt, equals(request.prompt));
    });

    test('2. AIResponse model creation and token usage', () {
      const usage = AITokenUsage(
          promptTokens: 50, completionTokens: 150, totalTokens: 200);
      final response = AIResponse<String>(
        text: 'Generated Quiz',
        usage: usage,
        model: 'gemini-1.5-flash',
        provider: 'gemini',
        finishReason: 'STOP',
      );

      expect(response.text, equals('Generated Quiz'));
      expect(response.usage.promptTokens, equals(50));
      expect(response.usage.completionTokens, equals(150));
      expect(response.usage.totalTokens, equals(200));
      expect(response.provider, equals('gemini'));
      expect(response.finishReason, equals('STOP'));
    });

    test('3. Token usage zero factory and equality', () {
      const usage1 = AITokenUsage.zero();
      const usage2 =
          AITokenUsage(promptTokens: 0, completionTokens: 0, totalTokens: 0);

      expect(usage1.promptTokens, equals(0));
      expect(usage1.completionTokens, equals(0));
      expect(usage1.totalTokens, equals(0));
      expect(usage1, equals(usage2));
      expect(usage1.hashCode, equals(usage2.hashCode));
    });

    test('4. AIModel metadata properties', () {
      const model = AIModel(
        id: 'gemini-1.5-pro',
        displayName: 'Gemini 1.5 Pro',
        contextWindow: 2097152,
        supportsVision: true,
        supportsStreaming: true,
        supportsJson: true,
        maxOutputTokens: 8192,
      );

      expect(model.id, equals('gemini-1.5-pro'));
      expect(model.supportsVision, isTrue);
      expect(model.supportsStreaming, isTrue);
      expect(model.supportsJson, isTrue);
      expect(model.contextWindow, equals(2097152));
      expect(model.maxOutputTokens, equals(8192));
    });

    test('5. AIProviderRegistry registration, resolution, and fallback', () {
      final registry = AIProviderRegistry();
      final provider1 = _MockAIProvider(name: 'p1');
      final provider2 = _MockAIProvider(name: 'p2');

      registry.register(provider1, setAsDefault: true);
      registry.register(provider2);

      expect(registry.providers.length, equals(2));
      expect(registry.provider('p1').name, equals('p1'));
      expect(registry.defaultProvider().name, equals('p1'));

      registry.unregister('p1');
      expect(registry.providers.length, equals(1));
      expect(registry.defaultProvider().name, equals('p2'));

      expect(() => registry.provider('unknown'),
          throwsA(isA<AIProviderException>()));
    });

    test(
        '6. GeminiProvider REST API request payload formatting and timeout passing',
        () async {
      final mockNetService = _MockNetworkService();
      await mockNetService.initialize();

      final gemini = GeminiProvider(
        apiKey: 'test-api-key',
        networkService: mockNetService,
        timeout: const Duration(seconds: 15),
      );
      await gemini.initialize();

      expect(gemini.isInitialized, isTrue);

      final request = AIRequest(
        prompt: 'Explain Article 21',
        systemPrompt: 'Be concise',
        temperature: 0.2,
      );

      final response = await gemini.generate<String>(request);

      expect(response.text, equals('Mock Gemini Response'));
      expect(response.provider, equals('gemini'));
      expect(response.usage.totalTokens, equals(20));

      expect(mockNetService.lastPostRequest, isNotNull);
      final netReq = mockNetService.lastPostRequest!;
      expect(netReq.queryParameters['key'], equals('test-api-key'));
      expect(netReq.url, contains('/models/gemini-1.5-flash:generateContent'));
      expect(netReq.timeout, equals(const Duration(seconds: 15)));
    });

    test('7. GeminiProvider maps HTTP errors to AIResponseException', () async {
      final mockNetService = _MockNetworkService();
      await mockNetService.initialize();
      mockNetService.statusCodeToReturn = 500;

      final gemini = GeminiProvider(
        apiKey: 'test-api-key',
        networkService: mockNetService,
      );
      await gemini.initialize();

      final request = AIRequest(prompt: 'Test prompt');
      expect(
        () => gemini.generate<String>(request),
        throwsA(isA<AIResponseException>().having(
            (AIResponseException e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('8. PromptTemplate placeholder rendering', () {
      const template = PromptTemplate(
        id: 'upsc_quiz_v1',
        name: 'UPSC Question Generator',
        template:
            'Subject: {{subject}}. Topic: {topic}. Difficulty: {{difficulty}}.',
        version: '1.0',
      );

      final rendered = template.render({
        'subject': 'Polity',
        'topic': 'Preamble',
        'difficulty': 'Hard',
      });

      expect(rendered,
          equals('Subject: Polity. Topic: Preamble. Difficulty: Hard.'));
    });

    test('9. TitanAIService routes requests to active registered provider',
        () async {
      final registry = AIProviderRegistry();
      final mockProvider = _MockAIProvider(name: 'mock_ai');
      registry.register(mockProvider, setAsDefault: true);

      final aiService = TitanAIService(registry: registry);
      await aiService.initialize();

      expect(aiService.isInitialized, isTrue);
      expect(aiService.availableModels().length, equals(1));
      expect(aiService.defaultModel().id, equals('mock-model-1'));

      final request = AIRequest(prompt: 'What is GST?');
      final response = await aiService.generate<String>(request);

      expect(response.text, equals('Completion for: What is GST?'));
      expect(response.provider, equals('mock_ai'));

      await aiService.close();
      expect(aiService.isInitialized, isFalse);
    });

    test(
        '10. TitanAIBootstrap initializes and registers components in TitanServiceLocator',
        () async {
      final mockProvider = _MockAIProvider(name: 'custom_ai');

      final service = await TitanAIBootstrap.initialize(
        customProvider: mockProvider,
      );

      expect(service.isInitialized, isTrue);
      expect(locator.isRegistered<AIService>(), isTrue);
      expect(locator.isRegistered<AIProviderRegistry>(), isTrue);

      final resolvedService = locator.get<AIService>();
      expect(identical(resolvedService, service), isTrue);
    });

    test('11. TitanAIBootstrap with TitanConfig registers GeminiProvider',
        () async {
      final mockNetService = _MockNetworkService();
      await mockNetService.initialize();
      locator.registerSingleton<NetworkService>(mockNetService);

      final config = TitanConfig(
        titanEnvironment: TitanEnvironment.development,
        appName: 'TestApp',
        version: '1.0.0',
        buildNumber: 1,
        isDebug: true,
        featureFlags: const {},
        apiBaseUrl: 'https://api-dev.quizforge.ai',
        enableLogging: false,
        enableAnalytics: false,
        aiApiKey: 'valid-api-key',
        aiDefaultModel: 'gemini-1.5-pro',
        aiTimeout: const Duration(seconds: 20),
      );

      final service = await TitanAIBootstrap.initialize(
        config: config,
      );

      expect(service.isInitialized, isTrue);
      expect(locator.isRegistered<AIService>(), isTrue);
      expect(locator.isRegistered<AIProviderRegistry>(), isTrue);
      expect(locator.isRegistered<GeminiProvider>(), isTrue);

      final gemini = locator.get<GeminiProvider>();
      expect(gemini.defaultModel().id, equals('gemini-1.5-pro'));
    });

    test('12. AIException hierarchy toString representation', () {
      const initEx = AIInitializationException('Init failed');
      const reqEx = AIRequestException('Invalid request');
      const respEx = AIResponseException('API Error', 500);
      const provEx = AIProviderException('Provider missing', 'openai');
      const modelEx = AIModelException('Model missing', 'gpt-4');

      expect(initEx.toString(),
          contains('AIInitializationException: Init failed'));
      expect(reqEx.toString(), contains('AIRequestException: Invalid request'));
      expect(respEx.statusCode, equals(500));
      expect(provEx.providerName, equals('openai'));
      expect(modelEx.modelId, equals('gpt-4'));
    });
  });
}
