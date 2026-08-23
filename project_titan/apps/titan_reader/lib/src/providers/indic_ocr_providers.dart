import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/ocr/indic_language_pack.dart';
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
