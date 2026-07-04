import 'package:flutter/material.dart';

import '../models/quiz_model.dart';
import 'result_page.dart';

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

final Map<int, String?> answers = {};

QuizQuestion get question =>
widget.questions[currentQuestion];

void selectAnswer(String option) {
setState(() {
answers[currentQuestion] = option;
});
}

void previousQuestion() {
if (currentQuestion == 0) return;

setState(() {
currentQuestion--;
});
}

void nextQuestion() {
if (currentQuestion < widget.questions.length - 1) {
setState(() {
currentQuestion++;
});
} else {
finishQuiz();
}
}

void finishQuiz() {
int correct = 0;

answers.forEach((index, selected) {
if (selected == widget.questions[index].answer) {
correct++;
}
});

final attempted =
answers.values.where((e) => e != null).length;

Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) => ResultPage(
score: correct,
totalQuestions: widget.questions.length,
attempted: attempted,
),
),
);
}

Widget buildOption(String option) {
final bool selected =
answers[currentQuestion] == option;

return Padding(
padding: const EdgeInsets.only(bottom: 14),
child: SizedBox(
width: double.infinity,
child: FilledButton(
style: FilledButton.styleFrom(
minimumSize: const Size.fromHeight(60),
backgroundColor: selected
? Colors.deepPurple
: Colors.deepPurple.shade100,
foregroundColor:
selected ? Colors.white : Colors.black87,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
),
onPressed: () => selectAnswer(option),
child: Text(
option,
style: const TextStyle(
fontSize: 16,
),
),
),
),
);
}

@override
Widget build(BuildContext context) {
final progress =
(currentQuestion + 1) / widget.questions.length;

return Scaffold(
appBar: AppBar(
title: Text(
"Question ${currentQuestion + 1}/${widget.questions.length}",
),
),
body: SafeArea(
child: LayoutBuilder(
builder: (context, constraints) {
return SingleChildScrollView(
padding: const EdgeInsets.all(16),
child: ConstrainedBox(
constraints: BoxConstraints(
minHeight: constraints.maxHeight,
),
child: IntrinsicHeight(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [

LinearProgressIndicator(
value: progress,
minHeight: 8,
borderRadius:
BorderRadius.circular(20),
),

const SizedBox(height: 24),

Card(
elevation: 2,
child: Padding(
padding:
const EdgeInsets.all(20),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [

Text(
question.question,
style:
const TextStyle(
fontSize: 24,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 24),

...question.options.map(
buildOption,
),

const SizedBox(height: 20),

const Divider(),

const SizedBox(height: 12),
  Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: currentQuestion == 0
              ? null
              : previousQuestion,
          icon: const Icon(
            Icons.arrow_back,
          ),
          label: const Text(
            "Previous",
          ),
          style:
          OutlinedButton.styleFrom(
            minimumSize:
            const Size.fromHeight(
                56),
          ),
        ),
      ),

      const SizedBox(width: 12),

      Expanded(
        child: FilledButton.icon(
          onPressed: nextQuestion,
          icon: Icon(
            currentQuestion ==
                widget.questions
                    .length -
                    1
                ? Icons.check_circle
                : Icons.arrow_forward,
          ),
          label: Text(
            currentQuestion ==
                widget.questions
                    .length -
                    1
                ? "Finish Quiz"
                : "Next",
          ),
          style:
          FilledButton.styleFrom(
            minimumSize:
            const Size.fromHeight(
                56),
          ),
        ),
      ),
    ],
  ),

  const SizedBox(height: 16),

  Center(
    child: Text(
      answers[currentQuestion] ==
          null
          ? "Not Attempted"
          : "Answer Selected",
      style: TextStyle(
        color:
        answers[currentQuestion] ==
            null
            ? Colors.orange
            : Colors.green,
        fontWeight:
        FontWeight.w600,
      ),
    ),
  ),
],
),
),
),

  const Spacer(),

  Center(
    child: Text(
      "UPSC Practice Mode • You may skip questions",
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 13,
      ),
    ),
  ),

  const SizedBox(height: 10),
],
),
),
),
);
},
),
),
);
}
}