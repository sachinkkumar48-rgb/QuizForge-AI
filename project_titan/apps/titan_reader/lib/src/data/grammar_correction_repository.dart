import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/grammar_issue.dart';

/// Repository contract for Reader-managed grammar corrections.
///
/// Applying a suggestion never edits the PDF (§16–17); accepted
/// corrections are stored here so the user can review and copy them.
abstract class GrammarCorrectionRepository {
  /// All stored corrections, newest first.
  Future<List<GrammarCorrection>> loadAll();

  /// Replaces the stored corrections with [corrections].
  Future<void> saveAll(List<GrammarCorrection> corrections);

  /// Removes the correction identified by [correctionId]. No-op when
  /// absent.
  Future<void> delete(String correctionId);
}

/// [GrammarCorrectionRepository] backed by the shared TITAN
/// [StorageService] inside the Reader-specific
/// `titan.reader.grammar.corrections` namespace.
class StorageGrammarCorrectionRepository
    implements GrammarCorrectionRepository {
  /// Storage namespace used for all Reader-managed corrections.
  static const String namespace = 'titan.reader.grammar.corrections';

  /// Storage key holding the whole correction list as one JSON payload.
  static const StorageKey allKey = StorageKey('all', namespace: namespace);

  final StorageService _storage;

  StorageGrammarCorrectionRepository(this._storage);

  @override
  Future<List<GrammarCorrection>> loadAll() async {
    final raw = await _storage.read<String>(allKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Grammar corrections payload is malformed.');
    }
    return decoded
        .whereType<Map<String, Object?>>()
        .map(GrammarCorrection.fromJson)
        .toList();
  }

  @override
  Future<void> saveAll(List<GrammarCorrection> corrections) async {
    final payload =
        corrections.map((correction) => correction.toJson()).toList();
    await _storage.write<String>(allKey, jsonEncode(payload));
  }

  @override
  Future<void> delete(String correctionId) async {
    final remaining = (await loadAll())
        .where((correction) => correction.id != correctionId)
        .toList();
    await saveAll(remaining);
  }
}
