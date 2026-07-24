import 'package:meta/meta.dart';

/// Immutable configuration model for TITAN domain modules.
@immutable
class TitanModuleConfig {
  final String moduleName;
  final String moduleVersion;
  final bool enabled;
  final Map<String, Object?> metadata;

  TitanModuleConfig({
    required this.moduleName,
    required this.moduleVersion,
    this.enabled = true,
    Map<String, Object?>? metadata,
  }) : metadata = Map<String, Object?>.unmodifiable(metadata ?? const {});

  const TitanModuleConfig.constConfig({
    required this.moduleName,
    required this.moduleVersion,
    required this.enabled,
    required this.metadata,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TitanModuleConfig || runtimeType != other.runtimeType) {
      return false;
    }
    if (moduleName != other.moduleName ||
        moduleVersion != other.moduleVersion ||
        enabled != other.enabled) {
      return false;
    }
    if (metadata.length != other.metadata.length) {
      return false;
    }
    for (final key in metadata.keys) {
      if (!other.metadata.containsKey(key) ||
          other.metadata[key] != metadata[key]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      moduleName.hashCode ^
      moduleVersion.hashCode ^
      enabled.hashCode ^
      metadata.hashCode;

  @override
  String toString() =>
      'TitanModuleConfig(name: $moduleName, v$moduleVersion, enabled: $enabled)';
}
