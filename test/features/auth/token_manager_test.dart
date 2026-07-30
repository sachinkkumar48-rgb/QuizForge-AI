import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/features/auth/services/token_manager.dart';
import 'package:quizforge_upsc/features/auth/storage/secure_storage.dart';

void main() {
  group('TokenManager & SecureStorage Unit Tests', () {
    late SecureStorage secureStorage;
    late TokenManager tokenManager;

    setUp(() {
      secureStorage = SecureStorage();
      tokenManager = TokenManager(storage: secureStorage);
    });

    test('Saves, loads, and clears access and refresh tokens', () async {
      const sampleAccessToken = 'header.payload_access.signature';
      const sampleRefreshToken = 'header.payload_refresh.signature';

      await tokenManager.saveTokens(
        accessToken: sampleAccessToken,
        refreshToken: sampleRefreshToken,
      );

      final tokens = await tokenManager.loadTokens();
      expect(tokens['accessToken'], equals(sampleAccessToken));
      expect(tokens['refreshToken'], equals(sampleRefreshToken));

      expect(await tokenManager.getAccessToken(), equals(sampleAccessToken));
      expect(await tokenManager.getRefreshToken(), equals(sampleRefreshToken));

      await tokenManager.clearTokens();

      final clearedTokens = await tokenManager.loadTokens();
      expect(clearedTokens['accessToken'], isNull);
      expect(clearedTokens['refreshToken'], isNull);
    });
  });
}
