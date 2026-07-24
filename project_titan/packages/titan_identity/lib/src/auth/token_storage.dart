import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../models/user_session.dart';

/// Abstract contract for secure token storage.
abstract class TokenStorage {
  /// Persists a session token securely.
  Future<void> saveSession(UserSession session);

  /// Retrieves cached user session.
  Future<UserSession?> getSession();

  /// Clears stored authentication session tokens.
  Future<void> clearSession();
}

/// In-memory & secure token storage implementation.
class SecureTokenStorage implements TokenStorage {
  final StorageService? _storageService;
  static const StorageKey _storageKey =
      StorageKey('user_session', namespace: 'identity');
  UserSession? _cachedSession;

  SecureTokenStorage({
    StorageService? storageService,
    UserSession? initialSession,
  })  : _storageService = storageService,
        _cachedSession = initialSession;

  @override
  Future<void> saveSession(UserSession session) async {
    _cachedSession = session;
    if (_storageService != null) {
      final jsonStr = jsonEncode(session.toJson());
      await _storageService.write<String>(_storageKey, jsonStr);
    }
  }

  @override
  Future<UserSession?> getSession() async {
    if (_storageService != null) {
      final jsonStr = await _storageService.read<String>(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
          _cachedSession = UserSession.fromJson(jsonMap);
          return _cachedSession;
        } catch (_) {
          await clearSession();
        }
      } else {
        _cachedSession = null;
      }
    }
    return _cachedSession;
  }

  @override
  Future<void> clearSession() async {
    _cachedSession = null;
    if (_storageService != null) {
      await _storageService.delete(_storageKey);
    }
  }
}
