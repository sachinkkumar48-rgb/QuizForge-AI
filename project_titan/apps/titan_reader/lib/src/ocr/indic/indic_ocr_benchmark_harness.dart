import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;

import '../../domain/entities/ocr/indic_language_pack.dart';
import '../../services/indic_language_pack_manager.dart';
import 'bilingual_ocr_router.dart';
import 'indic_ocr_model_loader.dart';
import 'indic_ocr_session_manager.dart';
import 'line_script_classifier.dart';

/// Statistical summary for a specific benchmark measurement.
class IndicOcrBenchmarkMetric {
  final String name;
  final int iterations;
  final List<double> durationsMs;
  final double minMs;
  final double maxMs;
  final double meanMs;
  final double medianMs;
  final double p95Ms;

  const IndicOcrBenchmarkMetric({
    required this.name,
    required this.iterations,
    required this.durationsMs,
    required this.minMs,
    required this.maxMs,
    required this.meanMs,
    required this.medianMs,
    required this.p95Ms,
  });

  factory IndicOcrBenchmarkMetric.fromDurations({
    required String name,
    required List<double> durationsMs,
  }) {
    if (durationsMs.isEmpty) {
      return IndicOcrBenchmarkMetric(
        name: name,
        iterations: 0,
        durationsMs: const [],
        minMs: 0.0,
        maxMs: 0.0,
        meanMs: 0.0,
        medianMs: 0.0,
        p95Ms: 0.0,
      );
    }

    final sorted = List<double>.from(durationsMs)..sort();
    final count = sorted.length;
    final min = sorted.first;
    final max = sorted.last;
    final sum = sorted.reduce((a, b) => a + b);
    final mean = sum / count;

    // Median calculation
    double median;
    if (count % 2 == 1) {
      median = sorted[count ~/ 2];
    } else {
      median = (sorted[(count ~/ 2) - 1] + sorted[count ~/ 2]) / 2.0;
    }

    // P95 calculation
    final p95Index = math.min(count - 1, (count * 0.95).floor());
    final p95 = sorted[p95Index];

    return IndicOcrBenchmarkMetric(
      name: name,
      iterations: count,
      durationsMs: List.unmodifiable(durationsMs),
      minMs: min,
      maxMs: max,
      meanMs: mean,
      medianMs: median,
      p95Ms: p95,
    );
  }

  Map<String, Object?> toJson() => {
        'name': name,
        'iterations': iterations,
        'minMs': double.parse(minMs.toStringAsFixed(3)),
        'maxMs': double.parse(maxMs.toStringAsFixed(3)),
        'meanMs': double.parse(meanMs.toStringAsFixed(3)),
        'medianMs': double.parse(medianMs.toStringAsFixed(3)),
        'p95Ms': double.parse(p95Ms.toStringAsFixed(3)),
      };
}

/// Aggregate results from an OCR benchmark suite execution.
class IndicOcrBenchmarkSuiteResult {
  final String environment;
  final DateTime timestamp;
  final Map<String, IndicOcrBenchmarkMetric> metrics;

  const IndicOcrBenchmarkSuiteResult({
    required this.environment,
    required this.timestamp,
    required this.metrics,
  });

  Map<String, Object?> toJson() => {
        'environment': environment,
        'timestamp': timestamp.toIso8601String(),
        'metrics': metrics.map((k, v) => MapEntry(k, v.toJson())),
      };

  /// Formats all metrics as a readable markdown table.
  String formatSummaryTable() {
    final sb = StringBuffer();
    sb.writeln(
        '| Metric | Iterations | Min (ms) | Mean (ms) | Median (ms) | P95 (ms) | Max (ms) |');
    sb.writeln('| :--- | :---: | :---: | :---: | :---: | :---: | :---: |');
    for (final entry in metrics.entries) {
      final m = entry.value;
      sb.writeln(
        '| **${m.name}** | ${m.iterations} | ${m.minMs.toStringAsFixed(2)} | ${m.meanMs.toStringAsFixed(2)} | ${m.medianMs.toStringAsFixed(2)} | ${m.p95Ms.toStringAsFixed(2)} | ${m.maxMs.toStringAsFixed(2)} |',
      );
    }
    return sb.toString();
  }
}

/// Reusable performance and latency benchmark harness for Indic OCR runtime.
class IndicOcrBenchmarkHarness {
  const IndicOcrBenchmarkHarness();

