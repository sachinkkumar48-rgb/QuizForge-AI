import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_storage/titan_storage.dart';

import 'src/app.dart';
import 'src/providers/reader_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Reuse the shared TITAN storage layer; never introduce a second
  // persistence engine (TITAN storage policy).
  final StorageService storage =
      await TitanStorageBootstrap.initializeStorage();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const TitanReaderApp(),
    ),
  );
}
