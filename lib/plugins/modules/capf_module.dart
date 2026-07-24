import 'package:flutter/material.dart';
import '../base/base_module.dart';

/// Central Armed Police Forces (CAPF) Assistant Commandant Module Plugin.
class CapfModule extends BaseQuizModule {
  CapfModule()
      : super(
          id: 'capf',
          name: 'CAPF Assistant Commandant',
          description:
              'Central Armed Police Forces (BSF, CRPF, CISF, ITBP, SSB) AC Paper 1 (General Ability & Intelligence) and Paper 2 (General Studies & Essay).',
          version: '1.0.0',
          category: 'Defence',
          icon: Icons.security,
          themeColor: Colors.brown,
        );
}
