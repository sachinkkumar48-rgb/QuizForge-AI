import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isGuest;
  final bool isOnboardingCompleted;
  final String userId;
  final String displayName;
  final String email;

  const AuthState({
    this.isAuthenticated = true, // Default to authenticated for direct demo
    this.isGuest = false,
    this.isOnboardingCompleted = true,
    this.userId = 'user_titan_aspirant',
    this.displayName = 'UPSC Aspirant',
    this.email = 'aspirant@titan.academy',
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isGuest,
    bool? isOnboardingCompleted,
    String? userId,
    String? displayName,
    String? email,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isGuest: isGuest ?? this.isGuest,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void loginAsGuest() {
    state = state.copyWith(
      isAuthenticated: true,
      isGuest: true,
      userId: 'guest_aspirant',
      displayName: 'Guest Aspirant',
    );
  }

  void loginWithEmail(String email, String displayName) {
    state = state.copyWith(
      isAuthenticated: true,
      isGuest: false,
      email: email,
      displayName: displayName,
    );
  }

  void completeOnboarding() {
    state = state.copyWith(isOnboardingCompleted: true);
  }

  void logout() {
    state = const AuthState(
      isAuthenticated: false,
      isGuest: false,
      isOnboardingCompleted: true,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
