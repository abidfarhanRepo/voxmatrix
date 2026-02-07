import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/domain/entities/room_settings.dart';
import 'package:voxmatrix/presentation/room_settings/bloc/room_settings_bloc.dart';
import 'package:voxmatrix/presentation/room_settings/bloc/room_settings_event.dart';
import 'package:voxmatrix/presentation/room_settings/bloc/room_settings_state.dart';

/// Room settings page
class RoomSettingsPage extends StatefulWidget {
  const RoomSettingsPage({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  final String roomId;
  final String roomName;

  @override
  State<RoomSettingsPage> createState() => _RoomSettingsPageState();
}

class _RoomSettingsPageState extends State<RoomSettingsPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<RoomSettingsBloc>()
        .add(LoadRoomSettings(widget.roomId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Settings'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'leave') {
                _showLeaveDialog(context);
              } else if (value == 'delete') {
                _showDeleteDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, size: 18),
                    SizedBox(width: 8),
                    Text('Leave Room'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete Room',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<RoomSettingsBloc, RoomSettingsState>(
        listener: (context, state) {
          if (state is RoomSettingsDeleted) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Room deleted')),
            );
          } else if (state is RoomSettingsLeft) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Left room')),
            );
          } else if (state is RoomSettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RoomSettingsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is RoomSettingsLoaded) {
            return _buildSettingsList(context, state.settings);
          } else if (state is RoomSettingsSaving) {
            return Stack(
              children: [
                _buildSettingsList(context, state.settings),
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text('Saving ${state.setting}...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else if (state is RoomSettingsError) {
            return _buildErrorState(context, state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.4),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context
                  .read<RoomSettingsBloc>()
                  .add(LoadRoomSettings(widget.roomId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, RoomSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacing),
      children: [
        _SectionHeader(title: 'Basic Info', icon: Icons.info_outline),
        _SettingCard(
          title: 'Room Name',
          subtitle: settings.name ?? 'No name set',
          trailing: Icons.edit,
          onTap: () => _showEditNameDialog(context, settings),
        ),
        _SettingCard(
          title: 'Topic',
          subtitle: settings.topic ?? 'No topic set',
          trailing: Icons.edit,
          onTap: () => _showEditTopicDialog(context, settings),
        ),
        const SizedBox(height: AppConstants.spacing),

        _SectionHeader(title: 'Access Control', icon: Icons.lock_outline),
        _SettingCard(
          title: 'Join Rule',
          subtitle: settings.joinRule.displayName,
          trailing: Icons.chevron_right,
          onTap: () => _showJoinRuleSelector(context, settings),
        ),
        _SettingCard(
          title: 'Guest Access',
          subtitle: settings.guestAccess.displayName,
          trailing: Icons.chevron_right,
          onTap: () => _showGuestAccessSelector(context, settings),
        ),
        const SizedBox(height: AppConstants.spacing),

        _SectionHeader(
          title: 'History Visibility',
          icon: Icons.history_outlined,
        ),
        _SettingCard(
          title: 'Who can see history?',
          subtitle: settings.historyVisibility.displayName,
          description: settings.historyVisibility.description,
          trailing: Icons.chevron_right,
          onTap: () => _showHistoryVisibilitySelector(context, settings),
        ),
        const SizedBox(height: AppConstants.spacing),

        _SectionHeader(title: 'Room Info', icon: Icons.info),
        _InfoCard(
          title: 'Room ID',
          content: widget.roomId,
        ),
        const SizedBox(height: AppConstants.spacing * 2),

        // Danger zone
        _SectionHeader(title: 'Danger Zone', icon: Icons.warning_outlined),
        Card(
          color: AppColors.error.withOpacity(0.1),
          child: ListTile(
            leading: const Icon(Icons.exit_to_app, color: AppColors.error),
            title: const Text('Leave Room',
                style: TextStyle(color: AppColors.error)),
            subtitle: const Text('You can rejoin later if invited'),
            onTap: () => _showLeaveDialog(context),
          ),
        ),
        Card(
          color: AppColors.error.withOpacity(0.1),
          child: ListTile(
            leading: const Icon(Icons.delete, color: AppColors.error),
            title: const Text('Delete Room',
                style: TextStyle(color: AppColors.error)),
            subtitle: const Text('Permanently delete this room'),
            onTap: () => _showDeleteDialog(context),
          ),
        ),
      ],
    );
  }

  void _showEditNameDialog(BuildContext context, RoomSettings settings) {
    final controller = TextEditingController(text: settings.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Room Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Room Name',
            hintText: 'Enter room name',
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            Navigator.of(context).pop();
            context.read<RoomSettingsBloc>().add(
                  UpdateRoomName(
                    roomId: widget.roomId,
                    name: value.trim(),
                  ),
                );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<RoomSettingsBloc>().add(
                    UpdateRoomName(
                      roomId: widget.roomId,
                      name: controller.text.trim(),
                    ),
                  );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditTopicDialog(BuildContext context, RoomSettings settings) {
    final controller = TextEditingController(text: settings.topic ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Room Topic'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Topic',
            hintText: 'What is this room about?',
          ),
          autofocus: true,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            Navigator.of(context).pop();
            context.read<RoomSettingsBloc>().add(
                  UpdateRoomTopic(
                    roomId: widget.roomId,
                    topic: value.trim(),
                  ),
                );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<RoomSettingsBloc>().add(
                    UpdateRoomTopic(
                      roomId: widget.roomId,
                      topic: controller.text.trim(),
                    ),
                  );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showJoinRuleSelector(BuildContext context, RoomSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Rule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: JoinRule.values.map((rule) {
            final isSelected = rule == settings.joinRule;
            return RadioListTile<JoinRule>(
              title: Text(rule.displayName),
              value: rule,
              groupValue: settings.joinRule,
              onChanged: (value) {
                if (value != null) {
                  Navigator.of(context).pop();
                  context.read<RoomSettingsBloc>().add(
                        UpdateJoinRule(
                          roomId: widget.roomId,
                          joinRule: value,
                        ),
                      );
                }
              },
              selected: isSelected,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showGuestAccessSelector(BuildContext context, RoomSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guest Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GuestAccess.values.map((access) {
            final isSelected = access == settings.guestAccess;
            return RadioListTile<GuestAccess>(
              title: Text(access.displayName),
              subtitle: Text(
                access == GuestAccess.canJoin
                    ? 'Guests can join this room'
                    : 'Guests cannot join this room',
              ),
              value: access,
              groupValue: settings.guestAccess,
              onChanged: (value) {
                if (value != null) {
                  Navigator.of(context).pop();
                  context.read<RoomSettingsBloc>().add(
                        UpdateGuestAccess(
                          roomId: widget.roomId,
                          guestAccess: value,
                        ),
                      );
                }
              },
              selected: isSelected,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHistoryVisibilitySelector(
    BuildContext context,
    RoomSettings settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('History Visibility'),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: HistoryVisibility.values.map((visibility) {
              final isSelected = visibility == settings.historyVisibility;
              return RadioListTile<HistoryVisibility>(
                title: Text(visibility.displayName),
                subtitle: Text(visibility.description),
                value: visibility,
                groupValue: settings.historyVisibility,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.of(context).pop();
                    context.read<RoomSettingsBloc>().add(
                          UpdateHistoryVisibility(
                            roomId: widget.roomId,
                            historyVisibility: value,
                          ),
                        );
                  }
                },
                selected: isSelected,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Room?'),
        content: const Text(
          'Are you sure you want to leave this room? You can rejoin later if invited.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<RoomSettingsBloc>()
                  .add(LeaveRoom(widget.roomId));
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room?'),
        content: const Text(
          'This will permanently delete the room and all its messages. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<RoomSettingsBloc>()
                  .add(DeleteRoom(widget.roomId));
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.spacing / 2,
        bottom: AppConstants.spacing / 2,
        top: AppConstants.spacing / 2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.title,
    required this.subtitle,
    this.description,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? description;
  final IconData trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacing / 2),
      child: ListTile(
        title: Text(title),
        subtitle: description != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subtitle),
                  if (description != null)
                    Text(
                      description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurface.withOpacity(0.6),
                          ),
                    ),
                ],
              )
            : Text(subtitle),
        trailing: Icon(trailing, size: 18),
        onTap: onTap,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacing / 2),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
