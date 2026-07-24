import 'package:flutter/material.dart';
import 'module_analytics.dart';
import 'module_importer.dart';
import 'module_repository.dart';
import 'module_ui.dart';

/// Root plugin interface for exam and study modules in QuizForge.
///
/// Any future module (e.g. UPSC, BPSC, SSC, EPFO, NDA, CDS, CAPF,
/// Current Affairs, Vocabulary, Essay) implements this interface
/// and registers with [PluginRegistry] without modifying core code.
abstract class QuizModule {
  /// Unique identifier of the module (e.g. 'upsc', 'bpsc', 'ssc', 'essay').
  String get id;

  /// Display name of the module (e.g. 'UPSC Civil Services').
  String get name;

  /// Detailed description of what this module covers.
  String get description;

  /// Module semantic version (e.g. '1.0.0').
  String get version;

  /// Module classification category (e.g. 'Civil Services', 'Defence', 'General Knowledge').
  String get category;

  /// Visual icon for the module.
  IconData get icon;

  /// Accent color theme for the module UI components.
  Color get themeColor;

  /// Data repository for module questions, exams, papers, and metadata.
  ModuleRepository get repository;

  /// UI provider for dashboards, practice screens, analytics, and importers.
  ModuleUI get ui;

  /// Dataset importer and schema validator for module-specific formats.
  ModuleImporter get importer;

  /// Domain-specific analytics engine for metrics and study recommendations.
  ModuleAnalytics get analytics;

  /// Lifecycle callback invoked when the module is registered/initialized.
  Future<void> initialize();

  /// Lifecycle callback invoked when the module is enabled or activated.
  Future<void> onEnable();

  /// Lifecycle callback invoked when the module is disabled or unloaded.
  Future<void> onDisable();
}
