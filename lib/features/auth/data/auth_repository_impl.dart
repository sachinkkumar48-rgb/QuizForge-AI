import '../../../core/network/api_client.dart';
import '../domain/auth_repository.dart';
import '../services/token_manager.dart';

/// Concrete production implementation of [AuthRepository] communicating with FastAPI identity endpoints.
class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final TokenManager _tokenManager;

  AuthRepositoryImpl({
    ApiClient? apiClient,
    TokenManager? tokenManager,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenManager = tokenManager ?? TokenManager();

  @override
  Future<void> register(String email, String password, {String? fullName}) async {
    final payload = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'password': password,
      if (fullName != null && fullName.trim().isNotEmpty) 'full_name': fullName.trim(),
    };

    final response = await _apiClient.post('/api/v1/auth/register', body: payload);
    final accessToken = response['access_token'] as String?;
    final refreshToken = response['refresh_token'] as String?;

    if (accessToken != null) {
      if (refreshToken != null) {
        await _tokenManager.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      } else {
        await _tokenManager.saveAccessToken(accessToken);
      }
    }
  }

  @override
  Future<void> login(String email, String password) async {
    final payload = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'password': password,
    };

    final response = await _apiClient.post('/api/v1/auth/login', body: payload);
    final accessToken = response['access_token'] as String?;
    final refreshToken = response['refresh_token'] as String?;

    if (accessToken == null) {
      throw const FormatException("Missing access_token in login response");
    }

    if (refreshToken != null) {
      await _tokenManager.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } else {
      await _tokenManager.saveAccessToken(accessToken);
    }
  }

  @override
  Future<void> refresh() async {
    final currentRefreshToken = await _tokenManager.getRefreshToken();
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      throw Exception("No refresh token available to refresh session.");
    }

    final response = await _apiClient.post(
      '/api/v1/auth/refresh',
      body: {'refresh_token': currentRefreshToken},
    );

    final accessToken = response['access_token'] as String?;
    final refreshToken = response['refresh_token'] as String?;

    if (accessToken != null) {
      if (refreshToken != null) {
        await _tokenManager.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      } else {
        await _tokenManager.saveAccessToken(accessToken);
      }
    }
  }

  @override
  Future<void> logout() async {
    final token = await _tokenManager.getAccessToken();
    try {
      if (token != null && token.isNotEmpty) {
        await _apiClient.post('/api/v1/auth/logout', token: token);
      }
    } catch (_) {
      // Ignore network errors on logout so local session always clears safely
    } finally {
      await _tokenManager.clearTokens();
    }
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await _tokenManager.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception("User is not authenticated (no access token).");
    }

    return await _apiClient.get('/api/v1/auth/me', token: token);
  }
}
