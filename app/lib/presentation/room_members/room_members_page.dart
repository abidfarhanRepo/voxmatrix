import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/domain/entities/room_member.dart';
import 'package:voxmatrix/presentation/room_members/bloc/room_members_bloc.dart';
import 'package:voxmatrix/presentation/room_members/bloc/room_members_event.dart';
import 'package:voxmatrix/presentation/room_members/bloc/room_members_state.dart';

/// Room members page showing all members and their roles
class RoomMembersPage extends StatefulWidget {
  const RoomMembersPage({
    super.key,
    required this.roomId,
    required this.roomName,
    this.canKick = false,
    this.canBan = false,
    this.canInvite = false,
  });

  final String roomId;
  final String roomName;
  final bool canKick;
  final bool canBan;
  final bool canInvite;

  @override
  State<RoomMembersPage> createState() => _RoomMembersPageState();
}

class _RoomMembersPageState extends State<RoomMembersPage> {
  @override
  void initState() {
    super.initState();
    context.read<RoomMembersBloc>().add(LoadRoomMembers(widget.roomId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.roomName} - Members'),
        actions: widget.canInvite
            ? [
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _showInviteDialog(context),
                ),
              ]
            : null,
      ),
      body: BlocBuilder<RoomMembersBloc, RoomMembersState>(
        builder: (context, state) {
          if (state is RoomMembersLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is RoomMembersError) {
            return _buildErrorState(context, state.message);
          } else if (state is RoomMembersLoaded) {
            return _buildMembersList(context, state.members);
          } else if (state is RoomMembersActionInProgress) {
            return Stack(
              children: [
                _buildMembersList(context, state.members),
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
                            Text(state.action),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
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
            'Failed to load members',
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
                  .read<RoomMembersBloc>()
                  .add(LoadRoomMembers(widget.roomId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(BuildContext context, List<RoomMember> members) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No members yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<RoomMembersBloc>()
            .add(RefreshRoomMembers(widget.roomId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.spacing),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return _MemberTile(
            member: member,
            canKick: widget.canKick,
            canBan: widget.canBan,
            onKick: (reason) {
              context.read<RoomMembersBloc>().add(
                    KickUser(
                      roomId: widget.roomId,
                      userId: member.userId,
                      reason: reason,
                    ),
                  );
            },
            onBan: (reason) {
              context.read<RoomMembersBloc>().add(
                    BanUser(
                      roomId: widget.roomId,
                      userId: member.userId,
                      reason: reason,
                    ),
                  );
            },
          );
        },
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final userIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite User'),
        content: TextField(
          controller: userIdController,
          decoration: const InputDecoration(
            labelText: 'User ID',
            hintText: '@user:server.com',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final userId = userIdController.text.trim();
              if (userId.isNotEmpty) {
                Navigator.of(context).pop();
                context.read<RoomMembersBloc>().add(
                      InviteUser(
                        roomId: widget.roomId,
                        userId: userId,
                      ),
                    );
              }
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.canKick,
    required this.canBan,
    this.onKick,
    this.onBan,
  });

  final RoomMember member;
  final bool canKick;
  final bool canBan;
  final ValueChanged<String>? onKick;
  final ValueChanged<String>? onBan;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacing / 2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            member.initials,
            style: TextStyle(
              color: Color(member.colorHash),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          member.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Text(member.userId),
            const SizedBox(width: 8),
            _MembershipChip(membership: member.membership),
            if (member.isAdmin) ...[
              const SizedBox(width: 4),
              _RoleChip(label: 'Admin', color: AppColors.error),
            ] else if (member.isModerator) ...[
              const SizedBox(width: 4),
              _RoleChip(label: 'Mod', color: AppColors.primary),
            ],
          ],
        ),
        trailing: (canKick || canBan)
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'kick') {
                    _showKickDialog(context);
                  } else if (value == 'ban') {
                    _showBanDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  if (canKick)
                    const PopupMenuItem(
                      value: 'kick',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, size: 18),
                          SizedBox(width: 8),
                          Text('Kick'),
                        ],
                      ),
                    ),
                  if (canBan)
                    const PopupMenuItem(
                      value: 'ban',
                      child: Row(
                        children: [
                          Icon(Icons.block, size: 18),
                          SizedBox(width: 8),
                          Text('Ban'),
                        ],
                      ),
                    ),
                ],
              )
            : null,
      ),
    );
  }

  void _showKickDialog(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kick ${member.displayName}?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onKick?.call(reasonController.text.trim());
            },
            child: const Text('Kick'),
          ),
        ],
      ),
    );
  }

  void _showBanDialog(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ban ${member.displayName}?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onBan?.call(reasonController.text.trim());
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Ban'),
          ),
        ],
      ),
    );
  }
}

class _MembershipChip extends StatelessWidget {
  const _MembershipChip({required this.membership});

  final String membership;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (membership) {
      case 'join':
        color = AppColors.success;
        label = 'Member';
        break;
      case 'invite':
        color = AppColors.primary;
        label = 'Invited';
        break;
      case 'ban':
        color = AppColors.error;
        label = 'Banned';
        break;
      case 'leave':
        color = AppColors.onSurface.withOpacity(0.5);
        label = 'Left';
        break;
      default:
        color = AppColors.onSurface.withOpacity(0.3);
        label = membership;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
