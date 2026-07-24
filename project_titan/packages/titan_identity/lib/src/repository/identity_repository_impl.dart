import '../auth/auth_provider.dart';
import '../auth/email_password_auth_provider.dart';
import '../auth/google_auth_provider.dart';
import '../auth/guest_auth_provider.dart';
import '../models/user.dart';
import '../models/user_session.dart';
import '../session/session_manager.dart';
import 'identity_repository.dart';

/// Concrete implementation of [IdentityRepository] managing provider registry and session state.
class IdentityRepositoryImpl implements IdentityRepository {
  final SessionManager _sessionManager;
  final Map<AuthProviderType, AuthProvider> _providers;

  IdentityRepositoryImpl({
    SessionManager? sessionManager,
    Map<AuthProviderType, AuthProvider>? providers,
  })  : _sessionManager = sessionManager ?? SessionManager(),
        _providers = providers ??
            {
              AuthProviderType.guest: const GuestAuthProvider(),
              AuthProviderType.google: const GoogleAuthProvider(),
              AuthProviderType.emailPassword: const EmailPasswordAuthProvider(),
            };

  @override
  Future<User?> getCurrentUser() async {
    final session = await getActiveSession();
    return session?.user;
  }

  @override
  Future<UserSession?> getActiveSession() async {
    var session = _sessionManager.currentSession;
    session ??= await _sessionManager.initialize();
    return session;
  }

  @override
  Future<UserSession> signIn({
    required AuthProviderType providerType,
    Map<String, dynamic>? credentials,
  }) async {
    final provider = _getProvider(providerType);
    final session = await provider.signIn(credentials: credentials);
    await _sessionManager.updateSession(session);
    return session;
  }

  @override
  Future<UserSession> register({
    required AuthProviderType providerType,
    required Map<String, dynamic> userDetails,
  }) async {
    final provider = _getProvider(providerType);
    final session = await provider.register(userDetails: userDetails);
    await _sessionManager.updateSession(session);
    return session;
  }

  @override
  Future<void> signOut() async {
    final session = _sessionManager.currentSession;
    if (session != null) {
      final provider = _providers[session.user.providerType];
      if (provider != null) {
        await provider.signOut(session);
      }
    }
    await _sessionManager.clearSession();
  }

  @override
  Future<UserSession> refreshSession() async {
    final session = _sessionManager.currentSession;
    if (session == null) {
      throw StateError('No active session to refresh.');
    }
    final provider = _getProvider(session.user.providerType);
    final refreshed = await provider.refreshSession(session);
    await _sessionManager.updateSession(refreshed);
    return refreshed;
  }

  @override
  Future<void> deleteAccount() async {
    await signOut();
  }

  AuthProvider _getProvider(AuthProviderType type) {
    final provider = _providers[type];
    if (provider == null) {
      throw UnsupportedError('Auth provider "$type" is not registered.');
    }
    return provider;
  }
}
