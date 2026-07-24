import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/pages/api_key_setup_page.dart';
import 'package:quizforge_upsc/repositories/api_key_repository.dart';

class MockApiKeyRepository implements ApiKeyRepository {
  @override
  Future<void> saveKey(String key) async {}
  @override
  Future<String?> loadKey() async => null;
  @override
  Future<void> deleteKey() async {}
  @override
  Future<bool> hasKey() async => false;
  @override
  Future<bool> validateKey(String key) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  String? launchedUrl;
  bool shouldFail = false;

  String? mockClipboardText;

  setUp(() {
    launchedUrl = null;
    shouldFail = false;
    mockClipboardText = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'canLaunch') {
          return !shouldFail;
        }
        if (methodCall.method == 'launch' || methodCall.method == 'launchUrl') {
          if (shouldFail) return false;
          launchedUrl = methodCall.arguments['url'] as String?;
          return true;
        }
        return true;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.getData') {
          return mockClipboardText != null
              ? <String, dynamic>{'text': mockClipboardText}
              : null;
        }
        if (methodCall.method == 'Clipboard.setData') {
          mockClipboardText = methodCall.arguments['text'] as String?;
          return null;
        }
        return null;
      },
    );

    ApiKeyRepository.instance = MockApiKeyRepository();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  testWidgets(
      'First-run onboarding components, trust card, and guide are visible',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ApiKeySetupPage(),
      ),
    );

    // Verify Title and Header
    expect(find.text("Welcome to QuizForge AI"), findsNWidgets(2));
    expect(
      find.textContaining("QuizForge AI uses Google's Gemini AI"),
      findsOneWidget,
    );
    expect(
      find.textContaining(
          "To use these AI features, you'll need a FREE Gemini API Key"),
      findsOneWidget,
    );

    // Verify Privacy & Security Trust Card
    expect(find.text("🔒 Privacy & Security"), findsOneWidget);
    expect(
      find.text("Your API key stays securely on your device."),
      findsOneWidget,
    );
    expect(
      find.text("QuizForge AI never shares your API key with anyone."),
      findsOneWidget,
    );
    expect(
      find.text(
        "Your key is used only to communicate directly with Google's Gemini API for generating quizzes.",
      ),
      findsOneWidget,
    );

    // Verify Buttons
    expect(find.text("Get Free Gemini API Key"), findsOneWidget);
    expect(find.text("I Already Have a Key"), findsOneWidget);

    // Verify Step-by-step instructions and time estimate
    await tester.scrollUntilVisible(
      find.text("How to Get Your Free API Key"),
      500,
    );
    expect(find.text("How to Get Your Free API Key"), findsOneWidget);
    expect(find.text("⏱ Takes less than 2 minutes."), findsOneWidget);
    expect(find.text('Tap "Get Free Gemini API Key"'), findsOneWidget);
    expect(find.text("Sign in using your Google Account."), findsOneWidget);
    expect(find.text("Click Create API Key"), findsOneWidget);
    expect(find.text("Copy the generated API key."), findsOneWidget);
    expect(find.text("Return to QuizForge AI."), findsOneWidget);
    expect(find.text("Paste your API key."), findsOneWidget);
    expect(find.text("Tap Validate & Save"), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tapping Get Free Gemini API Key launches browser URL',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ApiKeySetupPage(),
      ),
    );

    final btnFinder = find.text("Get Free Gemini API Key");
    await tester.ensureVisible(btnFinder);
    await tester.tap(btnFinder);
    await tester.pump();

    expect(
      launchedUrl,
      equals("https://aistudio.google.com/app/apikey"),
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Browser launch failure displays copy fallback dialog with Close button',
      (WidgetTester tester) async {
    shouldFail = true;

    await tester.pumpWidget(
      const MaterialApp(
        home: ApiKeySetupPage(),
      ),
    );

    final btnFinder = find.text("Get Free Gemini API Key");
    await tester.ensureVisible(btnFinder);
    await tester.tap(btnFinder);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify dialog elements
    expect(find.text("Unable to open Google AI Studio."), findsOneWidget);
    expect(find.text("Please visit:"), findsOneWidget);
    expect(
      find.text("https://aistudio.google.com/app/apikey"),
      findsOneWidget,
    );
    expect(find.text("Copy Link"), findsOneWidget);
    expect(find.text("Close"), findsOneWidget);

    await tester.tap(find.text("Close"));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tapping I Already Have a Key displays and focuses text field',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ApiKeySetupPage(),
      ),
    );

    expect(find.byType(TextField), findsNothing);

    final btnFinder = find.text("I Already Have a Key");
    await tester.ensureVisible(btnFinder);
    await tester.tap(btnFinder);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TextField), findsOneWidget);

    final FocusScopeNode focusScope =
        FocusScope.of(tester.element(find.byType(TextField)));
    expect(focusScope.focusedChild, isNotNull);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('App resume events show and autofocus the text field',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ApiKeySetupPage(),
      ),
    );

    expect(find.byType(TextField), findsNothing);

    final testerBinding = tester.binding;
    testerBinding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TextField), findsOneWidget);
    final FocusScopeNode focusScope =
        FocusScope.of(tester.element(find.byType(TextField)));
    expect(focusScope.focusedChild, isNotNull);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Clipboard detection prompts when valid AIza key is in clipboard',
      (WidgetTester tester) async {
    await Clipboard.setData(
      const ClipboardData(text: "AIzaSyTestApiKeyString123456"),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ApiKeySetupPage(),
      ),
    );

    final testerBinding = tester.binding;
    testerBinding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("Paste Gemini API Key?"), findsOneWidget);
    expect(
      find.text(
        "We found what looks like a Gemini API Key.\n\nWould you like to paste it?",
      ),
      findsOneWidget,
    );
    expect(find.text("Paste"), findsOneWidget);
    expect(find.text("Cancel"), findsOneWidget);

    await tester.tap(find.text("Paste"));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 300));

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, equals("AIzaSyTestApiKeyString123456"));

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
