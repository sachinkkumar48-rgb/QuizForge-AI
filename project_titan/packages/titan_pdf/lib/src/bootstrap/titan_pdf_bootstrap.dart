import 'package:titan_core/titan_core.dart';
import 'package:titan_domain/titan_domain.dart';

import '../repository/pdf_repository.dart';
import '../repository/pdf_repository_impl.dart';
import '../services/pdf_chunk_service.dart';
import '../services/pdf_import_service.dart';
import '../services/pdf_validation_service.dart';
import '../services/token_estimator.dart';

/// Central startup bootstrap coordinator for the TITAN PDF Domain Module.
class TitanPdfBootstrap implements TitanModuleBootstrap {
  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  void validate() {
    final locator = TitanServiceLocator.instance;
    TitanModuleValidator.validateRegisteredServices(
      locator,
      [AIService, StorageService, NetworkService],
    );
  }

  @override
  void registerDependencies(TitanServiceLocator locator) {
    const tokenEstimator = TokenEstimator();
    const validationService = PdfValidationService();
    const chunkService = PdfChunkService(tokenEstimator: tokenEstimator);
    const importService =
        PdfImportService(validationService: validationService);

    locator.registerSingleton<TokenEstimator>(tokenEstimator,
        allowOverride: true);
    locator.registerSingleton<PdfValidationService>(validationService,
        allowOverride: true);
    locator.registerSingleton<PdfChunkService>(chunkService,
        allowOverride: true);
    locator.registerSingleton<PdfImportService>(importService,
        allowOverride: true);

    locator.registerLazySingleton<PdfRepository>(
      () => PdfRepositoryImpl(
        aiService: locator.get<AIService>(),
        storageService: locator.get<StorageService>(),
        networkService: locator.get<NetworkService>(),
        importService: importService,
        chunkService: chunkService,
      ),
      allowOverride: true,
    );
  }

  @override
  Future<void> initialize() async {
    validate();
    registerDependencies(TitanServiceLocator.instance);
    _isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    final locator = TitanServiceLocator.instance;
    if (locator.isRegistered<PdfRepository>()) {
      final repo = locator.get<PdfRepository>();
      await repo.dispose();
      locator.unregister<PdfRepository>();
    }
    if (locator.isRegistered<PdfImportService>()) {
      locator.unregister<PdfImportService>();
    }
    if (locator.isRegistered<PdfChunkService>()) {
      locator.unregister<PdfChunkService>();
    }
    if (locator.isRegistered<PdfValidationService>()) {
      locator.unregister<PdfValidationService>();
    }
    if (locator.isRegistered<TokenEstimator>()) {
      locator.unregister<TokenEstimator>();
    }
    _isInitialized = false;
  }
}
