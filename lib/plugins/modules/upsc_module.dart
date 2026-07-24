import 'package:flutter/material.dart';
import '../base/base_module.dart';

/// UPSC Civil Services Examination (CSE) Module Plugin.
class UpscModule extends BaseQuizModule {
  UpscModule()
      : super(
          id: 'upsc',
          name: 'UPSC Civil Services',
          description:
              'Union Public Service Commission Civil Services Prelims & Mains examination preparation with PYQs and AI mock tests.',
          version: '1.0.0',
          category: 'Civil Services',
          icon: Icons.account_balance,
          themeColor: Colors.deepOrange,
        );
}
