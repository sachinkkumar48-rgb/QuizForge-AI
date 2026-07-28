/// Permission status enum for platform permissions.
enum PermissionStatus {
  granted,
  denied,
  restricted,
  permanentlyDenied,
}

/// Permission Manager abstraction for device permissions.
class PermissionManager {
  final Map<String, PermissionStatus> _simulatedPermissions = {};

  PermissionManager([Map<String, PermissionStatus>? initialPermissions]) {
    if (initialPermissions != null) {
      _simulatedPermissions.addAll(initialPermissions);
    }
  }

  /// Requests a platform permission.
  Future<PermissionStatus> requestPermission(String permissionName) async {
    final current = _simulatedPermissions[permissionName];
    if (current != null) return current;
    _simulatedPermissions[permissionName] = PermissionStatus.granted;
    return PermissionStatus.granted;
  }

  /// Checks current status of a platform permission.
  Future<PermissionStatus> checkPermission(String permissionName) async {
    return _simulatedPermissions[permissionName] ?? PermissionStatus.granted;
  }

  /// Returns true if the requested permission is granted.
  Future<bool> isGranted(String permissionName) async {
    final status = await checkPermission(permissionName);
    return status == PermissionStatus.granted;
  }

  /// Sets permission status (useful for testing & platform mocking).
  void setPermissionStatus(String permissionName, PermissionStatus status) {
    _simulatedPermissions[permissionName] = status;
  }

  /// Resets permission status map.
  void reset() {
    _simulatedPermissions.clear();
  }
}
