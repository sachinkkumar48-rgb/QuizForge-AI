import '../auth/auth_provider.dart';
import '../models/user.dart';
import '../models/user_session.dart';

/// Abstract repository interface for Identity & Authentication.
abstract class IdentityRepository {
  /// Retrieves the current authenticated user.
  Future<User?> getCurrentUser();

  /// Retrieves the active user session.
  Future<UserSession?> getActiveSession();

  /// Authenticates user using the specified provider type and credentials.
  Future<UserSession> signIn({
    required AuthProviderType providerType,
    Map<String, dynamic>? credentials,
  });

  /// Registers a new user account using the specified provider.
  Future<UserSession> register({
    required AuthProviderType providerType,
    required Map<String, dynamic> userDetails,
  });

  /// Signs out the active user and clears session tokens.
  Future<void> signOut();

  /// Refreshes active session token.
  Future<UserSession> refreshSession();

  /// Permanently deletes user account and terminates session.
  Future<void> deleteAccount();
}