  /// Executes all 10 core performance benchmarks using synthetic deterministic fixtures.
  Future<IndicOcrBenchmarkSuiteResult> runFullBenchmark({
    int iterations = 10,
    Directory? customTempDir,
  }) async {
    final tempDir = customTempDir ??
        await Directory.systemTemp.createTemp('titan_ocr_benchmark_');
    final metrics = <String, IndicOcrBenchmarkMetric>{};

    try {
      final packManager =
          IndicLanguagePackManager(platform: Platform.operatingSystem);
      const modelLoader = DefaultIndicOcrModelLoader();

      // Create synthetic test pack on disk
      final pack = await _createSyntheticBenchmarkPack(
          tempDir, 'benchmark-hindi', 'hi', 'Hindi', 'Deva', 'Devanagari');
      final pack2 = await _createSyntheticBenchmarkPack(
          tempDir, 'benchmark-bengali', 'bn', 'Bengali', 'Beng', 'Bengali');
      final pack3 = await _createSyntheticBenchmarkPack(
          tempDir, 'benchmark-tamil', 'ta', 'Tamil', 'Taml', 'Tamil');

      packManager.registerPack(pack);
      packManager.registerPack(pack2);
      packManager.registerPack(pack3);

      // 1. Benchmark: Pack Verification Overhead
      final verifyDurations = <double>[];
      for (int i = 0; i < iterations; i++) {
        final sw = Stopwatch()..start();
        final modelFile = File(pack.modelFilePath!);
        final modelBytes = await modelFile.readAsBytes();
        final hash = Sha256Checksum.hashBytes(modelBytes);
        final isValid =
            hash.toLowerCase() == pack.manifest.modelSha256.toLowerCase();
        sw.stop();
        if (isValid) {
          verifyDurations.add(sw.elapsedMicroseconds / 1000.0);
        }
      }
      metrics['packVerificationOverhead'] =
          IndicOcrBenchmarkMetric.fromDurations(
        name: 'Pack Verification (SHA-256)',
        durationsMs: verifyDurations,
      );

      // 2. Benchmark: Model Activation (Cold Load)
      final activationDurations = <double>[];
      for (int i = 0; i < iterations; i++) {
        final sessionManager = IndicOcrSessionManager(
          packManager: packManager,
          modelLoader: modelLoader,
          maxActiveSessions: 2,
        );
        final sw = Stopwatch()..start();
        await sessionManager.getOrCreateSession('hi');
        sw.stop();
        activationDurations.add(sw.elapsedMicroseconds / 1000.0);
        await sessionManager.disposeAll();
      }
      metrics['modelActivation'] = IndicOcrBenchmarkMetric.fromDurations(
        name: 'Model Activation (Cold)',
        durationsMs: activationDurations,
      );

      // 3. Benchmark: Model Session Reuse (Warm Cache Hit)
      final sessionManager = IndicOcrSessionManager(
        packManager: packManager,
        modelLoader: modelLoader,
        maxActiveSessions: 2,
      );
      await sessionManager.getOrCreateSession('hi');
      final reuseDurations = <double>[];
      for (int i = 0; i < iterations; i++) {
        final sw = Stopwatch()..start();
        await sessionManager.getOrCreateSession('hi');
        sw.stop();
        reuseDurations.add(sw.elapsedMicroseconds / 1000.0);
      }
      metrics['modelReuse'] = IndicOcrBenchmarkMetric.fromDurations(
        name: 'Model Session Reuse (Warm)',
        durationsMs: reuseDurations,
      );

      // 4. Benchmark: First OCR Inference (Cold)
      final router = BilingualOcrRouter(
        classifier: const UnicodeLineScriptClassifier(),
        sessionManager: sessionManager,
      );
      final firstInferenceDurations = <double>[];
      for (int i = 0; i < iterations; i++) {
        final freshSessionManager = IndicOcrSessionManager(
          packManager: packManager,
          modelLoader: modelLoader,
          maxActiveSessions: 2,
        );
        final freshRouter = BilingualOcrRouter(
          classifier: const UnicodeLineScriptClassifier(),
          sessionManager: freshSessionManager,
        );
        final sw = Stopwatch()..start();
        await freshRouter.processPageLines(
          documentId: 'bench-doc-1',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: 'संविधान की प्रस्तावना एवं उद्देशिका',
              left: 0.1,
              top: 0.1,
              right: 0.8,
              bottom: 0.15,
            ),
          ],
        );
        sw.stop();
        firstInferenceDurations.add(sw.elapsedMicroseconds / 1000.0);
        await freshSessionManager.disposeAll();
      }
      metrics['firstOcrInference'] = IndicOcrBenchmarkMetric.fromDurations(
        name: 'First OCR Inference (Cold)',
        durationsMs: firstInferenceDurations,
      );

