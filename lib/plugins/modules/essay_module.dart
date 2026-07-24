import 'package:flutter/material.dart';
import '../base/base_module.dart';

/// Essay Writing & Outlines Module Plugin.
class EssayModule extends BaseQuizModule {
  EssayModule()
      : super(
          id: 'essay',
          name: 'Essay & Answer Writing',
          description:
              'Mains essay writing prompts, philosophical essay themes, quotes repository, and AI structure evaluator.',
          version: '1.0.0',
          category: 'Writing Skills',
          icon: Icons.history_edu,
          themeColor: Colors.indigo,
        );
}
