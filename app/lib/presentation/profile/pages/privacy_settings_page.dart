import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/presentation/profile/bloc/profile_bloc.dart';
import 'package:voxmatrix/presentation/profile/bloc/profile_event.dart';

/// Privacy and security settings page
class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _showReadReceipts = true;
  bool _sendTypingNotifications = true;
  bool _enablePresence = true;
  bool _allowOnlineStatus = true;
  bool _requireEncryption = true;
  bool _ignoreUnknownRequests = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Read Receipts'),
          SwitchListTile(
            title: const Text('Send Read Receipts'),
            subtitle: const Text('Let others know when you\'ve read messages'),
            value: _showReadReceipts,
            onChanged: (value) {
              setState(() {
                _showReadReceipts = value;
              });
              _savePrivacySettings();
            },
          ),
          const Divider(),
          _buildSectionHeader('Typing Indicators'),
          SwitchListTile(
            title: const Text('Send Typing Notifications'),
            subtitle: const Text('Let others see when you\'re typing'),
            value: _sendTypingNotifications,
            onChanged: (value) {
              setState(() {
                _sendTypingNotifications = value;
              });
              _savePrivacySettings();
            },
          ),
          const Divider(),
          _buildSectionHeader('Presence'),
          SwitchListTile(
            title: const Text('Enable Presence'),
            subtitle: const Text('Share your online status'),
            value: _enablePresence,
            onChanged: (value) {
              setState(() {
                _enablePresence = value;
              });
              _savePrivacySettings();
            },
          ),
          SwitchListTile(
            title: const Text('Show Online Status'),
            subtitle: const Text('Let others see when you\'re online'),
            value: _allowOnlineStatus,
            onChanged: (value) {
              setState(() {
                _allowOnlineStatus = value;
              });
              _savePrivacySettings();
            },
          ),
          const Divider(),
          _buildSectionHeader('Encryption'),
          SwitchListTile(
            title: const Text('Require Encryption'),
            subtitle: const Text('Automatically enable E2EE in new rooms'),
            value: _requireEncryption,
            onChanged: (value) {
              setState(() {
                _requireEncryption = value;
              });
              _savePrivacySettings();
            },
          ),
          ListTile(
            title: const Text('Encryption Algorithm'),
            subtitle: const Text('m.megolm.v1.aes-sha2'),
            trailing: const Icon(Icons.lock, color: Colors.green),
            onTap: () {
              _showEncryptionInfo();
            },
          ),
          const Divider(),
          _buildSectionHeader('Direct Messages'),
          SwitchListTile(
            title: const Text('Ignore Unknown Requests'),
            subtitle: const Text('Hide messages from people you haven\'t chatted with'),
            value: _ignoreUnknownRequests,
            onChanged: (value) {
              setState(() {
                _ignoreUnknownRequests = value;
              });
              _savePrivacySettings();
            },
          ),
          const Divider(),
          _buildSectionHeader('Blocked Users'),
          ListTile(
            title: const Text('Blocked Users'),
            subtitle: const Text('Manage users you\'ve blocked'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showBlockedUsers();
            },
          ),
          const Divider(),
          _buildSectionHeader('Account Data'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text('Delete Account'),
            subtitle: const Text('Permanently delete your account'),
            onTap: () {
              _showDeleteAccountDialog();
            },
          ),
          const SizedBox(height: 32),
        ],
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

  void _savePrivacySettings() {
    context.read<ProfileBloc>().add(UpdatePrivacySettings(
          showReadReceipts: _showReadReceipts,
          sendTypingNotifications: _sendTypingNotifications,
          enablePresence: _enablePresence,
          allowOnlineStatus: _allowOnlineStatus,
          requireEncryption: _requireEncryption,
          ignoreUnknownRequests: _ignoreUnknownRequests,
        ));
  }

  void _showEncryptionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encryption'),
        content: const Text(
          'VoxMatrix uses the Matrix protocol\'s end-to-end encryption.\n\n'
          'Algorithm: m.megolm.v1.aes-sha2\n\n'
          'Messages are encrypted on your device and can only be decrypted '
          'by the intended recipients. Not even the server can read your messages.',
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

  void _showBlockedUsers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blocked Users'),
        content: const Text(
          'Manage users you\'ve blocked. Blocked users cannot send you '
          'messages or see your online status.',
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. Deleting your account will:\n\n'
          '• Remove all your messages from the server\n'
          '• Leave all rooms\n'
          '• Delete your encryption keys\n'
          '• Deactivate your account\n\n'
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
              // Handle account deletion
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
