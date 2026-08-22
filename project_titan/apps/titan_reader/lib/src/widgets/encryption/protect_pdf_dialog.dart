import 'package:flutter/material.dart';

import '../../domain/entities/pdf_encryption_options.dart';

/// Interactive dialog for configuring PDF password protection and encryption settings.
class ProtectPdfDialog extends StatefulWidget {
  final String documentTitle;

  const ProtectPdfDialog({
    super.key,
    required this.documentTitle,
  });

  @override
  State<ProtectPdfDialog> createState() => _ProtectPdfDialogState();
}

class _ProtectPdfDialogState extends State<ProtectPdfDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ownerPasswordController = TextEditingController();

  bool _obscureUserPassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureOwnerPassword = true;

  bool _enableOwnerPassword = false;
  PdfEncryptionAlgorithm _selectedAlgorithm = PdfEncryptionAlgorithm.aes128;

  // Permissions state
  bool _allowPrinting = true;
  bool _allowModifying = false;
  bool _allowCopying = false;
  bool _allowAnnotating = true;
  bool _allowFormFilling = true;

  @override
  void dispose() {
    _userPasswordController.dispose();
    _confirmPasswordController.dispose();
    _ownerPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final config = PdfEncryptionConfig(
      userPassword: _userPasswordController.text,
      ownerPassword:
          _enableOwnerPassword && _ownerPasswordController.text.isNotEmpty
              ? _ownerPasswordController.text
              : null,
      algorithm: _selectedAlgorithm,
      permissions: PdfPermissions(
        allowPrinting: _allowPrinting,
        allowModifying: _allowModifying,
        allowCopying: _allowCopying,
        allowAnnotating: _allowAnnotating,
        allowFormFilling: _allowFormFilling,
        allowAccessibilityExtraction: true,
        allowAssembly: _allowModifying,
        allowHighQualityPrinting: _allowPrinting,
      ),
    );

    Navigator.of(context).pop(config);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Protect PDF with Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.documentTitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const Key('encrypt-user-password-field'),
                          controller: _userPasswordController,
                          obscureText: _obscureUserPassword,
                          decoration: InputDecoration(
                            labelText: 'Open / User Password',
                            hintText: 'Password required to open this PDF',
                            prefixIcon: const Icon(Icons.key),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureUserPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(() =>
                                  _obscureUserPassword = !_obscureUserPassword),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value == null || value.isEmpty) &&
                                (!_enableOwnerPassword ||
                                    _ownerPasswordController.text.isEmpty)) {
                              return 'Please enter an open password or owner password.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('encrypt-confirm-password-field'),
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm Open Password',
                            prefixIcon: const Icon(Icons.check_circle_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_userPasswordController.text.isNotEmpty &&
                                value != _userPasswordController.text) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          key: const Key('encrypt-enable-owner-password'),
                          title: const Text('Set permissions & owner password'),
                          subtitle: const Text(
                              'Restrict editing, copying, and printing permissions'),
                          value: _enableOwnerPassword,
                          onChanged: (val) => setState(
                              () => _enableOwnerPassword = val ?? false),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        if (_enableOwnerPassword) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('encrypt-owner-password-field'),
                            controller: _ownerPasswordController,
                            obscureText: _obscureOwnerPassword,
                            decoration: InputDecoration(
                              labelText: 'Permissions / Owner Password',
                              hintText:
                                  'Password required to change permissions',
                              prefixIcon: const Icon(
                                  Icons.admin_panel_settings_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureOwnerPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () => setState(() =>
                                    _obscureOwnerPassword =
                                        !_obscureOwnerPassword),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_enableOwnerPassword &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter an owner password.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Allowed Permissions for Open Password users:',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          CheckboxListTile(
                            title: const Text('Allow Printing'),
                            value: _allowPrinting,
                            onChanged: (v) =>
                                setState(() => _allowPrinting = v ?? false),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          CheckboxListTile(
                            title:
                                const Text('Allow Copying & Text Extraction'),
                            value: _allowCopying,
                            onChanged: (v) =>
                                setState(() => _allowCopying = v ?? false),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          CheckboxListTile(
                            title:
                                const Text('Allow Modifying Content & Pages'),
                            value: _allowModifying,
                            onChanged: (v) =>
                                setState(() => _allowModifying = v ?? false),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          CheckboxListTile(
                            title: const Text('Allow Annotating & Comments'),
                            value: _allowAnnotating,
                            onChanged: (v) =>
                                setState(() => _allowAnnotating = v ?? false),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          CheckboxListTile(
                            title: const Text('Allow Form Filling & Signing'),
                            value: _allowFormFilling,
                            onChanged: (v) =>
                                setState(() => _allowFormFilling = v ?? false),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                        const SizedBox(height: 12),
                        DropdownButtonFormField<PdfEncryptionAlgorithm>(
                          key: const Key('encrypt-algorithm-selector'),
                          initialValue: _selectedAlgorithm,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Encryption Standard',
                            prefixIcon: Icon(Icons.shield_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: PdfEncryptionAlgorithm.aes128,
                              child: Text(
                                'AES-128 (Revision 4 - Recommended)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: PdfEncryptionAlgorithm.rc4_128,
                              child: Text(
                                'RC4-128 (Revision 3 - Compatible)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedAlgorithm = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      key: const Key('encrypt-cancel-button'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      key: const Key('encrypt-confirm-button'),
                      onPressed: _submit,
                      icon: const Icon(Icons.lock, size: 18),
                      label: const Text('Protect & Encrypt'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
