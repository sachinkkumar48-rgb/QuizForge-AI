import 'dart:async';

import '../auth/token_storage.dart';
import '../models/user.dart';
import '../models/user_session.dart';

/// Reactive manager maintaining active user authentication session state.
class SessionManager {
  final TokenStorage _tokenStorage;
  UserSession? _currentSession;
  final StreamController<UserSession?> _sessionController =
      StreamController<UserSession?>.broadcast();

  SessionManager({
    TokenStorage? tokenStorage,
    UserSession? initialSession,
  })  : _tokenStorage =
            tokenStorage ?? SecureTokenStorage(initialSession: initialSession),
        _currentSession = initialSession;

  /// Retrieves the active user session.
  UserSession? get currentSession => _currentSession;

  /// Stream of user session state changes for real-time reactivity.
  Stream<UserSession?> get sessionStream => _sessionController.stream;

  /// Retrieves the active user if authenticated.
  User? get currentUser => _currentSession?.user;

  /// Checks if a session is currently active and valid.
  bool get isAuthenticated =>
      _currentSession != null &&
      _currentSession!.isActive &&
      !_currentSession!.isExpired;

  /// Initializes session state from secure storage.
  Future<UserSession?> initialize() async {
    _currentSession = await _tokenStorage.getSession();
    _sessionController.add(_currentSession);
    return _currentSession;
  }

  /// Sets the active session and persists to token storage.
  Future<void> updateSession(UserSession session) async {
    _currentSession = session;
    await _tokenStorage.saveSession(session);
    _sessionController.add(_currentSession);
  }

  /// Clears active session state and wipes stored tokens.
  Future<void> clearSession() async {
    _currentSession = null;
    await _tokenStorage.clearSession();
    _sessionController.add(null);
  }

  /// Closes the stream controller on disposal.
  Future<void> dispose() async {
    await _sessionController.close();
  }
}
