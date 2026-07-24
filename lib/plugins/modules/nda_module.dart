import 'package:flutter/material.dart';
import '../base/base_module.dart';

/// National Defence Academy (NDA) Exam Module Plugin.
class NdaModule extends BaseQuizModule {
  NdaModule()
      : super(
          id: 'nda',
          name: 'NDA Defence Exam',
          description:
              'National Defence Academy & Naval Academy Examination prep covering Mathematics, Physics, Chemistry, English, and General Knowledge.',
          version: '1.0.0',
          category: 'Defence',
          icon: Icons.shield,
          themeColor: Colors.red,
        );
}
