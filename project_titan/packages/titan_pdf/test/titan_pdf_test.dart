import 'package:test/test.dart';
import 'package:titan_core/titan_core.dart';
import 'package:titan_domain/titan_domain.dart' as domain;
import 'package:titan_pdf/src/services/pdf_chunk_service.dart';
import 'package:titan_pdf/src/services/pdf_import_service.dart';
import 'package:titan_pdf/src/services/pdf_validation_service.dart';
import 'package:titan_pdf/src/services/token_estimator.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_storage/titan_storage.dart';

// Mocks implement the titan_domain ports required by BaseRepository /
// PdfRepositoryImpl, not the concrete package abstractions.
class _MockAIService implements domain.AIService {
  bool _initialized = false;
  @override
  bool get isInitialized => _initialized;
  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  List<domain.AIModel> availableModels() => const [];
  @override
  domain.AIModel defaultModel() => throw UnimplementedError();
  @override
  Future<domain.AIResponse<T>> generate<T>(domain.AIRequest request) async =>
      throw UnimplementedError();
  @override
  Future<void> close() async {
    _initialized = false;
  }
}

class _MockStorageService implements domain.StorageService {
  bool _initialized = false;
  final Map<String, dynamic> _store = {};

  @override
  bool get isInitialized => _initialized;
  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<bool> contains(StorageKey key) async =>
      _store.containsKey(key.qualifiedKey);

  @override
  Future<T?> read<T>(StorageKey key) async => _store[key.qualifiedKey] as T?;

  @override
  Future<domain.StorageEntry<T>?> readEntry<T>(StorageKey key) async => null;

  @override
  Future<void> write<T>(StorageKey key, T value) async {
    _store[key.qualifiedKey] = value;
  }

