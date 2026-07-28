import 'dart:async';

/// Represents system health status.
enum HealthStatus {
  healthy,
  degraded,
  unhealthy,
}

/// Subsystem health check result.
class SubsystemHealth {
  final String name;
  final HealthStatus status;
  final String message;
  final DateTime checkedAt;

  SubsystemHealth({
    required this.name,
    required this.status,
    this.message = 'Operational',
    DateTime? checkedAt,
  }) : checkedAt = checkedAt ?? DateTime.now();
}

typedef HealthChecker = FutureOr<SubsystemHealth> Function();

/// Health Monitor service checking operational status across storage, network, AI providers, and core services.
class HealthMonitor {
  final Map<String, HealthChecker> _checkers = {};

  HealthMonitor();

  /// Registers a subsystem health checker delegate.
  void registerChecker(String name, HealthChecker checker) {
    _checkers[name] = checker;
  }

  /// Runs all registered health checks.
  Future<Map<String, SubsystemHealth>> checkHealth() async {
    final Map<String, SubsystemHealth> results = {};
    for (final entry in _checkers.entries) {
      try {
        results[entry.key] = await entry.value();
      } catch (e) {
        results[entry.key] = SubsystemHealth(
          name: entry.key,
          status: HealthStatus.unhealthy,
          message: 'Health check failed: $e',
        );
      }
    }
    return results;
  }

  /// Returns true if all registered subsystems are healthy or degraded.
  Future<bool> isSystemOperational() async {
    final results = await checkHealth();
    return results.values.every((h) => h.status != HealthStatus.unhealthy);
  }
}
