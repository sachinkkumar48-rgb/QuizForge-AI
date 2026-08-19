import '../data/grammar_cache_repository.dart';
import '../data/grammar_correction_repository.dart';
import '../data/grammar_engine.dart';
import '../data/remote_grammar_source.dart';
import '../domain/entities/grammar_issue.dart';
import '../domain/grammar_errors.dart';
import '../domain/grammar_text_correction.dart';

/// Outcome of the optional remote leg of a check.
class GrammarRemoteOutcome {
  /// Issues merged from the remote engine, empty when it did not run.
  final List<GrammarIssue> issues;

  /// Human-readable failure reason when the remote engine ran but failed.
  /// Null when the remote engine succeeded or was not consulted.
  final String? failureReason;

  const GrammarRemoteOutcome({this.issues = const [], this.failureReason});
}

/// Application service orchestrating grammar checks.
///
/// Pipeline: cache → local deterministic engine → optional remote engine
/// (only when the user opted in) → cache the result. Applying corrections
/// is Reader-managed: the original PDF is never modified (§16–17).
class GrammarService {
  GrammarService({
    required GrammarEngine engine,
    required GrammarCacheRepository cache,
    required GrammarCorrectionRepository corrections,
    RemoteGrammarSource? remoteSource,
    required bool remoteEnabled,
    String Function(String prefix)? idGenerator,
  })  : _engine = engine,
        _cache = cache,
        _corrections = corrections,
        _remoteSource = remoteSource,
        _remoteEnabled = remoteEnabled,
        _idGenerator = idGenerator ?? _defaultIdGenerator;

  /// Language every Phase 4 check runs for; future phases may expose it.
  static const String language = 'en';

  final GrammarEngine _engine;
  final GrammarCacheRepository _cache;
  final GrammarCorrectionRepository _corrections;
  final RemoteGrammarSource? _remoteSource;
  final bool _remoteEnabled;
  final String Function(String prefix) _idGenerator;

  int _idSequence = 0;

  /// Whether the optional remote engine is consulted at all.
  bool get remoteEnabled => _remoteEnabled && _remoteSource != null;

  /// Checks [text], preferring the cache, and caches fresh results.
  ///
  /// Never throws for remote failures: local issues are still returned and
  /// the failure is reported through [GrammarRemoteOutcome] for honest UI
  /// states. Local engine failures surface as [GrammarCheckError].
  Future<({GrammarCheckResult result, GrammarRemoteOutcome remote})> checkText(
      String text,
      {DateTime? at}) async {
    final checkedAt = at ?? DateTime.now();
    final key = GrammarCacheRepository.keyFor(
      engineId: _engine.engineId,
      engineVersion: _engine.engineVersion,
      language: language,
      text: text,
    );
    final cached = await _cache.load(key);
    if (cached != null) {
      return (
        result: cached,
        remote: const GrammarRemoteOutcome(),
      );
    }

    final localIssues = await _engine.check(text, language: language);
    var remoteOutcome = const GrammarRemoteOutcome();
    var remoteSourceId = _remoteSource?.sourceId;
    var issues = localIssues;
    if (remoteEnabled) {
      try {
        final remoteIssues =
            await _remoteSource!.check(text, language: language);
        remoteOutcome = GrammarRemoteOutcome(issues: remoteIssues);
        issues = _merge(localIssues, remoteIssues);
      } on GrammarCheckError catch (error) {
        remoteOutcome = GrammarRemoteOutcome(failureReason: error.message);
        remoteSourceId = null;
      }
    } else {
      remoteSourceId = null;
    }

    final result = GrammarCheckResult(
      text: text,
      language: language,
      issues: issues,
      engineId: _engine.engineId,
      engineVersion: _engine.engineVersion,
      remoteSourceId: remoteSourceId,
      checkedAt: checkedAt,
    );
    await _cache.save(key, result);
    return (result: result, remote: remoteOutcome);
  }

  /// Applies accepted [replacements] (offset span → replacement) to [text]
  /// and stores the Reader-managed correction. The PDF is never touched.
  Future<GrammarCorrection> applyCorrections({
    required String text,
    required Map<(int start, int end), String> replacements,
    required List<String> appliedRuleIds,
    required DateTime at,
    String? documentId,
    int? pageNumber,
  }) async {
    final corrected = GrammarTextCorrection.apply(text, replacements);
    final correction = GrammarCorrection(
      id: nextId(),
      documentId: documentId,
      pageNumber: pageNumber,
      originalText: text,
      correctedText: corrected,
      appliedRuleIds: List.unmodifiable(appliedRuleIds),
      createdAt: at,
    );
    final stored = await _corrections.loadAll();
    await _corrections.saveAll([correction, ...stored]);
    return correction;
  }

  /// All stored corrections, newest first.
  Future<List<GrammarCorrection>> getCorrections() async {
    // Sort a defensive copy: repositories may return shared or
    // unmodifiable lists (e.g. the empty const list).
    final stored = List.of(await _corrections.loadAll());
    stored.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(stored);
  }

  /// Removes one stored correction by id.
  Future<void> removeCorrection(String correctionId) =>
      _corrections.delete(correctionId);

  /// Generates a new unique correction id.
  String nextId() => _idGenerator('grammar_${_idSequence++}');

  /// Local issues first; a remote issue is dropped when it covers exactly
  /// the same span as a local one (the deterministic engine wins).
  static List<GrammarIssue> _merge(
      List<GrammarIssue> local, List<GrammarIssue> remote) {
    final merged = <GrammarIssue>[...local];
    for (final issue in remote) {
      final duplicate = local.any((existing) =>
          existing.startOffset == issue.startOffset &&
          existing.endOffset == issue.endOffset);
      if (!duplicate) merged.add(issue);
    }
    merged.sort((a, b) {
      final byStart = a.startOffset.compareTo(b.startOffset);
      if (byStart != 0) return byStart;
      return a.endOffset.compareTo(b.endOffset);
    });
    return List.unmodifiable(merged);
  }

  static String _defaultIdGenerator(String seed) =>
      'grammar_${DateTime.now().microsecondsSinceEpoch}_$seed';
}
