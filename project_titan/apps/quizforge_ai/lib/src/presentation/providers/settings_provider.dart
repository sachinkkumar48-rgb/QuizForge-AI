import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable model representing UI settings preferences.
class AppSettingsState {
  final String languageCode;
  final bool highContrast;
  final int defaultQuestionsPerChunk;

  const AppSettingsState({
    this.languageCode = 'en',
    this.highContrast = false,
    this.defaultQuestionsPerChunk = 5,
  });

  AppSettingsState copyWith({
    String? languageCode,
    bool? highContrast,
    int? defaultQuestionsPerChunk,
  }) {
    return AppSettingsState(
      languageCode: languageCode ?? this.languageCode,
      highContrast: highContrast ?? this.highContrast,
      defaultQuestionsPerChunk:
          defaultQuestionsPerChunk ?? this.defaultQuestionsPerChunk,
    );
  }
}

/// Notifier coordinating UI application settings.
class SettingsNotifier extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    return const AppSettingsState();
  }

  void setHighContrast(bool enabled) {
    state = state.copyWith(highContrast: enabled);
  }

  void setLanguage(String code) {
    state = state.copyWith(languageCode: code);
  }

  void setDefaultQuestionsPerChunk(int count) {
    state = state.copyWith(defaultQuestionsPerChunk: count);
  }
}

/// Provider managing active UI settings.
final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettingsState>(SettingsNotifier.new);
