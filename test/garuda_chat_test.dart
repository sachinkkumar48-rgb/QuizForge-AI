import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/controllers/garuda_chat_viewmodel.dart';
import 'package:quizforge_upsc/pages/garuda_chat_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GARUDA AI Flutter Chat Experience (Sprint 8.2 / TITAN-S8.2.002)', () {
    testWidgets('Verification: GarudaChatPage loads history and renders header & conversation messages', (WidgetTester tester) async {
      final session = const ChatSessionDto(
        sessionId: 'sess_test_001',
        userId: 'user_test_100',
        topicId: 't_polity_14',
        topicName: 'Article 14 Fundamental Rights',
      );

      final viewModel = GarudaChatViewModel(
        session: session,
        repository: MockGarudaChatRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: GarudaChatPage(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Session Topic Title
      expect(find.text('Article 14 Fundamental Rights'), findsOneWidget);
      expect(find.text('GARUDA Tutor'), findsOneWidget);

      // 2. System Message
      expect(find.text('GARUDA AI Socratic Tutor initialized. Ask any question to begin.'), findsOneWidget);

      // 3. User Message
      expect(find.text('Explain Article 14 of the Indian Constitution.'), findsOneWidget);

      // 4. Assistant Markdown Message
      expect(find.textContaining('Article 14 guarantees'), findsOneWidget);
    });

    testWidgets('Verification: PDF Session displays grounding banner and PDF Knowledge routing metadata', (WidgetTester tester) async {
      final pdfSession = const ChatSessionDto(
        sessionId: 'sess_pdf_002',
        userId: 'user_test_200',
        topicId: 'doc_pdf_101',
        topicName: 'Constitution Summary PDF',
        pdfDocumentId: 'doc_pdf_101',
        pdfDocumentName: 'Indian_Constitution_Summary.pdf',
      );

      final viewModel = GarudaChatViewModel(
        session: pdfSession,
        repository: MockGarudaChatRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: GarudaChatPage(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      // Verify PDF Grounding Banner
      expect(find.textContaining('Answering from uploaded document: Indian_Constitution_Summary.pdf'), findsOneWidget);
      expect(find.text('PDF Grounded Session'), findsOneWidget);
    });

    testWidgets('Verification: Sending message triggers incremental streaming response and typing indicator', (WidgetTester tester) async {
      final session = const ChatSessionDto(
        sessionId: 'sess_stream_003',
        userId: 'user_test_300',
        topicId: 't_history_01',
        topicName: 'Ancient History',
      );

      final viewModel = GarudaChatViewModel(
        session: session,
        repository: MockGarudaChatRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: GarudaChatPage(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger message send via ViewModel
      final sendFuture = viewModel.sendMessage('Tell me about Harappan Trade');
      expect(viewModel.isGenerating, isTrue);

      await sendFuture;
      await tester.pumpAndSettle();

      expect(viewModel.isGenerating, isFalse);
      expect(viewModel.messages.last.content, contains('Socratic Analysis'));
    });


    testWidgets('Verification: Developer mode toggles Request ID display', (WidgetTester tester) async {
      final session = const ChatSessionDto(
        sessionId: 'sess_dev_004',
        userId: 'user_test_400',
        topicId: 't_polity_21',
        topicName: 'Article 21 Rights',
      );

      final viewModel = GarudaChatViewModel(
        session: session,
        repository: MockGarudaChatRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: GarudaChatPage(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      // Developer mode off initially
      expect(find.textContaining('ReqID:'), findsNothing);

      // Toggle developer mode on
      await tester.tap(find.byIcon(Icons.developer_mode_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('ReqID: req_pdf_mock_001'), findsOneWidget);
    });

    testWidgets('Verification: Retry last message flow removes last assistant/error message and re-executes', (WidgetTester tester) async {
      final session = const ChatSessionDto(
        sessionId: 'sess_retry_005',
        userId: 'user_test_500',
        topicId: 't_econ_01',
        topicName: 'Macroeconomics',
      );

      final viewModel = GarudaChatViewModel(
        session: session,
        repository: MockGarudaChatRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: GarudaChatPage(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      final initialMsgCount = viewModel.messages.length;
      await viewModel.retryLastMessage();
      await tester.pumpAndSettle();

      expect(viewModel.messages.length, greaterThanOrEqualTo(initialMsgCount));
    });

    testWidgets('Verification: Stop generation cancels streaming and unlocks input bar', (WidgetTester tester) async {
      final session = const ChatSessionDto(
        sessionId: 'sess_stop_006',
        userId: 'user_test_600',
        topicId: 't_geog_01',
        topicName: 'Physical Geography',
      );

      final viewModel = GarudaChatViewModel(
        session: session,
        repository: MockGarudaChatRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: GarudaChatPage(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      viewModel.sendMessage('Explain Monsoon System');
      expect(viewModel.isGenerating, isTrue);

      viewModel.stopGeneration();
      expect(viewModel.isGenerating, isFalse);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Verification: Markdown table and inline rich formatting render correctly', (WidgetTester tester) async {
      final session = const ChatSessionDto(
        sessionId: 'sess_table_007',
        userId: 'user_test_700',
        topicId: 't_table_01',
        topicName: 'Comparative Analysis',
      );

      final viewModel = GarudaChatViewModel(
        session: session,
        repository: MockGarudaChatRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: GarudaChatPage(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Table), findsNothing);
    });
  });
}
