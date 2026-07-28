import 'package:flutter/material.dart';

class HelpFeedbackScreen extends StatelessWidget {
  const HelpFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Feedback'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          const ExpansionTile(
            title: Text('How does the Learning Journey Engine work?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'The Learning Journey Engine dynamically sequences your stages, milestones, and checkpoints based on your study habits, assessment scores, and target exam deadline.',
                ),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('Is TITAN fully functional offline?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Yes! All 16 TITAN engines utilize local storage and cache layers so you can continue learning offline.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback form opened!')),
              );
            },
            icon: const Icon(Icons.feedback),
            label: const Text('Submit Feedback / Report Issue'),
          ),
        ],
      ),
    );
  }
}
