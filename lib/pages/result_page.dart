import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final int attempted;

  const ResultPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.attempted,
  });

  @override
  Widget build(BuildContext context) {
    final skipped = totalQuestions - attempted;
    final incorrect = attempted - score;

    final accuracy = totalQuestions == 0 ? 0.0 : (score / totalQuestions) * 100;

    String performance;
    Color performanceColor;
    IconData performanceIcon;

    if (accuracy >= 80) {
      performance = "Excellent";
      performanceColor = Colors.green;
      performanceIcon = Icons.workspace_premium;
    } else if (accuracy >= 60) {
      performance = "Good";
      performanceColor = Colors.blue;
      performanceIcon = Icons.thumb_up;
    } else if (accuracy >= 40) {
      performance = "Average";
      performanceColor = Colors.orange;
      performanceIcon = Icons.trending_up;
    } else {
      performance = "Needs Improvement";
      performanceColor = Colors.red;
      performanceIcon = Icons.school;
    }

    Widget statCard({
      required IconData icon,
      required String title,
      required String value,
      required Color color,
    }) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Quiz Result"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Icon(
                performanceIcon,
                size: 80,
                color: performanceColor,
              ),
              const SizedBox(height: 20),
              Text(
                "$score / $totalQuestions",
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                performance,
                style: TextStyle(
                  color: performanceColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: accuracy / 100,
                      strokeWidth: 12,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${accuracy.toStringAsFixed(1)}%",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Accuracy",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              statCard(
                icon: Icons.check_circle,
                title: "Correct",
                value: score.toString(),
                color: Colors.green,
              ),
              statCard(
                icon: Icons.cancel,
                title: "Incorrect",
                value: incorrect.toString(),
                color: Colors.red,
              ),
              statCard(
                icon: Icons.edit_note,
                title: "Attempted",
                value: attempted.toString(),
                color: Colors.blue,
              ),
              statCard(
                icon: Icons.skip_next,
                title: "Skipped",
                value: skipped.toString(),
                color: Colors.orange,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text(
                    "Back to Home",
                  ),
                  onPressed: () {
                    Navigator.popUntil(
                      context,
                      (route) => route.isFirst,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Keep practicing. Consistency is the key to UPSC success.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