      // 5. Benchmark: Warm OCR Inference
      final warmInferenceDurations = <double>[];
      for (int i = 0; i < iterations; i++) {
        final sw = Stopwatch()..start();
        await router.processPageLines(
          documentId: 'bench-doc-warm',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: 'हम भारत के लोग, भारत को एक सम्पूर्ण प्रभुत्व-सम्पन्न',
              left: 0.1,
              top: 0.1,
              right: 0.9,
              bottom: 0.15,
            ),
          ],
        );
        sw.stop();
        warmInferenceDurations.add(sw.elapsedMicroseconds / 1000.0);
      }
      metrics['warmOcrInference'] = IndicOcrBenchmarkMetric.fromDurations(
        name: 'Warm OCR Inference',
        durationsMs: warmInferenceDurations,
      );

      // 6. Benchmark: Bilingual OCR Inference (Hindi + English Mixed Page)
      final bilingualDurations = <double>[];
      for (int i = 0; i < iterations; i++) {
        final sw = Stopwatch()..start();
        await router.processPageLines(
          documentId: 'bench-doc-bilingual',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: 'Article 1: Name and territory of the Union',
              left: 0.1,
              top: 0.1,
              right: 0.8,
              bottom: 0.14,
            ),
            const LineCandidate(
              text: 'अनुच्छेद १: संघ का नाम और उसका राज्यक्षेत्र',
              left: 0.1,
              top: 0.16,
              right: 0.8,
              bottom: 0.20,
            ),
            const LineCandidate(
              text: 'India, that is Bharat, shall be a Union of States.',
              left: 0.1,
              top: 0.22,
              right: 0.8,
              bottom: 0.26,
            ),
            const LineCandidate(
              text: 'भारत, अर्थात इंडिया, राज्यों का संघ होगा।',
              left: 0.1,
              top: 0.28,
              right: 0.8,
              bottom: 0.32,
            ),
          ],
        );
        sw.stop();
        bilingualDurations.add(sw.elapsedMicroseconds / 1000.0);
      }
      metrics['bilingualOcrInference'] = IndicOcrBenchmarkMetric.fromDurations(
        name: 'Bilingual Page Inference (4 lines)',
        durationsMs: bilingualDurations,
      );

      // 7. Benchmark: Repeated Page Processing (10 Pages Scanned Document Lifecycle)
      final multiPageDurations = <double>[];
      for (int i = 0; i < math.min(iterations, 5); i++) {
        final sw = Stopwatch()..start();
        for (int pNum = 1; pNum <= 10; pNum++) {
          await router.processPageLines(
            documentId: 'bench-doc-10p',
            pageNumber: pNum,
            lineCandidates: [
              LineCandidate(
                text: 'पृष्ठ संख्या $pNum: भारतीय संविधान के मूल तत्व',
                left: 0.1,
                top: 0.1,
                right: 0.8,
                bottom: 0.15,
              ),
              const LineCandidate(
                text: 'Fundamental Principles of the Constitution',
                left: 0.1,
                top: 0.2,
                right: 0.8,
                bottom: 0.25,
              ),
            ],
          );
        }
        sw.stop();
        multiPageDurations.add(sw.elapsedMicroseconds / 1000.0);
      }
      metrics['repeatedPageProcessing'] = IndicOcrBenchmarkMetric.fromDurations(
        name: '10-Page Document Processing',
        durationsMs: multiPageDurations,
      );

      // 8. Benchmark: Cancellation Latency
      final cancelDurations = <double>[];
      for (int i = 0; i < iterations; i++) {
        final sw = Stopwatch()..start();
        final result = await router.processPageLines(
          documentId: 'bench-doc-cancel',
          pageNumber: 1,
          isCancelled: true,
          lineCandidates: [
            const LineCandidate(
              text: 'यह रद्द किया जाना चाहिए',
              left: 0.1,
              top: 0.1,
              right: 0.8,
              bottom: 0.15,
            ),
          ],
        );
        sw.stop();
        if (result.isCancelled) {
          cancelDurations.add(sw.elapsedMicroseconds / 1000.0);
        }
      }
      metrics['cancellationLatency'] = IndicOcrBenchmarkMetric.fromDurations(
        name: 'Cancellation Latency',
        durationsMs: cancelDurations,
      );

      // 9. Benchmark: Session Disposal
      final disposalDurations = <double>[];
      for (int i = 0; i < iterations; i++) {
        final tempManager = IndicOcrSessionManager(
          packManager: packManager,
          modelLoader: modelLoader,
          maxActiveSessions: 2,
        );
        await tempManager.getOrCreateSession('hi');
        final sw = Stopwatch()..start();
        await tempManager.disposeAll();
        sw.stop();
        disposalDurations.add(sw.elapsedMicroseconds / 1000.0);
      }
      metrics['sessionDisposal'] = IndicOcrBenchmarkMetric.fromDurations(
        name: 'Session Disposal & Cleanup',
        durationsMs: disposalDurations,
      );

      // 10. Benchmark: LRU Eviction Under Pressure
      final lruDurations = <double>[];
      for (int i = 0; i < iterations; i++) {
        final tempManager = IndicOcrSessionManager(
          packManager: packManager,
          modelLoader: modelLoader,
          maxActiveSessions: 2,
        );
        await tempManager.getOrCreateSession('hi');
        await tempManager.getOrCreateSession('bn');
        final sw = Stopwatch()..start();
        // Requesting 3rd pack ('ta') triggers LRU eviction of 'hi'
        await tempManager.getOrCreateSession('ta');
        sw.stop();
        lruDurations.add(sw.elapsedMicroseconds / 1000.0);
        await tempManager.disposeAll();
      }
      metrics['lruEviction'] = IndicOcrBenchmarkMetric.fromDurations(
        name: 'LRU Eviction & Allocation',
        durationsMs: lruDurations,
      );

      await sessionManager.disposeAll();

      return IndicOcrBenchmarkSuiteResult(
        environment:
            '${Platform.operatingSystem} ${Platform.operatingSystemVersion} (${Platform.localeName})',
        timestamp: DateTime.now(),
        metrics: metrics,
      );
    } finally {
      if (customTempDir == null && await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  /// Helper to create a valid synthetic model pack on disk for benchmarking.
  static Future<IndicLanguagePack> _createSyntheticBenchmarkPack(
    Directory rootDir,
    String packId,
    String languageCode,
    String languageName,
    String scriptCode,
    String scriptName,
  ) async {
    final packDir = Directory(p.join(rootDir.path, packId));
    await packDir.create(recursive: true);

    final modelBytes = utf8.encode('BENCHMARK_SYNTHETIC_WEIGHTS_$packId');
    final dictBytes = utf8.encode('a\nb\nc\nक\nख\nग\nघ\nङ\n');

    final modelSha = Sha256Checksum.hashBytes(modelBytes);
    final dictSha = Sha256Checksum.hashBytes(dictBytes);

    final modelFile = File(p.join(packDir.path, 'model.onnx'));
    await modelFile.writeAsBytes(modelBytes);

    final dictFile = File(p.join(packDir.path, 'dict.txt'));
    await dictFile.writeAsBytes(dictBytes);

    final manifest = IndicPackManifest(
      manifestVersion: '1.0.0',
      packId: packId,
      displayName: '$languageName ($scriptName) Benchmark Pack',
      languageCode: languageCode,
      languageName: languageName,
      scriptCode: scriptCode,
      scriptName: scriptName,
      engineVersion: '1.0.0',
      modelVersion: '1.0.0',
      modelFormat: 'onnx',
      quantization: 'int8',
      modelFileName: 'model.onnx',
      modelSizeBytes: modelBytes.length,
      modelSha256: modelSha,
      dictFileName: 'dict.txt',
      dictSizeBytes: dictBytes.length,
      dictSha256: dictSha,
      licenseType: 'Apache-2.0',
      minimumAppVersion: '0.1.0',
      supportedPlatforms: const ['windows', 'macos', 'linux', 'android', 'ios'],
    );

    final manifestFile = File(p.join(packDir.path, 'manifest.json'));
    await manifestFile.writeAsString(jsonEncode(manifest.toJson()));

    return IndicLanguagePack(
      manifest: manifest,
      status: IndicLanguagePackStatus.ready,
      directoryPath: packDir.path,
    );
  }
}
