import 'package:flutter/material.dart';

/// Contract for module-specific UI rendering and components.
abstract class ModuleUI {
  /// Main module dashboard / overview view widget.
  Widget buildDashboard(BuildContext context);

  /// Custom practice / quiz view wrapper widget.
  Widget buildPracticeView(BuildContext context,
      {Map<String, dynamic>? params});

  /// Custom analytics view widget for this module.
  Widget buildAnalyticsView(BuildContext context);

  /// Importer interface widget for this module.
  Widget buildImporterView(BuildContext context);

  /// List of quick action widgets (cards/buttons) to display in the main hub.
  List<Widget> getQuickActions(BuildContext context);
}
