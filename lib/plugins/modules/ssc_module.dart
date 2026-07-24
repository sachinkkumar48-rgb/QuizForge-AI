import 'package:flutter/material.dart';
import '../base/base_module.dart';

/// Staff Selection Commission (SSC) CGL / CHSL Module Plugin.
class SscModule extends BaseQuizModule {
  SscModule()
      : super(
          id: 'ssc',
          name: 'SSC CGL / CHSL',
          description:
              'Staff Selection Commission Tier 1 & Tier 2 prep covering Quantitative Aptitude, English, Reasoning, and General Awareness.',
          version: '1.0.0',
          category: 'Staff Selection',
          icon: Icons.assessment,
          themeColor: Colors.blue,
        );
}
