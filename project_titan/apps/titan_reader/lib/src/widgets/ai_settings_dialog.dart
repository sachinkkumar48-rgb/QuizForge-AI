library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/ai_reading_models.dart';
import '../providers/ai_reading_providers.dart';

/// Settings dialog for configuring AI Provider, Model, and Endpoint parameters.
class AISettingsDialog extends ConsumerStatefulWidget {
  const AISettingsDialog({super.key});

  @override
  ConsumerState<AISettingsDialog> createState() => _AISettingsDialogState();
}

class _AISettingsDialogState extends ConsumerState<AISettingsDialog> {
  late AIProviderType _providerType;
  late TextEditingController _modelController;
  late TextEditingController _ollamaUrlController;
  late TextEditingController _openAIUrlController;
  late TextEditingController _openAIKeyController;
  late TextEditingController _geminiKeyController;
  late double _temperature;
  late int _maxTokens;
  late bool _localFirst;

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiConfigStateProvider);
    _providerType = config.providerType;
    _modelController = TextEditingController(text: config.activeModelId);
    _ollamaUrlController = TextEditingController(text: config.ollamaBaseUrl);
    _openAIUrlController = TextEditingController(text: config.openAIBaseUrl);
    _openAIKeyController =
        TextEditingController(text: config.openAIApiKey ?? '');
    _geminiKeyController =
        TextEditingController(text: config.geminiApiKey ?? '');
    _temperature = config.temperature;
    _maxTokens = config.maxTokens;
    _localFirst = config.localFirst;
  }

  @override
  void dispose() {
    _modelController.dispose();
    _ollamaUrlController.dispose();
    _openAIUrlController.dispose();
    _openAIKeyController.dispose();
    _geminiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = AIConfig(
      providerType: _providerType,
      activeModelId: _modelController.text.trim().isEmpty
          ? 'default'
          : _modelController.text.trim(),
      ollamaBaseUrl: _ollamaUrlController.text.trim(),
      openAIBaseUrl: _openAIUrlController.text.trim(),
      openAIApiKey: _openAIKeyController.text.trim().isEmpty
          ? null
          : _openAIKeyController.text.trim(),
      geminiApiKey: _geminiKeyController.text.trim().isEmpty
          ? null
          : _geminiKeyController.text.trim(),
      localFirst: _localFirst,
      temperature: _temperature,
      maxTokens: _maxTokens,
    );

    await ref.read(aiConfigStateProvider.notifier).update(updated);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableModelsAsync = ref.watch(aiAvailableModelsProvider);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.psychology_outlined),
          SizedBox(width: 8),
          Text('AI Assistant Settings'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Provider', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<AIProviderType>(
                key: const Key('ai-settings-provider-dropdown'),
                initialValue: _providerType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: AIProviderType.localOllama,
                    child: Text('Local Ollama (Offline / Native)'),
                  ),
                  DropdownMenuItem(
                    value: AIProviderType.openAICompatible,
                    child: Text('OpenAI-Compatible Server'),
                  ),
                  DropdownMenuItem(
                    value: AIProviderType.gemini,
                    child: Text('Google Gemini API'),
                  ),
                  DropdownMenuItem(
                    value: AIProviderType.mock,
                    child: Text('Mock Provider (Offline Testing)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _providerType = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text('Model Name', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              availableModelsAsync.when(
                data: (models) {
                  return Column(
                    children: [
                      TextFormField(
                        key: const Key('ai-settings-model-input'),
                        controller: _modelController,
                        decoration: InputDecoration(
                          hintText: 'e.g. llama3.2, mistral, gpt-4o-mini',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: models.isNotEmpty
                              ? PopupMenuButton<String>(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onSelected: (m) =>
                                      setState(() => _modelController.text = m),
                                  itemBuilder: (context) => models
                                      .map((m) => PopupMenuItem(
                                          value: m.id,
                                          child: Text(m.displayName)))
                                      .toList(),
                                )
                              : null,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), isDense: true),
                ),
              ),
              const SizedBox(height: 16),
              if (_providerType == AIProviderType.localOllama) ...[
                Text('Ollama Base URL', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ollamaUrlController,
                  decoration: const InputDecoration(
                    hintText: 'http://127.0.0.1:11434',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ] else if (_providerType == AIProviderType.openAICompatible) ...[
                Text('OpenAI Endpoint URL', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _openAIUrlController,
                  decoration: const InputDecoration(
                    hintText: 'http://127.0.0.1:1234/v1',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Text('API Key (Optional for local servers)',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _openAIKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ] else if (_providerType == AIProviderType.gemini) ...[
                Text('Gemini API Key', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _geminiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    key: const Key('ai-settings-local-first-checkbox'),
                    value: _localFirst,
                    onChanged: (val) =>
                        setState(() => _localFirst = val ?? true),
                  ),
                  const Expanded(
                    child: Text(
                        'Prefer Local AI (Zero transmission for local models)'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Temperature: ${_temperature.toStringAsFixed(1)}',
                      style: theme.textTheme.bodyMedium),
                  Expanded(
                    child: Slider(
                      value: _temperature,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (val) => setState(() => _temperature = val),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('ai-settings-save-button'),
          onPressed: _save,
          child: const Text('Save Settings'),
        ),
      ],
    );
  }
}

void showAISettingsDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => const AISettingsDialog(),
  );
}
