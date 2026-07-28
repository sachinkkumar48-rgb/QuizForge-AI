import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_ai_mentor/titan_ai_mentor.dart';

class TutorView extends ConsumerStatefulWidget {
  const TutorView({super.key});

  @override
  ConsumerState<TutorView> createState() => _TutorViewState();
}

class _TutorViewState extends ConsumerState<TutorView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor & Mentor'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MentorMessageBubble(
                  message: MentorMessage(
                    id: 'm1',
                    sender: MentorMessageSender.mentor,
                    content:
                        'Hello Aspirant! How can I assist your UPSC preparation today? We can resolve concepts, analyze misconceptions, or plan targeted revision.',
                    timestamp: DateTime.now(),
                  ),
                ),
              ],
            ),
          ),
          MentorInputBar(
            controller: _controller,
            onSend: (text) {},
          ),
        ],
      ),
    );
  }
}
