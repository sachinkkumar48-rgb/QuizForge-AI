library;

import '../../models/option_model.dart';

class OptionExtractor {
  /// Extracts structured Option list from raw option strings or question block text.
  static List<Option> extractOptions(List<String> rawOptions, {String? correctKey}) {
    final options = <Option>[];
    final defaultKeys = ['A', 'B', 'C', 'D'];

    if (rawOptions.isNotEmpty) {
      for (int i = 0; i < rawOptions.length; i++) {
        final raw = rawOptions[i];
        final parts = raw.split(':');
        final key = parts.length > 1 ? parts[0].trim().toUpperCase() : (i < defaultKeys.length ? defaultKeys[i] : 'OPT_${i + 1}');
        final text = parts.length > 1 ? parts.sublist(1).join(':').trim() : raw.trim();

        options.add(Option(
          key: key,
          text: text,
          isCorrect: correctKey != null && key == correctKey.toUpperCase(),
        ));
      }
    } else {
      // Standard default 4 options if not parsed explicitly
      for (final key in defaultKeys) {
        options.add(Option(
          key: key,
          text: 'Option $key Text',
          isCorrect: correctKey != null && key == correctKey.toUpperCase(),
        ));
      }
    }

    return options;
  }
}
