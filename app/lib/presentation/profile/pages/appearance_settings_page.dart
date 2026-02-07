import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/presentation/profile/bloc/profile_bloc.dart';
import 'package:voxmatrix/presentation/profile/bloc/profile_event.dart';

/// Appearance settings page
class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() =>
      _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0;
  bool _showReadReceipts = true;
  bool _showTypingIndicators = true;
  bool _compactView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Theme'),
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            subtitle: const Text('Follow system theme'),
            value: ThemeMode.system,
            groupValue: _themeMode,
            onChanged: (value) {
              setState(() {
                _themeMode = value!;
              });
              _saveAppearanceSettings();
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            subtitle: const Text('Always use light theme'),
            value: ThemeMode.light,
            groupValue: _themeMode,
            onChanged: (value) {
              setState(() {
                _themeMode = value!;
              });
              _saveAppearanceSettings();
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            subtitle: const Text('Always use dark theme'),
            value: ThemeMode.dark,
            groupValue: _themeMode,
            onChanged: (value) {
              setState(() {
                _themeMode = value!;
              });
              _saveAppearanceSettings();
            },
          ),
          const Divider(),
          _buildSectionHeader('Text Size'),
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacing * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Font Scale'),
                    Text(
                      '${(_fontScale * 100).toInt()}%',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _fontScale,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  label: '${(_fontScale * 100).toInt()}%',
                  onChanged: (value) {
                    setState(() {
                      _fontScale = value;
                    });
                    _saveAppearanceSettings();
                  },
                ),
                Text(
                  'Adjust text size throughout the app',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader('Message Display'),
          SwitchListTile(
            title: const Text('Show Read Receipts'),
            subtitle: const Text('Show when messages are read'),
            value: _showReadReceipts,
            onChanged: (value) {
              setState(() {
                _showReadReceipts = value;
              });
              _saveAppearanceSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Show Typing Indicators'),
            subtitle: const Text('Show when others are typing'),
            value: _showTypingIndicators,
            onChanged: (value) {
              setState(() {
                _showTypingIndicators = value;
              });
              _saveAppearanceSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Compact View'),
            subtitle: const Text('Show more messages on screen'),
            value: _compactView,
            onChanged: (value) {
              setState(() {
                _compactView = value;
              });
              _saveAppearanceSettings();
            },
          ),
          const Divider(),
          _buildSectionHeader('Room List'),
          ListTile(
            title: const Text('Room Display Order'),
            subtitle: Text(_getRoomOrderLabel()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showRoomOrderDialog();
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

  String _getRoomOrderLabel() {
    // Default to activity
    return 'By Activity';
  }

  void _saveAppearanceSettings() {
    context.read<ProfileBloc>().add(UpdateAppearanceSettings(
          themeMode: _themeMode,
          fontScale: _fontScale,
          showReadReceipts: _showReadReceipts,
          showTypingIndicators: _showTypingIndicators,
          compactView: _compactView,
        ));
  }

  void _showRoomOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Room Display Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('By Activity'),
              subtitle: const Text('Most recent rooms first'),
              value: 'activity',
              groupValue: 'activity',
              onChanged: (value) {
                Navigator.of(context).pop();
                _saveAppearanceSettings();
              },
            ),
            RadioListTile<String>(
              title: const Text('Alphabetically'),
              subtitle: const Text('A to Z'),
              value: 'alphabetical',
              groupValue: 'activity',
              onChanged: (value) {
                Navigator.of(context).pop();
                _saveAppearanceSettings();
              },
            ),
            RadioListTile<String>(
              title: const Text('By Unread Count'),
              subtitle: const Text('Rooms with most unread messages'),
              value: 'unread',
              groupValue: 'activity',
              onChanged: (value) {
                Navigator.of(context).pop();
                _saveAppearanceSettings();
              },
            ),
          ],
        ),
      ),
    );
  }
}
