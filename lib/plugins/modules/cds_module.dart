import 'package:flutter/material.dart';
import '../base/base_module.dart';

/// Combined Defence Services (CDS) Exam Module Plugin.
class CdsModule extends BaseQuizModule {
  CdsModule()
      : super(
          id: 'cds',
          name: 'CDS Defence Exam',
          description:
              'Combined Defence Services examination preparation for IMA, INA, AFA, and OTA officers training.',
          version: '1.0.0',
          category: 'Defence',
          icon: Icons.military_tech,
          themeColor: Colors.deepPurple,
        );
}
