import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/domain/entities/space_entity.dart';
import 'package:voxmatrix/presentation/spaces/bloc/spaces_bloc.dart';
import 'package:voxmatrix/presentation/spaces/bloc/spaces_event.dart';
import 'package:voxmatrix/presentation/spaces/bloc/spaces_state.dart';

/// Spaces page showing Matrix Spaces (homeserver groups)
class SpacesPage extends StatefulWidget {
  const SpacesPage({super.key});

  @override
  State<SpacesPage> createState() => _SpacesPageState();
}

class _SpacesPageState extends State<SpacesPage> {
  @override
  void initState() {
    super.initState();
    context.read<SpacesBloc>().add(const LoadSpaces());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spaces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateSpaceDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<SpacesBloc, SpacesState>(
        builder: (context, state) {
          if (state is SpacesLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is SpacesError) {
            return _buildErrorState(context, state.message);
          } else if (state is SpacesLoaded) {
            return _buildSpacesList(context, state.spaces);
          }
          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.workspaces_outline,
            size: 64,
            color: AppColors.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Spaces',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a space to organize your rooms',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCreateSpaceDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Space'),
          ),
        ],
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
            'Failed to load spaces',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.onSurface.withOpacity(0.5),
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
              context.read<SpacesBloc>().add(const LoadSpaces());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacesList(BuildContext context, List<SpaceEntity> spaces) {
    if (spaces.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SpacesBloc>().add(const LoadSpaces());
      },
      child: ListView.builder(
        itemCount: spaces.length,
        padding: const EdgeInsets.all(AppConstants.spacing),
        itemBuilder: (context, index) {
          final space = spaces[index];
          return _SpaceTile(
            space: space,
            onTap: () => _viewSpaceRooms(context, space),
          );
        },
      ),
    );
  }

  void _showCreateSpaceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final topicController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Space'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter space name',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: topicController,
              decoration: const InputDecoration(
                labelText: 'Topic (optional)',
                hintText: 'Enter space topic',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                context.read<SpacesBloc>().add(
                      CreateSpace(
                        name: nameController.text.trim(),
                        topic: topicController.text.trim().isEmpty
                            ? null
                            : topicController.text.trim(),
                      ),
                    );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _viewSpaceRooms(BuildContext context, SpaceEntity space) {
    // TODO: Navigate to space rooms view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View rooms in ${space.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _SpaceTile extends StatelessWidget {
  const _SpaceTile({
    required this.space,
    required this.onTap,
  });

  final SpaceEntity space;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacing / 2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            space.name.isNotEmpty ? space.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(space.name),
        subtitle: space.topic != null
            ? Text(
                space.topic!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Text('${space.memberCount} members'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
