import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../controllers/quiz_controller.dart';
import '../core/di/service_locator_init.dart';
import '../plugins/plugins.dart';
import '../repositories/api_key_repository.dart';
import '../repositories/quiz_session_repository.dart';
import '../services/pdf_service.dart';
import '../widgets/loading_dialog.dart';
import 'api_key_setup_page.dart';
import 'history_page.dart';
import 'library_page.dart';
import 'module_explorer_page.dart';
import 'pyq/pyq_dashboard_page.dart';
import 'quiz_page.dart';
import 'quizforge_dashboard_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PlatformFile? selectedPdf;

  bool isGenerating = false;
  int selectedQuestionCount = 10;

  late final QuizController quizController;

  @override
  void initState() {
    super.initState();
    quizController = locate<QuizController>();
    _initPlugins();
    _checkActiveSession();
  }

  Future<void> _initPlugins() async {
    final registry = PluginRegistry();
    if (registry.registeredModules.isEmpty) {
      await registry.registerModule(UpscModule());
      await registry.registerModule(BpscModule());
      await registry.registerModule(SscModule());
      await registry.registerModule(EpfoModule());
      await registry.registerModule(NdaModule());
      await registry.registerModule(CdsModule());
      await registry.registerModule(CapfModule());
      await registry.registerModule(CurrentAffairsModule());
      await registry.registerModule(VocabularyModule());
      await registry.registerModule(EssayModule());
    }
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
                      content: Text("Previous quiz session discarded."),
                    ),
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

      final errorMsg = e.toString().replaceAll("Exception: ", "");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
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

    final hasKey = await ApiKeyRepository().hasKey();
    if (!hasKey) {
      if (!mounted) return;
      final setupSuccess = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const ApiKeySetupPage(),
        ),
      );
      if (setupSuccess != true) {
        return;
      }
      if (!mounted) return;
    }

    if (!mounted) return;

    setState(() {
      isGenerating = true;
    });

    LoadingDialog.show(
      context,
      message: "Generating Questions...\nInitializing...",
    );

    try {
      final quizModel = await quizController.generateQuiz(
        selectedPdf!,
        questionCount: selectedQuestionCount,
        onProgress: (msg) {
          LoadingDialog.updateMessage(msg);
        },
      );

      if (!mounted) return;

      LoadingDialog.hide(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizPage(
            questions: quizModel.questions,
            sourceName: selectedPdf!.name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      LoadingDialog.hide(context);

      final state = quizController.state;
      final errorMsg =
          state.message ?? e.toString().replaceAll("Exception: ", "");
      final isApiKeyError = state.isApiKeyError;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          action: isApiKeyError
              ? SnackBarAction(
                  label: "Settings",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsPage(),
                      ),
                    );
                  },
                )
              : null,
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
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.withValues(alpha: 0.1),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 15,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
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
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined),
            tooltip: "Dashboard",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QuizForgeDashboardPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 70,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 16),
            const Text(
              "Smart Quiz Generator",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
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
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Number of Questions:",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [10, 25, 50, 100, 150].map((count) {
                final isSelected = selectedQuestionCount == count;
                return ChoiceChip(
                  label: Text("$count Questions"),
                  selected: isSelected,
                  onSelected: isGenerating
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() {
                              selectedQuestionCount = count;
                            });
                          }
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
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
                  isGenerating
                      ? "Generating..."
                      : "Generate $selectedQuestionCount AI Questions",
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LibraryPage(),
                  ),
                );
              },
              icon: const Icon(Icons.folder_open),
              label: const Text("Choose from PDF Library"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Main UPSC PYQ Feature Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(
                  color: Colors.deepPurple.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              color: Colors.deepPurple.withValues(alpha: 0.05),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PyqDashboardPage(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            Colors.deepPurple.withValues(alpha: 0.15),
                        child: const Icon(
                          Icons.history_edu,
                          size: 32,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "UPSC PYQ",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Official Previous Year Questions",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.deepPurple,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                buildActionCard(
                  icon: Icons.extension,
                  title: "Plugin Hub",
                  subtitle:
                      "${PluginRegistry().enabledModules.length} Modules Active",
                  color: Colors.deepPurple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ModuleExplorerPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
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
                const SizedBox(width: 12),
                buildActionCard(
                  icon: Icons.library_books,
                  title: "PDF Library",
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LibraryPage(),
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
