import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final int score;
  final int totalQuestions;

  const ResultPage({
    super.key,
    required this.score,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = (score / totalQuestions) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Result"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 90,
              color: Colors.amber,
            ),

            const SizedBox(height: 20),

            Text(
              "$score / $totalQuestions",
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "${percentage.toStringAsFixed(1)}%",
              style: const TextStyle(
                fontSize: 26,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text("Back to Home"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}