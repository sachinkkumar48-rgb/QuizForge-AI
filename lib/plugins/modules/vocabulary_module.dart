import 'package:flutter/material.dart';
import '../base/base_module.dart';

/// Vocabulary & Word Power Module Plugin.
class VocabularyModule extends BaseQuizModule {
  VocabularyModule()
      : super(
          id: 'vocabulary',
          name: 'Vocabulary Builder',
          description:
              'Advanced English and Hindi vocabulary booster with synonyms, antonyms, one-word substitutions, and flashcards.',
          version: '1.0.0',
          category: 'Language Skills',
          icon: Icons.spellcheck,
          themeColor: Colors.pink,
        );
}
