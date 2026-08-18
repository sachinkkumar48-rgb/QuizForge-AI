import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/app.dart';
import 'package:titan_reader/src/navigation/reader_router.dart';
import 'package:titan_reader/src/providers/reader_providers.dart';
import 'package:titan_reader/src/screens/library_screen.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  testWidgets('app boots on the library route', (tester) async {
    final storage = InMemoryStorageService();
    await storage.initialize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: const TitanReaderApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The router lands on '/' which hosts the library screen.
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(find.text('TITAN Reader'), findsOneWidget);
  });

  testWidgets('unknown routes render the navigation error screen',
      (tester) async {
    final storage = InMemoryStorageService();
    await storage.initialize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: const TitanReaderApp(),
      ),
    );
    await tester.pumpAndSettle();

    readerRouter.go('/no/such/route');
    await tester.pumpAndSettle();

    expect(find.text('Navigation Error'), findsOneWidget);

    // Restore the initial location so other tests see a clean router.
    readerRouter.go('/');
    await tester.pumpAndSettle();
  });
}
