import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../repositories/api_key_repository.dart';
import 'api_key_setup_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiKeyRepository _apiKeyRepository = ApiKeyRepository();

  bool _isLoading = true;
  bool _hasKey = false;
  String _maskedKey = "";
  String _connectionStatus = "Checking...";
  bool _isConnectionValid = false;
  bool _isValidating = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    final hasKey = await _apiKeyRepository.hasKey();
    if (hasKey) {
      final key = await _apiKeyRepository.loadKey();
      if (key != null && key.length > 6) {
        _maskedKey = "AIzaSy${"*" * (key.length - 6)}";
      } else {
        _maskedKey = "AIzaSy****************";
      }
      _hasKey = true;
      _connectionStatus = "Configured (Click 'Revalidate' to test connection)";
      _isConnectionValid = false;
    } else {
      _hasKey = false;
      _maskedKey = "Not configured";
      _connectionStatus = "Not Configured";
      _isConnectionValid = false;
    }

    setState(() {
      _isLoading = false;
      _validationError = null;
    });
  }

  Future<void> _revalidateKey() async {
    final key = await _apiKeyRepository.loadKey();
    if (key == null) return;

    setState(() {
      _isValidating = true;
      _validationError = null;
      _connectionStatus = "Validating...";
    });

    try {
      final isValid = await _apiKeyRepository.validateKey(key);
      if (isValid) {
        setState(() {
          _isConnectionValid = true;
          _connectionStatus = "✓ Connected";
        });
      }
    } catch (e) {
      setState(() {
        _isConnectionValid = false;
        _validationError = e.toString().replaceAll("Exception: ", "");
        _connectionStatus = "Connection Failed";
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  Future<void> _deleteKey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Remove API Key?"),
        content: const Text(
          "This will delete your Gemini API key from this device. You will not be able to generate new quizzes until you configure a new key.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiKeyRepository.deleteKey();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("API Key removed successfully.")),
        );
      }
      _loadSettings();
    }
  }

  Future<void> _replaceKey() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ApiKeySetupPage(isReplacement: true),
      ),
    );

    if (result == true) {
      _loadSettings();
      _revalidateKey();
    }
  }

  Future<void> _launchApiKeyStudio() async {
    const urlString = "https://aistudio.google.com/app/apikey";
    final url = Uri.parse(urlString);

    try {
      final success = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!success) {
        _showLaunchFailureDialog(urlString);
      }
    } catch (e) {
      _showLaunchFailureDialog(urlString);
    }
  }

  void _showLaunchFailureDialog(String url) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Browser Launch Failed"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Unable to open Google AI Studio in your browser.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text("Please copy and visit the URL manually:"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(fontFamily: "monospace", fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text("Copy Link"),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Link copied to clipboard!")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Gemini Integration",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // API Key Status Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.key,
                                color: _hasKey
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Gemini API Key",
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _maskedKey,
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        fontFamily: "monospace",
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          Row(
                            children: [
                              Icon(
                                _getConnectionIcon(),
                                color: _getConnectionColor(),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Connection Status",
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _connectionStatus,
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _getConnectionColor(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_validationError != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                _validationError!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Actions Section
                  Text(
                    "Actions",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_hasKey) ...[
                    // Get Free Key Button
                    _buildActionButton(
                      context,
                      icon: Icons.open_in_new,
                      title: "Get Free Gemini API Key",
                      subtitle: "Create a free key in Google AI Studio",
                      onTap: _isValidating ? null : _launchApiKeyStudio,
                    ),
                    const SizedBox(height: 12),

                    // Revalidate Button
                    _buildActionButton(
                      context,
                      icon: Icons.refresh,
                      title: "Revalidate API Key",
                      subtitle:
                          "Check if the key is active and connection works",
                      onTap: _isValidating ? null : _revalidateKey,
                      trailing: _isValidating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Replace Button
                    _buildActionButton(
                      context,
                      icon: Icons.edit_note,
                      title: "Replace API Key",
                      subtitle: "Configure a different Gemini API Key",
                      onTap: _isValidating ? null : _replaceKey,
                    ),
                    const SizedBox(height: 12),

                    // Remove Button
                    _buildActionButton(
                      context,
                      icon: Icons.delete_outline,
                      title: "Remove API Key",
                      subtitle: "Delete key securely from this device",
                      onTap: _isValidating ? null : _deleteKey,
                      destructive: true,
                    ),
                  ] else ...[
                    // Get Free Key Button
                    _buildActionButton(
                      context,
                      icon: Icons.open_in_new,
                      title: "Get Free Gemini API Key",
                      subtitle: "Create a free key in Google AI Studio",
                      onTap: _launchApiKeyStudio,
                    ),
                    const SizedBox(height: 12),

                    // Setup Button
                    _buildActionButton(
                      context,
                      icon: Icons.add_link,
                      title: "Set Gemini API Key",
                      subtitle:
                          "Configure your API Key to start generating quizzes",
                      onTap: _replaceKey,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
    bool destructive = false,
  }) {
    final theme = Theme.of(context);
    final color = destructive ? Colors.red : theme.colorScheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: destructive
              ? Colors.red.withValues(alpha: 0.25)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: destructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }

  IconData _getConnectionIcon() {
    if (!_hasKey) return Icons.link_off;
    if (_isValidating) return Icons.sync;
    if (_isConnectionValid) return Icons.check_circle;
    if (_validationError != null) return Icons.error;
    return Icons.help_outline;
  }

  Color _getConnectionColor() {
    if (!_hasKey) return Colors.orange;
    if (_isValidating) return Colors.blue;
    if (_isConnectionValid) return Colors.green;
    if (_validationError != null) return Colors.red;
    return Colors.grey;
  }
}
