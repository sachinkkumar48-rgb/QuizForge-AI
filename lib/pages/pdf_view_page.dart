import 'package:flutter/material.dart';

class PdfViewPage extends StatelessWidget {
  final String text;

  const PdfViewPage({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Extracted PDF Text"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: SelectableText(text),
        ),
      ),
    );
  }
}