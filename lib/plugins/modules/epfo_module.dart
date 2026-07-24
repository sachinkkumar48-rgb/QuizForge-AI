import 'package:flutter/material.dart';
import '../base/base_module.dart';

/// Employees' Provident Fund Organisation (EPFO) APFC / EO / AO Module Plugin.
class EpfoModule extends BaseQuizModule {
  EpfoModule()
      : super(
          id: 'epfo',
          name: 'EPFO APFC / EO',
          description:
              'EPFO Enforcement Officer / Accounts Officer and APFC exam prep covering Industrial Relations, Labor Laws, General Accounting, and Auditing.',
          version: '1.0.0',
          category: 'Specialized Exams',
          icon: Icons.gavel,
          themeColor: Colors.purple,
        );
}
