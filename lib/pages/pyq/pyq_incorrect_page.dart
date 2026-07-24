import 'package:flutter/material.dart';

import '../../controllers/pyq_controller.dart';
import '../../models/pyq_question_model.dart';
import 'pyq_attempt_page.dart';

class PyqIncorrectPage extends StatefulWidget {
  const PyqIncorrectPage({super.key});

  @override
  State<PyqIncorrectPage> createState() => _PyqIncorrectPageState();
}

class _PyqIncorrectPageState extends State<PyqIncorrectPage> {
  final PyqController pyqController = PyqController();
  List<PyqQuestionModel> incorrectQuestions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncorrect();
  }

  Future<void> _loadIncorrect() async {
    final list = await pyqController.getIncorrectQuestions();
    if (mounted) {
      setState(() {
        incorrectQuestions = list;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incorrect Questions (Mistake Bank)"),
        centerTitle: true,
        actions: [
          if (incorrectQuestions.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PyqAttemptPage(
                      questions: incorrectQuestions,
                      title: "Mistake Bank Practice",
                    ),
                  ),
                ).then((_) => _loadIncorrect());
              },
              child: const Text(
                "Fix All",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : incorrectQuestions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_outline,
                          size: 70, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        "No Mistakes Found!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Great job! Any questions answered incorrectly will appear here.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: incorrectQuestions.length,
                  itemBuilder: (context, index) {
                    final q = incorrectQuestions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: Colors.red.shade300.withValues(alpha: 0.5)),
                      ),
                      color: Colors.red.withValues(alpha: 0.03),
                      child: ListTile(
                        title: Text(
                          q.question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text("${q.year} • ${q.subject} • ${q.topic}"),
                        ),
                        trailing: const Icon(Icons.refresh, color: Colors.red),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PyqAttemptPage(
                                questions: [q],
                                title: "Retry Incorrect Question",
                              ),
                            ),
                          ).then((_) => _loadIncorrect());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
