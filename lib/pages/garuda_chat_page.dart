import 'package:flutter/material.dart';
import 'package:quizforge_upsc/controllers/garuda_chat_viewmodel.dart';
import 'package:quizforge_upsc/widgets/garuda_chat_widgets.dart';

/// GARUDA AI Production Learner-Facing Chat Experience Page
class GarudaChatPage extends StatefulWidget {
  final GarudaChatViewModel viewModel;

  const GarudaChatPage({
    super.key,
    required this.viewModel,
  });

  @override
  State<GarudaChatPage> createState() => _GarudaChatPageState();
}

class _GarudaChatPageState extends State<GarudaChatPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadSessionHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      widget.viewModel.updateScrollPosition(
        _scrollController.offset,
        _scrollController.position.maxScrollExtent,
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vm = widget.viewModel;

    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        // Auto-scroll on new streaming token when user is near bottom
        if (vm.isGenerating && _scrollController.hasClients) {
          final isNearBottom = _scrollController.offset >=
              _scrollController.position.maxScrollExtent - 150;
          if (isNearBottom) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.session.topicName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  vm.session.isPdfSession ? 'PDF Grounded Session' : 'GARUDA Tutor',
                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.developer_mode_rounded,
                  color: vm.developerMode ? colorScheme.primary : colorScheme.outline,
                ),
                tooltip: 'Toggle Developer Mode (Request ID)',
                onPressed: vm.toggleDeveloperMode,
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh History',
                onPressed: vm.loadSessionHistory,
              ),
            ],
          ),
          body: Column(
            children: [
              if (vm.session.isPdfSession && vm.session.pdfDocumentName != null)
                PdfGroundingBanner(documentName: vm.session.pdfDocumentName!),
              Expanded(
                child: vm.isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading session history...'),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(top: 12, bottom: 20),
                            itemCount: vm.messages.length,
                            itemBuilder: (context, index) {
                              final msg = vm.messages[index];
                              return ChatMessageTile(
                                message: msg,
                                developerMode: vm.developerMode,
                                onRetry: vm.retryLastMessage,
                              );
                            },
                          ),
                          if (vm.showScrollToBottom)
                            Positioned(
                              right: 16,
                              bottom: 16,
                              child: ChatScrollToBottomButton(
                                onPressed: _scrollToBottom,
                              ),
                            ),
                        ],
                      ),
              ),
              ChatInputBar(
                onSend: (text) async {
                  await vm.sendMessage(text);
                  _scrollToBottom();
                },
                onStop: vm.stopGeneration,
                isGenerating: vm.isGenerating,
              ),
            ],
          ),
        );
      },
    );
  }
}
