import 'package:flutter/material.dart';

import '../../controllers/pyq_controller.dart';
import '../../models/pyq_question_model.dart';
import 'pyq_attempt_page.dart';

class PyqSubjectTopicPage extends StatefulWidget {
  const PyqSubjectTopicPage({super.key});

  @override
  State<PyqSubjectTopicPage> createState() => _PyqSubjectTopicPageState();
}

class _PyqSubjectTopicPageState extends State<PyqSubjectTopicPage> {
  final PyqController pyqController = PyqController();
  List<PyqQuestionModel> allQuestions = [];
  bool isLoading = true;

  final List<String> subjects = [
    "Polity",
    "History",
    "Economy",
    "Geography",
    "Environment",
    "Science & Technology",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await pyqController.getAllQuestions();
    if (mounted) {
      setState(() {
        allQuestions = list;
        isLoading = false;
      });
    }
  }

  void _startSubjectSession(String subject) {
    final list = allQuestions
        .where((q) => q.subject.toLowerCase() == subject.toLowerCase())
        .toList();
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No questions available for $subject.")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PyqAttemptPage(
          questions: list,
          title: "$subject PYQs",
        ),
      ),
    ).then((_) => _loadData());
  }

  void _startTopicSession(String subject, String topic) {
    final list = allQuestions
        .where((q) =>
            q.subject.toLowerCase() == subject.toLowerCase() &&
            q.topic.toLowerCase() == topic.toLowerCase())
        .toList();
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No questions available for $topic.")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PyqAttemptPage(
          questions: list,
          title: "$topic PYQs",
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Subject & Topic Wise PYQs"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final subjectQuestions = allQuestions
                    .where(
                        (q) => q.subject.toLowerCase() == subject.toLowerCase())
                    .toList();

                final Map<String, int> topicCounts = {};
                for (final q in subjectQuestions) {
                  topicCounts[q.topic] = (topicCounts[q.topic] ?? 0) + 1;
                }

                final attempted =
                    subjectQuestions.where((q) => q.isAttempted).length;
                final total = subjectQuestions.length;
                final progress = total == 0 ? 0.0 : attempted / total;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("$total Questions | $attempted Attempted"),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    trailing: TextButton(
                      onPressed: () => _startSubjectSession(subject),
                      child: const Text("Practice All"),
                    ),
                    children: [
                      const Divider(),
                      if (topicCounts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text("No specific topics imported yet."),
                        )
                      else
                        ...topicCounts.entries.map((entry) {
                          return ListTile(
                            title: Text(entry.key),
                            subtitle: Text("${entry.value} Questions"),
                            trailing:
                                const Icon(Icons.play_circle_fill_outlined),
                            onTap: () => _startTopicSession(subject, entry.key),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
