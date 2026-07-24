import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../repositories/api_key_repository.dart';

class ApiKeySetupPage extends StatefulWidget {
  final bool isReplacement;

  const ApiKeySetupPage({
    super.key,
    this.isReplacement = false,
  });

  @override
  State<ApiKeySetupPage> createState() => _ApiKeySetupPageState();
}

class _ApiKeySetupPageState extends State<ApiKeySetupPage>
    with WidgetsBindingObserver {
  final TextEditingController _keyController = TextEditingController();
  final ApiKeyRepository _apiKeyRepository = ApiKeyRepository();
  final FocusNode _keyFocusNode = FocusNode();

  bool _isValidating = false;
  String? _errorMessage;
  bool _isValidated = false;
  bool _showInputField = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isReplacement) {
      _showInputField = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyController.dispose();
    _keyFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted && !_isValidated && !_isValidating) {
        setState(() {
          _showInputField = true;
        });
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted && _keyFocusNode.canRequestFocus) {
            _keyFocusNode.requestFocus();
          }
          _checkClipboardAndPrompt();
        });
      }
    }
  }

  Future<void> _checkClipboardAndPrompt() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null && text.startsWith('AIza') && mounted && !_isValidated) {
        if (_keyController.text.trim() == text) return;
        _showClipboardPasteDialog(text);
      }
    } catch (_) {
      // Ignore clipboard permission errors gracefully
    }
  }

  void _showClipboardPasteDialog(String candidateKey) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Paste Gemini API Key?"),
        content: const Text(
          "We found what looks like a Gemini API Key.\n\nWould you like to paste it?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _keyController.text = candidateKey;
                _showInputField = true;
              });
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && _keyFocusNode.canRequestFocus) {
                  _keyFocusNode.requestFocus();
                }
              });
            },
            child: const Text("Paste"),
          ),
        ],
      ),
    );
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
        title: const Text("Unable to open Google AI Studio."),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Please visit:"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: SelectableText(
                url,
                style: TextStyle(
                  fontFamily: "monospace",
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Close"),
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

  Future<void> _validateAndSave() async {
    final keyInput = _keyController.text.trim();
    if (keyInput.isEmpty) {
      setState(() {
        _errorMessage = "Please enter an API Key.";
        _isValidated = false;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _isValidated = false;
    });

    try {
      final isValid = await _apiKeyRepository.validateKey(keyInput);
      if (isValid) {
        await _apiKeyRepository.saveKey(keyInput);
        if (mounted) {
          setState(() {
            _isValidated = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text("API Key successfully validated and saved!"),
                ],
              ),
            ),
          );
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          _isValidated = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isReplacement ? "Replace API Key" : "Welcome to QuizForge AI",
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Header Section
                  _buildHeroHeader(theme),
                  const SizedBox(height: 20),

                  // Important Trust Message Card
                  _buildTrustCard(theme),
                  const SizedBox(height: 24),

                  // Action Buttons Section
                  _buildActionButtons(theme),
                  const SizedBox(height: 28),

                  // Input Section (revealed on "I Already Have a Key" or resume)
                  _buildInputFieldSection(theme),

                  // Step-by-Step Instructions Guide
                  _buildStepByStepGuide(theme),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 36,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              "Welcome to QuizForge AI",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "QuizForge AI uses Google's Gemini AI to generate intelligent quizzes, explanations, and personalized learning experiences.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:
                  theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "To use these AI features, you'll need a FREE Gemini API Key.\nGetting one takes about 2 minutes.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSecondaryContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "🔒 Privacy & Security",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBulletPoint(
              theme,
              "Your API key stays securely on your device.",
            ),
            _buildBulletPoint(
              theme,
              "QuizForge AI never shares your API key with anyone.",
            ),
            _buildBulletPoint(
              theme,
              "Your key is used only to communicate directly with Google's Gemini API for generating quizzes.",
            ),
            _buildBulletPoint(
              theme,
              "You can replace or remove your API key at any time from Settings.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: "Get Free Gemini API Key",
          hint: "Opens Google AI Studio page in default browser",
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _launchApiKeyStudio,
              icon: const Icon(Icons.open_in_new, size: 20),
              label: const Text(
                "Get Free Gemini API Key",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!_showInputField)
          Semantics(
            button: true,
            label: "I Already Have a Key",
            hint: "Shows text field to enter Gemini API Key",
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.primary,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _showInputField = true;
                  });
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted && _keyFocusNode.canRequestFocus) {
                      _keyFocusNode.requestFocus();
                    }
                  });
                },
                child: Text(
                  "I Already Have a Key",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputFieldSection(ThemeData theme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _showInputField
          ? Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _errorMessage != null
                        ? theme.colorScheme.error
                        : theme.colorScheme.outlineVariant,
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
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Enter Gemini API Key",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _keyController,
                        focusNode: _keyFocusNode,
                        obscureText: _obscureText,
                        autocorrect: false,
                        enableSuggestions: false,
                        style: const TextStyle(
                          fontFamily: "monospace",
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: "AIzaSy...",
                          prefixIcon: const Icon(Icons.vpn_key_outlined),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                                tooltip: _obscureText
                                    ? "Show API Key"
                                    : "Hide API Key",
                              ),
                              if (_isValidated)
                                const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _errorMessage != null
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.outline,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _errorMessage != null
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_isValidating)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text("Validating API Key with Gemini..."),
                            ],
                          ),
                        ),
                      if (_isValidated)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.check, color: Colors.green),
                              SizedBox(width: 12),
                              Text(
                                "✓ Connected",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Semantics(
                        button: true,
                        label: "Validate and Save API Key",
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _isValidating ? null : _validateAndSave,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isValidating
                                  ? "Validating..."
                                  : "Validate & Save",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildStepByStepGuide(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "How to Get Your Free API Key",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "⏱ Takes less than 2 minutes.",
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStepRow(theme, "1", 'Tap "Get Free Gemini API Key"'),
            _buildArrow(theme),
            _buildStepRow(theme, "2", "Sign in using your Google Account."),
            _buildArrow(theme),
            _buildStepRow(theme, "3", "Click Create API Key"),
            _buildArrow(theme),
            _buildStepRow(theme, "4", "Copy the generated API key."),
            _buildArrow(theme),
            _buildStepRow(theme, "5", "Return to QuizForge AI."),
            _buildArrow(theme),
            _buildStepRow(theme, "6", "Paste your API key."),
            _buildArrow(theme),
            _buildStepRow(theme, "7", "Tap Validate & Save"),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(ThemeData theme, String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            number,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArrow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      child: Text(
        "↓",
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
