import 'package:flutter/material.dart';
import '../base/base_module.dart';

/// Current Affairs & News Digest Module Plugin.
class CurrentAffairsModule extends BaseQuizModule {
  CurrentAffairsModule()
      : super(
          id: 'current_affairs',
          name: 'Current Affairs Digest',
          description:
              'Daily, weekly, and monthly national & international current affairs digest with topic-wise quiz generation.',
          version: '1.0.0',
          category: 'General Knowledge',
          icon: Icons.newspaper,
          themeColor: Colors.amber.shade800,
        );
}
