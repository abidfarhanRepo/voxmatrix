import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/domain/entities/crypto.dart';
import 'package:voxmatrix/presentation/crypto/bloc/crypto_bloc.dart';
import 'package:voxmatrix/presentation/crypto/bloc/crypto_event.dart';
import 'package:voxmatrix/presentation/crypto/bloc/crypto_state.dart';

/// Encryption keys management page
class EncryptionKeysPage extends StatefulWidget {
  const EncryptionKeysPage({super.key});

  @override
  State<EncryptionKeysPage> createState() => _EncryptionKeysPageState();
}

class _EncryptionKeysPageState extends State<EncryptionKeysPage> {
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encryption Keys'),
      ),
      body: BlocListener<CryptoBloc, CryptoState>(
        listener: (context, state) {
          if (state is CryptoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is CryptoKeysExported) {
            _showExportedKeysDialog(state.keys);
          } else if (state is CryptoKeysImported) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Keys imported successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: ListView(
          children: [
            _buildSectionHeader('Key Backup'),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('About Key Backup'),
              subtitle: Text(
                'Export your encryption keys to secure them. '
                'Import them to restore access to your encrypted messages.',
              ),
            ),
            const Divider(),
            _buildSectionHeader('Export Keys'),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Encryption Keys'),
              subtitle: const Text(
                'Download your keys as a password-protected file',
              ),
              trailing: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isExporting ? null : _exportKeys,
            ),
            const Divider(),
            _buildSectionHeader('Import Keys'),
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Import Encryption Keys'),
              subtitle: const Text(
                'Restore your keys from a backup file',
              ),
              trailing: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isImporting ? null : _importKeys,
            ),
            const Divider(),
            _buildSectionHeader('Advanced'),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset Encryption'),
              subtitle: const Text(
                'Reset all encryption (requires re-verification)',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showResetDialog,
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Cross-Signing'),
              subtitle: const Text('Manage your cross-signing keys'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showCrossSigningInfo,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacing * 2),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _exportKeys() {
    setState(() {
      _isExporting = true;
    });

    // Show password dialog for export
    showDialog(
      context: context,
      builder: (context) => _PasswordDialog(
        title: 'Export Keys',
        submitLabel: 'Export',
        onSubmit: (password) {
          Navigator.of(context).pop();
          context.read<CryptoBloc>().add(
                ExportKeys(password: password),
              );
          setState(() {
            _isExporting = false;
          });
        },
        onCancel: () {
          setState(() {
            _isExporting = false;
          });
        },
      ),
    );
  }

  void _importKeys() {
    setState(() {
      _isImporting = true;
    });

    // Show import dialog
    showDialog(
      context: context,
      builder: (context) => _ImportKeysDialog(
        onImport: (data, password) {
          Navigator.of(context).pop();
          context.read<CryptoBloc>().add(
                ImportKeys(keyData: data, password: password),
              );
          setState(() {
            _isImporting = false;
          });
        },
        onCancel: () {
          setState(() {
            _isImporting = false;
          });
        },
      ),
    );
  }

  void _showExportedKeysDialog(String keys) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keys Exported'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Your encryption keys have been exported.'),
            const SizedBox(height: 8),
            const Text(
              'Keep this file safe and secure. '
              'Anyone with access to these keys can read your encrypted messages.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Encryption'),
        content: const Text(
          'This will:\n\n'
          '• Delete all your encryption keys\n'
          '• Sign you out of all encrypted rooms\n'
          '• Require you to verify all devices again\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<CryptoBloc>().add(const ResetCrypto());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showCrossSigningInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cross-Signing'),
        content: const Text(
          'Cross-signing allows you to verify your own devices and '
          'have other users trust your verification.\n\n'
          '• Master Key: The main key for your identity\n'
          '• Self-Signing Key: Verifies your own devices\n'
          '• User-Signing Key: Verifies other users\n\n'
          'Keep these keys secure to maintain your trusted identity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Password dialog for key export
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    required this.onCancel,
  });

  final String title;
  final String submitLabel;
  final void Function(String password) onSubmit;
  final VoidCallback onCancel;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final password = _passwordController.text;
            final confirm = _confirmController.text;
            if (password.isEmpty || password != confirm) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Passwords do not match'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }
            widget.onSubmit(password);
          },
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}

/// Import keys dialog
class _ImportKeysDialog extends StatefulWidget {
  const _ImportKeysDialog({
    required this.onImport,
    required this.onCancel,
  });

  final void Function(String data, String password) onImport;
  final VoidCallback onCancel;

  @override
  State<_ImportKeysDialog> createState() => _ImportKeysDialogState();
}

class _ImportKeysDialogState extends State<_ImportKeysDialog> {
  final _dataController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Keys'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _dataController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Key Data',
              border: OutlineInputBorder(),
              hintText: 'Paste your exported keys here',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final data = _dataController.text;
            final password = _passwordController.text;
            if (data.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter key data'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }
            widget.onImport(data, password);
          },
          child: const Text('Import'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _dataController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
