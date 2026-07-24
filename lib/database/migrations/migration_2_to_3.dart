import 'dart:convert';
import 'migration.dart';

class Migration2To3 extends SchemaMigration {
  Migration2To3()
      : super(
          fromVersion: 2,
          toVersion: 3,
          description:
              'Upgrade bookmark categories and recalculate question statistics accuracy percentages.',
        );

  @override
  Future<void> up(Map<String, Map<String, String>> boxesData) async {
    // 1. Migrate Bookmarks
    final bookmarkBox = boxesData['engine_bookmarks'];
    if (bookmarkBox != null) {
      bookmarkBox.forEach((key, jsonStr) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          if (!map.containsKey('category') ||
              map['category'] == null ||
              (map['category'] as String).isEmpty) {
            map['category'] = 'General';
          }
          bookmarkBox[key] = jsonEncode(map);
        } catch (_) {}
      });
    }

    // 2. Migrate Question Statistics
    final statsBox = boxesData['engine_statistics'];
    if (statsBox != null) {
      statsBox.forEach((key, jsonStr) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          final total = map['totalAttempts'] as int? ?? 0;
          final correct = map['correctAttempts'] as int? ?? 0;
          map['accuracyPercentage'] =
              total == 0 ? 0.0 : (correct / total) * 100.0;
          statsBox[key] = jsonEncode(map);
        } catch (_) {}
      });
    }
  }

  @override
  Future<void> down(Map<String, Map<String, String>> boxesData) async {
    // Rollback changes if needed
  }
}
