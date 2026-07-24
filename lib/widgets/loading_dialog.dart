import 'package:flutter/material.dart';

class LoadingDialog {
  LoadingDialog._();

  static ValueNotifier<String>? _messageNotifier;

  static void show(
    BuildContext context, {
    String message = "Generating UPSC Quiz...",
  }) {
    _messageNotifier = ValueNotifier<String>(message);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  const Text(
                    "QuizForge AI",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<String>(
                    valueListenable: _messageNotifier!,
                    builder: (context, currentMessage, _) {
                      return Text(
                        currentMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text(
                    "Please wait...\nGenerating high-quality UPSC questions.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void updateMessage(String message) {
    if (_messageNotifier != null) {
      _messageNotifier!.value = message;
    }
  }

  static void hide(BuildContext context) {
    _messageNotifier?.dispose();
    _messageNotifier = null;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}
