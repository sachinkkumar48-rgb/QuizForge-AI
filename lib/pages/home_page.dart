import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../controllers/quiz_controller.dart';
import '../repositories/quiz_session_repository.dart';
import '../services/pdf_service.dart';
import '../widgets/loading_dialog.dart';
import 'quiz_page.dart';
import 'history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PlatformFile? selectedPdf;

  bool isGenerating = false;

  final QuizController quizController = QuizController();

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final hasSession = await QuizSessionRepository().hasActiveSession();
    if (hasSession && mounted) {
      _showResumeDialog();
    }
  }

  Future<void> _showResumeDialog() async {
    final sessionRepo = QuizSessionRepository();
    final session = await sessionRepo.loadSession();
    if (session == null || !mounted) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text("Resume Previous Quiz?"),
          content: const Text("An unfinished quiz was found."),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await sessionRepo.deleteSession();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Previous quiz session discarded.")),
                  );
                }
              },
              child: const Text("Discard"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizPage(
                      questions: session.quizQuestions,
                      sourceName: session.sourceName,
                      restoredSession: session,
                    ),
                  ),
                );
              },
              child: const Text("Resume"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> importPdf() async {
    try {
      final pdf = await PdfService.pickPdf();

      if (pdf == null) return;

      setState(() {
        selectedPdf = pdf;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "${pdf.name} selected successfully.",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> generateQuiz() async {
    if (selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a PDF first.",
          ),
        ),
      );
      return;
    }

    setState(() {
      isGenerating = true;
    });

    LoadingDialog.show(
      context,
      message: "Reading PDF and generating UPSC quiz...",
    );

    try {
      final questions = await quizController.generateQuiz(
        selectedPdf!,
      );

      if (!mounted) return;

      LoadingDialog.hide(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizPage(
            questions: questions,
            sourceName: selectedPdf!.name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      LoadingDialog.hide(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  Widget buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 30,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPdf = selectedPdf != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("QuizForge AI"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Icon(
              Icons.auto_awesome,
              size: 90,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            const Text(
              "AI Powered UPSC Quiz Generator",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Import a PDF and generate UPSC Prelims questions using Gemini AI.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: importPdf,
              child: Ink(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasPdf ? Colors.green : Colors.deepPurple,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          hasPdf ? Colors.green.shade50 : Colors.red.shade50,
                      child: Icon(
                        Icons.picture_as_pdf,
                        size: 30,
                        color: hasPdf ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasPdf ? "Selected PDF" : "Select PDF",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasPdf
                                ? selectedPdf!.name
                                : "Tap here to choose a PDF",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      hasPdf ? Icons.check_circle : Icons.upload_file,
                      color: hasPdf ? Colors.green : Colors.deepPurple,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton.icon(
                onPressed: isGenerating ? null : generateQuiz,
                icon: isGenerating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.smart_toy),
                label: Text(
                  isGenerating ? "Generating..." : "Generate AI Quiz",
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                buildActionCard(
                  icon: Icons.history,
                  title: "History",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HistoryPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                buildActionCard(
                  icon: Icons.settings,
                  title: "Settings",
                  color: Colors.green,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Settings feature coming soon.",
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              "QuizForge AI v0.5 Alpha",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
