import 'package:flutter/material.dart';
import '../controllers/quiz_session_controller.dart';
import '../models/quiz_model.dart';
import 'result_page.dart';

class ReviewPage extends StatelessWidget {
  final QuizSessionController controller;

  const ReviewPage({
    super.key,
    required this.controller,
  });

  Color _getStatusColor(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.notVisited:
        return Colors.grey.shade300;
      case QuestionStatus.visited:
        return Colors.amber.shade600;
      case QuestionStatus.answered:
        return Colors.green.shade600;
      case QuestionStatus.markedForReview:
        return Colors.purple.shade600;
    }
  }

  String _getStatusName(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.notVisited:
        return "Not Visited";
      case QuestionStatus.visited:
        return "Visited";
      case QuestionStatus.answered:
        return "Answered";
      case QuestionStatus.markedForReview:
        return "Marked for Review";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Review"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.questions.length,
                itemBuilder: (context, index) {
                  final question = controller.questions[index];
                  final status =
                      controller.statuses[index] ?? QuestionStatus.notVisited;
                  final color = _getStatusColor(status);
                  final isAnswered = status == QuestionStatus.answered;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    child: InkWell(
                      onTap: () {
                        controller.jumpToQuestion(index);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: color,
                              foregroundColor:
                                  status == QuestionStatus.notVisited
                                      ? Colors.black87
                                      : Colors.white,
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    question.question,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getStatusName(status),
                                    style: TextStyle(
                                      color: color == Colors.grey.shade300
                                          ? Colors.grey.shade600
                                          : color,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isAnswered &&
                                controller.answers[index] != null) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  "Answer: ${controller.answers[index]}",
                                  style: const TextStyle(fontSize: 11),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text("Back to Quiz"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        controller.submitQuiz(
                          onFinished: (score, total, attempted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultPage(
                                  score: score,
                                  totalQuestions: total,
                                  attempted: attempted,
                                ),
                              ),
                              (route) => route.isFirst,
                            );
                          },
                        );
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text("Submit Quiz"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
