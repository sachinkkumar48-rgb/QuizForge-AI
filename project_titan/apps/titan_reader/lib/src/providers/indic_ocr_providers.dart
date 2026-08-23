import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/ocr/indic_language_pack.dart';
import '../ocr/indic/bilingual_ocr_router.dart';
import '../ocr/indic/indic_ocr_session_manager.dart';
import '../ocr/indic/line_script_classifier.dart';
import '../services/indic_language_pack_manager.dart';

/// Provider for the application [IndicLanguagePackManager] coordinator.
final indicLanguagePackManagerProvider =
    Provider<IndicLanguagePackManager>((ref) {
  final manager = IndicLanguagePackManager();
  // Register the foundation descriptor for Hindi by default
  manager.registerPack(IndicLanguagePack.hindiFoundationDescriptor);
  return manager;
});

/// Provider exposing all discovered Indic language packs.
final allIndicPacksProvider = Provider<List<IndicLanguagePack>>((ref) {
  final manager = ref.watch(indicLanguagePackManagerProvider);
  return manager.allPacks;
});

/// Provider exposing only verified, ready-for-inference Indic language packs.
final readyIndicPacksProvider = Provider<List<IndicLanguagePack>>((ref) {
  final manager = ref.watch(indicLanguagePackManagerProvider);
  return manager.readyPacks;
});

/// Provider returning the current state of the Hindi / Devanagari language pack.
final hindiLanguagePackProvider = Provider<IndicLanguagePack>((ref) {
  final manager = ref.watch(indicLanguagePackManagerProvider);
  return manager.getPackByLanguage('hi') ??
      IndicLanguagePack.hindiFoundationDescriptor;
});

/// Provider for the [LineScriptClassifier] instance.
final lineScriptClassifierProvider = Provider<LineScriptClassifier>((ref) {
  return const UnicodeLineScriptClassifier();
});

/// Provider for the [IndicOcrSessionManager] coordinator.
final indicOcrSessionManagerProvider = Provider<IndicOcrSessionManager>((ref) {
  final packManager = ref.watch(indicLanguagePackManagerProvider);
  final sessionManager = IndicOcrSessionManager(
    packManager: packManager,
    maxActiveSessions: 2,
  );
  ref.onDispose(() {
    sessionManager.disposeAll();
  });
  return sessionManager;
});

/// Provider for the [BilingualOcrRouter] coordinator.
final bilingualOcrRouterProvider = Provider<BilingualOcrRouter>((ref) {
  final classifier = ref.watch(lineScriptClassifierProvider);
  final sessionManager = ref.watch(indicOcrSessionManagerProvider);
  return BilingualOcrRouter(
    classifier: classifier,
    sessionManager: sessionManager,
  );
});
