import 'package:flutter_test/flutter_test.dart';
import 'package:titan_identity/titan_identity.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('SecureTokenStorage Tests', () {
    final now = DateTime.now();
    final user = User(
      id: 'usr_storage',
      email: 'storage@example.com',
      displayName: 'Storage Learner',
      providerType: AuthProviderType.guest,
      createdAt: now,
    );
    final session = UserSession(
      sessionId: 'sess_storage',
      user: user,
      accessToken: 'tok_storage',
      expiresAt: now.add(const Duration(hours: 12)),
    );

    test('In-memory save, retrieve, clear session', () async {
      final storage = SecureTokenStorage();

      expect(await storage.getSession(), isNull);

      await storage.saveSession(session);
      final retrieved = await storage.getSession();

      expect(retrieved, equals(session));

      await storage.clearSession();
      expect(await storage.getSession(), isNull);
    });

    test('Persistent storage using InMemoryStorageService backend', () async {
      final storageService = InMemoryStorageService();
      await storageService.initialize();

      final storage = SecureTokenStorage(storageService: storageService);

      await storage.saveSession(session);

      // Create new SecureTokenStorage instance connected to same storage backend
      final storage2 = SecureTokenStorage(storageService: storageService);
      final retrieved = await storage2.getSession();

      expect(retrieved?.sessionId, session.sessionId);
      expect(retrieved?.user.id, session.user.id);

      await storage2.clearSession();
      expect(await storage.getSession(), isNull);
    });
  });
}
