import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_identity/titan_identity.dart';

void main() {
  group('Material 3 Widgets Tests', () {
    final now = DateTime.now();
    final user = User(
      id: 'usr_widget',
      email: 'widget@example.com',
      displayName: 'Widget User',
      providerType: AuthProviderType.google,
      createdAt: now,
    );
    final session = UserSession(
      sessionId: 'sess_widget',
      user: user,
      accessToken: 'token_widget',
      expiresAt: now.add(const Duration(hours: 10)),
    );

    testWidgets('UserAvatar renders fallback initials and responds to tap',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              user: user,
              radius: 24,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('WU'), findsOneWidget);
      await tester.tap(find.byType(UserAvatar));
      expect(tapped, isTrue);
    });

    testWidgets('SessionStatusChip displays Active Session badge',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionStatusChip(session: session),
          ),
        ),
      );

      expect(find.text('Active Session'), findsOneWidget);
    });

    testWidgets('SessionStatusChip displays Guest Mode badge for guest user',
        (tester) async {
      final guestUser = user.copyWith(isGuest: true);
      final guestSession = session.copyWith(user: guestUser);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionStatusChip(session: guestSession),
          ),
        ),
      );

      expect(find.text('Guest Mode'), findsOneWidget);
    });

    testWidgets('ProviderButton renders label and triggers callback',
        (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderButton(
              providerType: AuthProviderType.google,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Sign in with Google'), findsOneWidget);
      await tester.tap(find.byType(ProviderButton));
      expect(pressed, isTrue);
    });

    testWidgets('SignInButton triggers onPressed callback', (tester) async {
      var clicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignInButton(
              onPressed: () => clicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Sign In'), findsOneWidget);
      await tester.tap(find.byType(SignInButton));
      expect(clicked, isTrue);
    });

    testWidgets('ProfileCard renders user details and action buttons',
        (tester) async {
      var signedOut = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileCard(
              session: session,
              onSignOutPressed: () => signedOut = true,
            ),
          ),
        ),
      );

      expect(find.text('Widget User'), findsOneWidget);
      expect(find.text('widget@example.com'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      await tester.tap(find.text('Sign Out'));
      expect(signedOut, isTrue);
    });

    testWidgets('AccountMenu opens popup menu options', (tester) async {
      var profileSelected = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                AccountMenu(
                  session: session,
                  onProfilePressed: () => profileSelected = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AccountMenu));
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      await tester.tap(find.text('My Profile'));
      await tester.pumpAndSettle();
      expect(profileSelected, isTrue);
    });
  });
}
