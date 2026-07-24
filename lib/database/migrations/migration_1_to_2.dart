import 'dart:convert';
import 'migration.dart';

class Migration1To2 extends SchemaMigration {
  Migration1To2()
      : super(
          fromVersion: 1,
          toVersion: 2,
          description:
              'Add default author and version metadata to explanations; normalize user notes timestamps.',
        );

  @override
  Future<void> up(Map<String, Map<String, String>> boxesData) async {
    // 1. Migrate Explanations
    final expBox = boxesData['engine_explanations'];
    if (expBox != null) {
      expBox.forEach((key, jsonStr) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          if (!map.containsKey('author') || map['author'] == null) {
            map['author'] = 'Official UPSC';
          }
          if (!map.containsKey('version') || map['version'] == null) {
            map['version'] = '1.0.0';
          }
          expBox[key] = jsonEncode(map);
        } catch (_) {}
      });
    }

    // 2. Migrate User Notes
    final notesBox = boxesData['engine_user_notes'];
    if (notesBox != null) {
      notesBox.forEach((key, jsonStr) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          if (!map.containsKey('updatedAt') || map['updatedAt'] == null) {
            map['updatedAt'] = DateTime.now().toIso8601String();
          }
          notesBox[key] = jsonEncode(map);
        } catch (_) {}
      });
    }
  }

  @override
  Future<void> down(Map<String, Map<String, String>> boxesData) async {
    // Rollback changes if needed
  }
}
