/// Date formatting and parsing utilities for GARUDA Evidence Engine.
class EvidenceDateUtils {
  /// Parse ISO8601 String or return default DateTime if parsing fails.
  static DateTime parseIso(String isoString, {DateTime? fallback}) {
    final parsed = DateTime.tryParse(isoString);
    return parsed ?? (fallback ?? DateTime.now());
  }

  /// Format DateTime to ISO8601 string.
  static String toIso(DateTime dt) {
    return dt.toIso8601String();
  }
}
