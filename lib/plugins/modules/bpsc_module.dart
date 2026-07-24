import 'package:flutter/material.dart';
import '../base/base_module.dart';

/// Bihar Public Service Commission (BPSC) Combined Competitive Exam Module Plugin.
class BpscModule extends BaseQuizModule {
  BpscModule()
      : super(
          id: 'bpsc',
          name: 'BPSC State PCS',
          description:
              'Bihar Public Service Commission Combined Competitive Exam practice with Bihar Special GS, History, and State Geography.',
          version: '1.0.0',
          category: 'State Services',
          icon: Icons.location_city,
          themeColor: Colors.teal,
        );
}
