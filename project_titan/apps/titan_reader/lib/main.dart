import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:titan_storage/titan_storage.dart';

import 'src/app.dart';
import 'src/providers/reader_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable debug printing in release builds
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Reuse the shared TITAN storage layer; never introduce a second
  // persistence engine (TITAN storage policy).
  StorageService storage;
  try {
    String? storagePath;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      storagePath = docDir.path;
    } catch (e) {
      debugPrint('Notice: Document directory resolution fallback: $e');
    }

    storage = await TitanStorageBootstrap.initializeStorage(
      storagePath: storagePath,
    );
  } catch (e, st) {
    debugPrint('TITAN Reader storage initialization fallback: $e\n$st');
    storage = InMemoryStorageService();
    if (!storage.isInitialized) {
      await storage.initialize();
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const TitanReaderApp(),
    ),
  );
}
