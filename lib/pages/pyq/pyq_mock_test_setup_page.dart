import 'package:flutter/material.dart';

import '../../controllers/pyq_controller.dart';
import 'pyq_attempt_page.dart';

class PyqMockTestSetupPage extends StatefulWidget {
  const PyqMockTestSetupPage({super.key});

  @override
  State<PyqMockTestSetupPage> createState() => _PyqMockTestSetupPageState();
}

class _PyqMockTestSetupPageState extends State<PyqMockTestSetupPage> {
  final PyqController pyqController = PyqController();

  String? selectedSubject;
  int testSize = 25;
  bool isCreating = false;

  final List<String> subjects = [
    "All Subjects",
    "Polity",
    "History",
    "Economy",
    "Geography",
    "Environment",
    "Science & Technology",
  ];

  void _startPresetMock(int count, String? subject, String title) async {
    setState(() {
      isCreating = true;
    });

    final questions = await pyqController.generateMockTest(
      count: count,
      subject: (subject == null || subject == "All Subjects") ? null : subject,
    );

    if (!mounted) return;

    setState(() {
      isCreating = false;
    });

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Not enough questions found for this test preset."),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PyqAttemptPage(
          questions: questions,
          title: title,
          isExamMode: true,
        ),
      ),
    );
  }

  Widget _buildPresetCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      color: color.withValues(alpha: 0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing:
            const Icon(Icons.play_circle_filled, color: Colors.deepPurple),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PYQ Mock Tests"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quick Presets",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPresetCard(
              title: "25 Random PYQs",
              subtitle: "Quick 25-question mixed paper test",
              icon: Icons.shuffle,
              color: Colors.blue,
              onTap: () =>
                  _startPresetMock(25, null, "25 Random PYQs Mock Test"),
            ),
            _buildPresetCard(
              title: "50 Polity PYQs",
              subtitle: "Focused test on Indian Polity & Constitution",
              icon: Icons.gavel,
              color: Colors.deepPurple,
              onTap: () =>
                  _startPresetMock(50, "Polity", "50 Polity PYQs Mock Test"),
            ),
            _buildPresetCard(
              title: "100 Mixed PYQs (Full Length)",
              subtitle: "Full-length UPSC CSE Prelims style paper",
              icon: Icons.assignment,
              color: Colors.indigo,
              onTap: () =>
                  _startPresetMock(100, null, "100 Mixed PYQs Mock Test"),
            ),
            _buildPresetCard(
              title: "Environment & Ecology PYQs",
              subtitle: "Dedicated environment & biodiversity test",
              icon: Icons.eco,
              color: Colors.green,
              onTap: () => _startPresetMock(
                  25, "Environment", "Environment PYQs Mock Test"),
            ),
            _buildPresetCard(
              title: "Economy & Banking PYQs",
              subtitle: "Macroeconomics & monetary policy test",
              icon: Icons.account_balance,
              color: Colors.teal,
              onTap: () =>
                  _startPresetMock(25, "Economy", "Economy PYQs Mock Test"),
            ),
            const SizedBox(height: 24),
            const Text(
              "Custom Test Builder",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedSubject ?? "All Subjects",
              decoration: const InputDecoration(
                labelText: "Subject Filter",
                border: OutlineInputBorder(),
              ),
              items: subjects.map((sub) {
                return DropdownMenuItem(value: sub, child: Text(sub));
              }).toList(),
              onChanged: (val) {
                setState(() => selectedSubject = val);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              "Number of Questions",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [10, 25, 50, 100].map((count) {
                final isSelected = testSize == count;
                return ChoiceChip(
                  label: Text("$count Questions"),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => testSize = count);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: isCreating
                    ? null
                    : () => _startPresetMock(
                          testSize,
                          selectedSubject,
                          "Custom Mock Test ($testSize Qs)",
                        ),
                icon: isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rocket_launch),
                label: Text(
                  isCreating ? "Generating Test..." : "Launch Custom Mock Test",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
