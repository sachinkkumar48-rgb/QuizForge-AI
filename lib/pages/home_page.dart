import 'package:flutter/material.dart';

import '../services/pdf_service.dart';
import '../services/pdf_reader_service.dart';
import '../controllers/quiz_controller.dart';
import 'quiz_page.dart';
import '../models/quiz_model.dart';
import 'pdf_view_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedPdf;

  Future<void> importPdf() async {
    final path = await PdfService.pickPdf();

    if (path == null) return;

    setState(() {
      selectedPdf = path;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reading PDF..."),
      ),
    );

    final text = await PdfReaderService.readPdf(path);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewPage(text: text),
      ),
    );
  }

  Widget menuButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QuizForge AI"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.quiz,
                size: 100,
                color: Colors.deepPurple,
              ),

              const SizedBox(height: 20),

              const Text(
                "AI Powered UPSC Quiz Generator",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Generate quizzes from your UPSC PDFs using AI.",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 25),

              if (selectedPdf != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      selectedPdf!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),

              const SizedBox(height: 25),

              menuButton(
                title: "Import PDF",
                icon: Icons.picture_as_pdf,
                color: Colors.red,
                onTap: importPdf,
              ),

              const SizedBox(height: 15),

              menuButton(
                title: "Generate AI Quiz",
                icon: Icons.smart_toy,
                color: Colors.deepPurple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "AI integration will be added next.",
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              menuButton(
                title: "Previous Quizzes",
                icon: Icons.history,
                color: Colors.blue,
                onTap: () {},
              ),

              const SizedBox(height: 15),

              menuButton(
                title: "Settings",
                icon: Icons.settings,
                color: Colors.green,
                onTap: () {},
              ),

              const SizedBox(height: 30),

              const Center(
                child: Text(
                  "QuizForge AI v1.0",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}