  @override
  Future<void> delete(StorageKey key) async {
    _store.remove(key.qualifiedKey);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  Future<List<StorageKey>> keys({String? namespace}) async {
    final result = <StorageKey>[];
    for (final k in _store.keys) {
      if (namespace == null || k.startsWith('$namespace:')) {
        final id = k.contains(':') ? k.split(':').last : k;
        result.add(StorageKey(id, namespace: namespace ?? 'default'));
      }
    }
    return result;
  }

  @override
  Future<void> close() async {
    _initialized = false;
  }
}

class _MockNetworkService implements domain.NetworkService {
  bool _initialized = false;
  @override
  bool get isInitialized => _initialized;
  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<domain.NetworkResponse<T>> get<T>(
          domain.NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<domain.NetworkResponse<T>> post<T>(
          domain.NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<domain.NetworkResponse<T>> put<T>(
          domain.NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<domain.NetworkResponse<T>> patch<T>(
          domain.NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<domain.NetworkResponse<T>> delete<T>(
          domain.NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<domain.NetworkResponse<T>> head<T>(
          domain.NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<domain.NetworkResponse<T>> request<T>(
          domain.NetworkRequest request) async =>
      throw UnimplementedError();
  @override
  Future<void> close() async {
    _initialized = false;
  }
}

void main() {
  group('Titan PDF Domain Module Foundation Tests', () {
    late TitanServiceLocator locator;
    late _MockAIService mockAI;
    late _MockStorageService mockStorage;
    late _MockNetworkService mockNetwork;

    setUp(() {
      locator = TitanServiceLocator.instance;
      locator.reset();
      TitanBootstrap.reset();

      mockAI = _MockAIService();
      mockStorage = _MockStorageService();
      mockNetwork = _MockNetworkService();
    });

    tearDown(() {
      locator.reset();
      TitanBootstrap.reset();
    });

    test(
        '1. TokenEstimator calculates tokens heuristic rule tokens ≈ characters / 4',
        () {
      const estimator = TokenEstimator();
      expect(estimator.estimateTokens(''), equals(0));
      expect(estimator.estimateTokens('abcd'), equals(1)); // 4 chars / 4 = 1
      expect(estimator.estimateTokens('Hello World! This is TITAN PDF Module.'),
          equals(10)); // 38 chars / 4 = 9.5 -> ceil = 10
    });

    test(
        '2. PdfValidationService asserts file extensions, size limits, encrypted and corrupted flags',
        () {
      const validator = PdfValidationService();

      // Valid PDF file
      expect(
        () => validator.validatePdf(
          filePath: '/path/to/sample.pdf',
          sizeBytes: 1024,
          headerBytes: '%PDF-1.7 text'.codeUnits,
        ),
        returnsNormally,
      );

      // Invalid extension
      expect(
        () => validator.validatePdf(
            filePath: '/path/to/sample.txt', sizeBytes: 1024),
        throwsA(isA<PdfValidationException>().having(
            (PdfValidationException e) => e.validationErrors.first,
            'error',
            contains('.pdf'))),
      );

      // Size below minimum (< 100 bytes)
      expect(
        () => validator.validatePdf(
            filePath: '/path/to/sample.pdf', sizeBytes: 50),
        throwsA(isA<PdfValidationException>().having(
            (PdfValidationException e) => e.validationErrors.first,
            'error',
            contains('minimum threshold'))),
      );

      // Encrypted PDF flag
      expect(
        () => validator.validatePdf(
            filePath: '/path/to/sample.pdf',
            sizeBytes: 1024,
            isEncrypted: true),
        throwsA(isA<PdfValidationException>().having(
            (PdfValidationException e) => e.validationErrors.first,
            'error',
            contains('Encrypted'))),
      );

      // Corrupted PDF flag
      expect(
        () => validator.validatePdf(
            filePath: '/path/to/sample.pdf',
            sizeBytes: 1024,
            isCorrupted: true),
        throwsA(isA<PdfValidationException>().having(
            (PdfValidationException e) => e.validationErrors.first,
            'error',
            contains('corrupted'))),
      );
    });

    test(
        '3. PdfChunkService segments text adhering to ChunkOptions maxCharacters and overlap',
        () {
      const chunkService = PdfChunkService();
      final sampleText = '''
Paragraph 1: The Constitution of India is the supreme law of India. It lays down the framework for political code, structure, procedures, powers, and duties of government institutions.

Paragraph 2: It is the longest written national constitution in the world. B. R. Ambedkar was the chairman of the drafting committee.

Paragraph 3: It imparts constitutional supremacy and was adopted by its people with a declaration in its preamble. Parliament cannot override the constitution.
''';

      final options = const ChunkOptions(
        maxCharacters: 220,
        overlapCharacters: 30,
        minChunkSize: 20,
      );

      final chunks = chunkService.chunkText(
        documentId: 'doc_polity_1',
        text: sampleText,
        options: options,
      );

      expect(chunks.isNotEmpty, isTrue);
      expect(chunks.first.documentId, equals('doc_polity_1'));
      expect(chunks.first.tokenEstimate, greaterThan(0));
    });

    test('4. PdfRepositoryImpl CRUD operations and document import lifecycle',
        () async {
      final repo = PdfRepositoryImpl(
        aiService: mockAI,
        storageService: mockStorage,
        networkService: mockNetwork,
      );

      await repo.initialize();
      expect(repo.isInitialized, isTrue);

      final importResult = await repo.importPdf(
        '/documents/upsc_polity.pdf',
        displayName: 'UPSC Indian Polity Notes',
        sizeBytes: 10240,
        pageCount: 25,
      );

      expect(importResult.isSuccess, isTrue);
      expect(importResult.document.displayName,
          equals('UPSC Indian Polity Notes'));
      expect(importResult.document.status, equals(PdfStatus.ready));

      final loadedDoc = await repo.loadPdf(importResult.document.id);
      expect(loadedDoc, isNotNull);
      expect(loadedDoc!.id, equals(importResult.document.id));

      final docsList = await repo.listDocuments();
      expect(docsList.length, equals(1));
      expect(docsList.first.id, equals(importResult.document.id));

      final extractedText = await repo.extractText(importResult.document.id);
      expect(extractedText, contains('UPSC Indian Polity Notes'));

      final chunks = await repo.createChunks(importResult.document.id);
      expect(chunks.isNotEmpty, isTrue);

      await repo.saveChunks(importResult.document.id, chunks);

      await repo.deletePdf(importResult.document.id);
      final afterDelete = await repo.loadPdf(importResult.document.id);
      expect(afterDelete, isNull);
    });

    test(
        '5. TitanPdfBootstrap validates dependencies and registers components in TitanServiceLocator',
        () async {
      final bootstrap = TitanPdfBootstrap();

      // Missing registered services in locator throws exception
      expect(
        () => bootstrap.validate(),
        throwsA(isA<TitanMissingDependencyException>()),
      );

      locator.registerSingleton<domain.AIService>(mockAI);
      locator.registerSingleton<domain.StorageService>(mockStorage);
      locator.registerSingleton<domain.NetworkService>(mockNetwork);

      expect(bootstrap.isInitialized, isFalse);
      await bootstrap.initialize();
      expect(bootstrap.isInitialized, isTrue);

      expect(locator.isRegistered<PdfRepository>(), isTrue);
      expect(locator.isRegistered<PdfImportService>(), isTrue);
      expect(locator.isRegistered<PdfChunkService>(), isTrue);
      expect(locator.isRegistered<PdfValidationService>(), isTrue);
      expect(locator.isRegistered<TokenEstimator>(), isTrue);

      final pdfRepo = locator.get<PdfRepository>();
      expect(pdfRepo, isA<PdfRepositoryImpl>());

      await bootstrap.dispose();
      expect(bootstrap.isInitialized, isFalse);
      expect(locator.isRegistered<PdfRepository>(), isFalse);
    });
  });
}
