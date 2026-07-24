import 'package:flutter/material.dart';
import '../../../models/pyq_question_model.dart';

class PyqExplanationSheet extends StatelessWidget {
  final PyqQuestionModel question;
  final String? selectedAnswer;

  const PyqExplanationSheet({
    super.key,
    required this.question,
    this.selectedAnswer,
  });

  static void show(
    BuildContext context, {
    required PyqQuestionModel question,
    String? selectedAnswer,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PyqExplanationSheet(
        question: question,
        selectedAnswer: selectedAnswer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = selectedAnswer != null &&
        (selectedAnswer == question.correctAnswer ||
            selectedAnswer == question.officialAnswer);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.lightbulb_outline,
                  color: isCorrect ? Colors.green : Colors.amber.shade800,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCorrect ? "Correct Answer!" : "Answer & Explanation",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Correct Answer Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Correct Answer: ${question.correctAnswer} (${question.officialAnswer})",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Official / Main Explanation
            if (question.explanation.official.isNotEmpty) ...[
              const Text(
                "Detailed Explanation",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                question.explanation.official,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 16),
            ],

            // Why incorrect options are wrong
            if (question.explanation.incorrectOptions != null &&
                question.explanation.incorrectOptions!.isNotEmpty) ...[
              const Text(
                "Option Analysis",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...question.explanation.incorrectOptions!.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey.shade300,
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Related Concepts
            if (question.explanation.relatedConcepts != null &&
                question.explanation.relatedConcepts!.isNotEmpty) ...[
              const Text(
                "Related Concepts",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: question.explanation.relatedConcepts!.map((concept) {
                  return Chip(
                    avatar: const Icon(Icons.auto_awesome, size: 16),
                    label: Text(concept),
                    backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Previous Year Trend
            if (question.explanation.previousYearTrend != null &&
                question.explanation.previousYearTrend!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "UPSC Trend: ${question.explanation.previousYearTrend}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Tags & Metadata
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(label: Text("Year: ${question.year}")),
                Chip(label: Text("Subject: ${question.subject}")),
                Chip(label: Text("Topic: ${question.topic}")),
                Chip(label: Text("Difficulty: ${question.difficulty}")),
                if (question.reference.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.menu_book, size: 16),
                    label: Text(question.reference),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
