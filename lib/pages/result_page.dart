import 'package:flutter/material.dart';
import '../models/quiz_analytics.dart';
import '../widgets/analytics_dashboard.dart';

class ResultPage extends StatelessWidget {
  final QuizAnalytics analytics;

  const ResultPage({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Quiz Result"),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 800;

            final mainButton = SizedBox(
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
            );

            final quoteWidget = Text(
              "Keep practicing. Consistency is the key to UPSC success.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            );

            if (isLargeScreen) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    AnalyticsDashboard(analytics: analytics),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 300,
                          child: mainButton,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    quoteWidget,
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AnalyticsDashboard(analytics: analytics),
                  const SizedBox(height: 24),
                  mainButton,
                  const SizedBox(height: 20),
                  quoteWidget,
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
