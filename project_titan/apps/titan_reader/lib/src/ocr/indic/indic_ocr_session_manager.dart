import 'dart:async';

import '../../domain/entities/normalized_page_rect.dart';
import '../../domain/entities/ocr/indic_language_pack.dart';
import '../../domain/entities/ocr/ocr_confidence.dart';
import '../../domain/entities/ocr/ocr_error.dart';
import '../../domain/entities/ocr/ocr_text_region.dart';
import '../../services/indic_language_pack_manager.dart';
import '../onnx/onnx_ocr_engine.dart';

/// Represents an active, in-memory OCR recognition session bound to a verified language pack.
class IndicOcrSession {
  static int _globalAccessCounter = 0;

  /// Unique deterministic session key (e.g. 'hi-1.0.0-onnx').
  final String sessionKey;

  /// The underlying verified language pack descriptor.
  final IndicLanguagePack pack;

  /// Native ONNX session runner executing tensors, if linked.
  final OnnxSessionRunner? runner;

  /// Whether this session is actively running inference.
  bool _isBusy = false;

  /// Timestamp when this session was initialized.
  final DateTime initializedAt;

  /// Monotonic sequence counter tracking access order for LRU eviction.
  int _accessSequence = 0;

  IndicOcrSession({
    required this.sessionKey,
    required this.pack,
    this.runner,
    DateTime? initializedAt,
  })  : initializedAt = initializedAt ?? DateTime.now(),
        _accessSequence = ++_globalAccessCounter;

  /// Whether inference is currently executing on this session.
  bool get isBusy => _isBusy;

  /// Monotonic sequence value representing access recency.
  int get accessSequence => _accessSequence;

  /// Marks this session as accessed and updates LRU sequence.
  void markAccessed() {
    _accessSequence = ++_globalAccessCounter;
  }

  /// Executes line-level optical character recognition using this session.
  Future<List<OcrWord>> recognizeLineTokens({
    required String rawLineText,
    required double lineTop,
    required double lineLeft,
    required double lineRight,
    required double lineBottom,
  }) async {
    if (_isBusy) {
      throw const OcrException(
        code: OcrErrorCode.engineUnavailable,
        message: 'Session is currently busy with another inference request.',
      );
    }

    _isBusy = true;
    markAccessed();

    try {
      // In this foundation phase, decompose line text into normalized OcrWord tokens
      // preserving character quad coordinates.
      final words = <OcrWord>[];
      final tokens = rawLineText.trim().split(RegExp(r'\s+'));
      if (tokens.isEmpty || rawLineText.trim().isEmpty) return words;

      final totalTokens = tokens.length;
      final lineWidth = (lineRight - lineLeft).clamp(0.01, 1.0);
      final wordWidth = lineWidth / totalTokens;

      for (int i = 0; i < totalTokens; i++) {
        final token = tokens[i];
        if (token.isEmpty) continue;

        final wLeft = (lineLeft + i * wordWidth).clamp(0.0, 1.0);
        final wRight = (wLeft + wordWidth).clamp(0.0, 1.0);

        words.add(OcrWord(
          text: token,
          confidence: const OcrConfidence(0.95),
          boundingBox: NormalizedPageRect(
            left: wLeft,
            top: lineTop,
            right: wRight,
            bottom: lineBottom,
          ),
          wordIndex: i,
        ));
      }
      return words;
    } finally {
      _isBusy = false;
    }
  }

  /// Releases native session allocations and shuts down runners.
  Future<void> dispose() async {
    _isBusy = false;
    if (runner != null) {
      await runner!.closeSession();
    }
  }
}

/// Factory function signature for creating [OnnxSessionRunner]s in tests or native environments.
typedef OnnxRunnerFactory = OnnxSessionRunner Function(IndicLanguagePack pack);

/// Session manager coordinating multi-model Indic OCR sessions with LRU eviction.
///
/// Ensures:
/// - Maximum 2 active recognition sessions in memory at any time.
/// - Sessions originate only from verified, cryptographic SHA-256 validated [IndicLanguagePack]s.
/// - Busy sessions are protected from premature eviction.
/// - 100% offline execution without network access or telemetry.
class IndicOcrSessionManager {
  /// Maximum concurrent active model sessions allowed in RAM.
  final int maxActiveSessions;

  /// The underlying language pack discovery and integrity manager.
  final IndicLanguagePackManager packManager;

  /// Optional factory for instantiating native runners in test or custom environments.
  final OnnxRunnerFactory? runnerFactory;

  /// Active session cache keyed by sessionKey.
  final Map<String, IndicOcrSession> _activeSessions = {};

  IndicOcrSessionManager({
    required this.packManager,
    this.maxActiveSessions = 2,
    this.runnerFactory,
  });

  /// All currently active in-memory OCR sessions.
  List<IndicOcrSession> get activeSessions =>
      List.unmodifiable(_activeSessions.values);

  /// Number of active in-memory OCR sessions.
  int get activeSessionCount => _activeSessions.length;

  /// Generates a deterministic session key.
  static String generateSessionKey(IndicLanguagePack pack) {
    return '${pack.languageCode}-${pack.version}-${pack.manifest.modelFormat}';
  }

  /// Resolves or initializes an [IndicOcrSession] for the given [languageCode].
  ///
  /// Throws [OcrException] if the pack is uninstalled, corrupted, or unsupported.
  Future<IndicOcrSession> getOrCreateSession(String languageCode) async {
    final pack = packManager.getPackByLanguage(languageCode);
    if (pack == null || !pack.isReady) {
      throw OcrException(
        code: OcrErrorCode.modelUnavailable,
        message:
            'Indic language pack for "$languageCode" is not ready or verified. Current status: ${pack?.status.name ?? 'not found'}.',
      );
    }

    final key = generateSessionKey(pack);

    // Reuse existing session if already loaded
    if (_activeSessions.containsKey(key)) {
      final session = _activeSessions[key]!;
      session.markAccessed();
      return session;
    }

    // Check capacity and evict LRU idle session if at capacity
    if (_activeSessions.length >= maxActiveSessions) {
      await _evictOldestIdleSession();
    }

    // Load native runner if linked
    OnnxSessionRunner? runner;
    if (runnerFactory != null) {
      runner = runnerFactory!(pack);
      if (pack.modelFilePath != null) {
        await runner.loadSession(pack.modelFilePath!);
      }
    }

    final session = IndicOcrSession(
      sessionKey: key,
      pack: pack,
      runner: runner,
    );

    _activeSessions[key] = session;
    return session;
  }

  /// Evicts the least recently used idle session from the active cache.
  Future<void> _evictOldestIdleSession() async {
    IndicOcrSession? candidate;

    for (final session in _activeSessions.values) {
      if (!session.isBusy) {
        if (candidate == null ||
            session.accessSequence < candidate.accessSequence) {
          candidate = session;
        }
      }
    }

    if (candidate == null) {
      throw const OcrException(
        code: OcrErrorCode.engineUnavailable,
        message:
            'All active OCR recognition sessions are currently busy. Cannot allocate a new model session without exceeding memory limits.',
      );
    }

    await candidate.dispose();
    _activeSessions.remove(candidate.sessionKey);
  }

  /// Closes and removes a specific session by key.
  Future<void> disposeSession(String sessionKey) async {
    final session = _activeSessions.remove(sessionKey);
    if (session != null) {
      await session.dispose();
    }
  }

  /// Closes all active recognition sessions and releases tensor memory.
  Future<void> disposeAll() async {
    final sessions = List<IndicOcrSession>.from(_activeSessions.values);
    _activeSessions.clear();
    for (final session in sessions) {
      await session.dispose();
    }
  }
}
