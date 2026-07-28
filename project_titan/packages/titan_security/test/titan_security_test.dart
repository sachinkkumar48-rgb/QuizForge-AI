import 'package:flutter_test/flutter_test.dart';
import 'package:titan_security/titan_security.dart';

void main() {
  group('Titan Security Package Comprehensive Unit Tests', () {
    test('SecretManager obfuscates, hashes, verifies, and loads secrets', () {
      expect(SecretManager.obfuscate('MY_SECRET_KEY'), equals('MY****EY'));
      expect(SecretManager.obfuscate('123'), equals('****'));
      expect(SecretManager.obfuscate(''), equals(''));

      final manager = SecretManager({'env_key': 'env_val'});
      expect(manager.hasSecret('env_key'), isTrue);
      expect(manager.getSecret('env_key'), equals('env_val'));

      manager.setSecret('api_token', 'super_secret_value');
      expect(manager.getSecret('api_token'), equals('super_secret_value'));
      expect(manager.verifySecret('api_token', 'super_secret_value'), isTrue);
      expect(manager.verifySecret('api_token', 'wrong_value'), isFalse);

      manager.loadFromMap({'key2': 'val2'});
      expect(manager.hasSecret('key2'), isTrue);

      manager.clear();
      expect(manager.hasSecret('api_token'), isFalse);
    });

    test('EncryptionService encrypts, decrypts, hashes, and computes HMAC', () {
      final service = EncryptionService(key: 'TEST_KEY');
      const text = 'Hello TITAN 2026';
      final encrypted = service.encrypt(text);
      expect(encrypted, isNot(equals(text)));

      final decrypted = service.decrypt(encrypted);
      expect(decrypted, equals(text));

      expect(service.encrypt(''), equals(''));
      expect(service.decrypt(''), equals(''));

      final hash1 = service.hash('input');
      final hash2 = service.hash('input');
      expect(hash1, equals(hash2));

      final hmac = service.computeHmac('data', 'secret');
      expect(hmac, isNotEmpty);

      final invalidService = EncryptionService(key: 'WRONG_KEY');
      expect(() => invalidService.decrypt(encrypted),
          throwsA(isA<FormatException>()));
    });

    test('SecureApiKeyManager validates API key formats', () {
      final manager = SecureApiKeyManager();
      expect(manager.isValidApiKey('1234567890'), isTrue);
      expect(manager.isValidApiKey('short'), isFalse);
      expect(manager.isValidApiKey(null), isFalse);
      expect(manager.isValidApiKey('   '), isFalse);
    });

    test('CertificateValidator validates domain and fingerprints', () {
      const validator = CertificateValidator(
        allowedDomains: ['api.quizforge.ai'],
        allowedSha256Fingerprints: ['AA:BB:CC:DD'],
      );
      expect(validator.allowedSha256Fingerprints, contains('AA:BB:CC:DD'));
      expect(validator.allowedDomains, contains('api.quizforge.ai'));
    });

    test('PermissionManager tracks permission status and checks grant status',
        () async {
      final manager = PermissionManager();
      var status = await manager.checkPermission('camera');
      expect(status, equals(PermissionStatus.granted));
      expect(await manager.isGranted('camera'), isTrue);

      manager.setPermissionStatus('mic', PermissionStatus.denied);
      status = await manager.checkPermission('mic');
      expect(status, equals(PermissionStatus.denied));
      expect(await manager.isGranted('mic'), isFalse);

      manager.reset();
      expect(await manager.checkPermission('mic'),
          equals(PermissionStatus.granted));
    });
  });
}
