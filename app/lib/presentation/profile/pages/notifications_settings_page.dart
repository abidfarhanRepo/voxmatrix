import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/presentation/profile/bloc/profile_bloc.dart';
import 'package:voxmatrix/presentation/profile/bloc/profile_event.dart';

/// Notifications settings page
class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _enableNotifications = true;
  bool _enableSound = true;
  bool _enableVibrate = true;
  bool _notifyForAllMessages = false;
  bool _notifyForMentionsOnly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('General'),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Allow push notifications'),
            value: _enableNotifications,
            onChanged: (value) {
              setState(() {
                _enableNotifications = value;
              });
              _saveNotificationSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Play sound for notifications'),
            value: _enableSound,
            onChanged: (value) {
              setState(() {
                _enableSound = value;
              });
              _saveNotificationSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Vibrate'),
            subtitle: const Text('Vibrate on notification'),
            value: _enableVibrate,
            onChanged: (value) {
              setState(() {
                _enableVibrate = value;
              });
              _saveNotificationSettings();
            },
          ),
          const Divider(),
          _buildSectionHeader('Message Notifications'),
          RadioListTile<bool>(
            title: const Text('All Messages'),
            subtitle: const Text('Notify for all new messages'),
            value: true,
            groupValue: _notifyForAllMessages,
            onChanged: (value) {
              setState(() {
                _notifyForAllMessages = value!;
                _notifyForMentionsOnly = !value;
              });
              _saveNotificationSettings();
            },
          ),
          RadioListTile<bool>(
            title: const Text('Mentions Only'),
            subtitle: const Text('Notify only when mentioned'),
            value: false,
            groupValue: _notifyForAllMessages,
            onChanged: (value) {
              setState(() {
                _notifyForAllMessages = !value!;
                _notifyForMentionsOnly = value;
              });
              _saveNotificationSettings();
            },
          ),
          const Divider(),
          _buildSectionHeader('Per-Room Settings'),
          ListTile(
            title: const Text('Customize Room Notifications'),
            subtitle: const Text('Override settings for specific rooms'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showRoomNotificationSettings();
            },
          ),
          const Divider(),
          _buildSectionHeader('Keywords'),
          ListTile(
            title: const Text('Notification Keywords'),
            subtitle: const Text('Get notified for specific words'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showKeywordSettings();
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

  void _saveNotificationSettings() {
    // Save notification settings using ProfileBloc
    context.read<ProfileBloc>().add(UpdateNotificationSettings(
          enableNotifications: _enableNotifications,
          enableSound: _enableSound,
          enableVibrate: _enableVibrate,
          notifyForAllMessages: _notifyForAllMessages,
        ));
  }

  void _showRoomNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Room Notifications'),
        content: const Text(
          'Customize notification settings for individual rooms.\n\n'
          'This feature allows you to override global notification settings '
          'for specific rooms (e.g., mute busy rooms, enable notifications '
          'for important rooms).',
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

  void _showKeywordSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Keywords'),
        content: const Text(
          'Set keywords that will trigger notifications even when in '
          '"Mentions Only" mode.\n\n'
          'Common examples: your name, urgent, important, etc.',
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
