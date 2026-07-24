import 'package:flutter/foundation.dart';
import '../core/quiz_module.dart';

/// Central singleton registry and manager for QuizForge plugins/modules.
///
/// Enables dynamic registration, discovery, enabling/disabling, and active
/// selection of exam and study modules without modifying core app code.
class PluginRegistry extends ChangeNotifier {
  static final PluginRegistry _instance = PluginRegistry._internal();
  factory PluginRegistry() => _instance;

  PluginRegistry._internal();

  final Map<String, QuizModule> _registeredModules = {};
  final Set<String> _enabledModuleIds = {};
  String? _activeModuleId;

  /// Get list of all registered modules.
  List<QuizModule> get registeredModules =>
      List.unmodifiable(_registeredModules.values);

  /// Get list of enabled modules.
  List<QuizModule> get enabledModules {
    return _registeredModules.values
        .where((m) => _enabledModuleIds.contains(m.id))
        .toList();
  }

  /// Get currently active selected module.
  QuizModule? get activeModule {
    if (_activeModuleId == null) return null;
    return _registeredModules[_activeModuleId];
  }

  /// Active module ID getter.
  String? get activeModuleId => _activeModuleId;

  /// Register a new module with the registry.
  Future<void> registerModule(QuizModule module, {bool enable = true}) async {
    if (_registeredModules.containsKey(module.id)) {
      debugPrint('PluginRegistry: Overwriting module ${module.id}');
    }

    _registeredModules[module.id] = module;
    await module.initialize();

    if (enable) {
      _enabledModuleIds.add(module.id);
      await module.onEnable();
      _activeModuleId ??= module.id;
    }

    notifyListeners();
  }

  /// Unregister a module by its ID.
  Future<void> unregisterModule(String moduleId) async {
    final module = _registeredModules.remove(moduleId);
    if (module != null) {
      if (_enabledModuleIds.contains(moduleId)) {
        await module.onDisable();
        _enabledModuleIds.remove(moduleId);
      }
      if (_activeModuleId == moduleId) {
        _activeModuleId =
            _enabledModuleIds.isNotEmpty ? _enabledModuleIds.first : null;
      }
      notifyListeners();
    }
  }

  /// Enable an installed module.
  Future<void> enableModule(String moduleId) async {
    final module = _registeredModules[moduleId];
    if (module != null && !_enabledModuleIds.contains(moduleId)) {
      _enabledModuleIds.add(moduleId);
      await module.onEnable();
      notifyListeners();
    }
  }

  /// Disable an installed module.
  Future<void> disableModule(String moduleId) async {
    final module = _registeredModules[moduleId];
    if (module != null && _enabledModuleIds.contains(moduleId)) {
      _enabledModuleIds.remove(moduleId);
      await module.onDisable();
      if (_activeModuleId == moduleId) {
        _activeModuleId =
            _enabledModuleIds.isNotEmpty ? _enabledModuleIds.first : null;
      }
      notifyListeners();
    }
  }

  /// Set the active module by ID.
  void setActiveModule(String moduleId) {
    if (_registeredModules.containsKey(moduleId) &&
        _enabledModuleIds.contains(moduleId)) {
      _activeModuleId = moduleId;
      notifyListeners();
    }
  }

  /// Get module by ID.
  QuizModule? getModule(String moduleId) => _registeredModules[moduleId];

  /// Get modules by category.
  List<QuizModule> getModulesByCategory(String category) {
    return _registeredModules.values
        .where((m) => m.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Check if a module is enabled.
  bool isModuleEnabled(String moduleId) => _enabledModuleIds.contains(moduleId);

  /// Clear all registered modules (used for testing or resetting).
  void clearRegistry() {
    _registeredModules.clear();
    _enabledModuleIds.clear();
    _activeModuleId = null;
    notifyListeners();
  }
}
