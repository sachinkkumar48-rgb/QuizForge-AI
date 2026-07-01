import 'package:flutter/material.dart';

import '../models/quiz_model.dart';

class QuizPage extends StatefulWidget {
  final List<QuizQuestion> questions;

  const QuizPage({
    super.key,
    required this.questions,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentQuestion = 0;
  int score = 0;
  String? selectedAnswer;

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Question ${currentQuestion + 1} / ${widget.questions.length}",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value:
              (currentQuestion + 1) / widget.questions.length,
            ),

            const SizedBox(height: 24),

            Text(
              question.question,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ...question.options.map(
                  (option) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedAnswer = option;
                      });
                    },
                    child: Text(option),
                  ),
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedAnswer == question.answer) {
                    score++;
                  }

                  if (currentQuestion <
                      widget.questions.length - 1) {
                    setState(() {
                      currentQuestion++;
                      selectedAnswer = null;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Quiz Finished! Score: $score/${widget.questions.length}",
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  "Next",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}