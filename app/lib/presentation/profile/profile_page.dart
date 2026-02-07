import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/domain/entities/user_entity.dart';
import 'package:voxmatrix/presentation/auth/bloc/auth_bloc.dart';
import 'package:voxmatrix/presentation/auth/bloc/auth_state.dart';
import 'package:voxmatrix/presentation/profile/bloc/profile_bloc.dart';
import 'package:voxmatrix/presentation/profile/bloc/profile_event.dart';
import 'package:voxmatrix/presentation/profile/bloc/profile_state.dart';
import 'package:voxmatrix/presentation/profile/pages/notifications_settings_page.dart';
import 'package:voxmatrix/presentation/profile/pages/appearance_settings_page.dart';
import 'package:voxmatrix/presentation/profile/pages/privacy_settings_page.dart';
import 'package:voxmatrix/presentation/profile/pages/devices_page.dart';
import 'package:voxmatrix/presentation/profile/pages/encryption_keys_page.dart';
import 'package:voxmatrix/core/widgets/app_widgets.dart';

/// User profile page showing account info and settings
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const LoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          centerTitle: true,
        ),
        backgroundColor: Colors.transparent,
        body: AppBackground(
          glowAlignment: Alignment.topLeft,
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                final user = authState.user;
                return BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, profileState) {
                    final displayName = profileState is ProfileLoaded
                        ? profileState.displayName
                        : user.displayName;
                    final avatarUrl = profileState is ProfileLoaded
                        ? profileState.avatarUrl
                        : null;
                    final isLoading = profileState is ProfileUpdating &&
                        profileState.field == 'avatar';

                    return ListView(
                      children: [
                        _buildProfileHeader(
                          displayName,
                          avatarUrl,
                          user.id,
                          isLoading,
                        ),
                        const Divider(height: 32),
                        _buildSettingsSection(context),
                        const Divider(height: 32),
                        _buildAccountSection(context),
                        const Divider(height: 32),
                        _buildCryptoSection(context),
                        const Divider(height: 32),
                        _buildAboutSection(context),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    String displayName,
    String? avatarUrl,
    String userId,
    bool isLoadingAvatar,
  ) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Center(
          child: GestureDetector(
            onTap: () => _showAvatarPicker(context),
            child: Hero(
              tag: 'profile_avatar',
              child: Stack(
                children: [
                  Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (isLoadingAvatar)
                    const Positioned.fill(
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => _showAvatarPicker(context),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.camera_alt,
                            color: AppColors.onPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userId,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing * 2,
            vertical: AppConstants.spacing,
          ),
          child: Text(
            'SETTINGS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notifications'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationsSettingsPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode_outlined),
          title: const Text('Appearance'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AppearanceSettingsPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock_outlined),
          title: const Text('Privacy & Security'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PrivacySettingsPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.storage_outlined),
          title: const Text('Storage & Cache'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showStorageDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing * 2,
            vertical: AppConstants.spacing,
          ),
          child: Text(
            'ACCOUNT',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.devices_outlined),
          title: const Text('Devices'),
          subtitle: const Text('Manage your sessions'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const DevicesPage(),
              ),
            );
          },
        ),
        BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            final isLoading = state is ProfileUpdating &&
                state.field == 'displayName';
            return ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Profile'),
              trailing: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: isLoading ? null : () => _showEditProfileDialog(context),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCryptoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing * 2,
            vertical: AppConstants.spacing,
          ),
          child: Text(
            'ENCRYPTION',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.lock_outlined, color: Colors.green),
          title: const Text('Encryption Enabled'),
          subtitle: const Text('Your messages are end-to-end encrypted'),
          trailing: const Icon(Icons.check_circle, color: Colors.green),
        ),
        ListTile(
          leading: const Icon(Icons.key_outlined),
          title: const Text('Encryption Keys'),
          subtitle: const Text('Manage your encryption keys'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const EncryptionKeysPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: const Text('Verified Devices'),
          subtitle: const Text('View and verify devices'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const DevicesPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing * 2,
            vertical: AppConstants.spacing,
          ),
          child: Text(
            'ABOUT',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info_outlined),
          title: const Text('Version'),
          subtitle:
              Text('${AppConstants.appName} v${AppConstants.appVersion}'),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Licenses'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: 'VoxMatrix',
              applicationVersion: AppConstants.appVersion,
              applicationLegalese: '© 2025 VoxMatrix Contributors\n\n'
                  'VoxMatrix is an open-source Matrix client built with Flutter.\n\n'
                  'Matrix is an open network for secure, decentralised communication.',
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.code_outlined),
          title: const Text('Source Code'),
          subtitle: const Text('Open Source Matrix Client'),
          onTap: () {
            _launchUrl('https://github.com/yourusername/voxmatrix');
          },
        ),
      ],
    );
  }

  void _showAvatarPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 85,
                );
                if (image != null && context.mounted) {
                  context.read<ProfileBloc>().add(UpdateAvatar(image.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 85,
                );
                if (image != null && context.mounted) {
                  context.read<ProfileBloc>().add(UpdateAvatar(image.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove Photo'),
              onTap: () {
                Navigator.pop(context);
                context.read<ProfileBloc>().add(const RemoveAvatar());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final profileState = context.read<ProfileBloc>().state;
    final displayNameController = TextEditingController(
      text: profileState is ProfileLoaded ? profileState.displayName : '',
    );

    showDialog(
      context: context,
      builder: (context) => BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileSuccess) {
            Navigator.of(context).pop();
          }
        },
        child: AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your display name',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                final isLoading = state is ProfileUpdating &&
                    state.field == 'displayName';
                return ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          final newName = displayNameController.text.trim();
                          if (newName.isNotEmpty) {
                            context
                                .read<ProfileBloc>()
                                .add(UpdateDisplayName(newName));
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStorageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage & Cache'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clear cached data to free up space on your device.'),
            const SizedBox(height: 16),
            ListTile(
              dense: true,
              leading: const Icon(Icons.image),
              title: const Text('Images'),
              trailing: TextButton(
                onPressed: () {
                  // TODO: Clear image cache
                },
                child: const Text('Clear'),
              ),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.file_present),
              title: const Text('Files'),
              trailing: TextButton(
                onPressed: () {
                  // TODO: Clear file cache
                },
                child: const Text('Clear'),
              ),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.delete_sweep),
              title: const Text('All Cache'),
              trailing: TextButton(
                onPressed: () {
                  // TODO: Clear all cache
                  Navigator.of(context).pop();
                },
                child: const Text('Clear'),
              ),
            ),
          ],
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

  void showLicensePage({
    required BuildContext context,
    required String applicationName,
    required String applicationVersion,
    required String applicationLegalese,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LicensePage(
          applicationName: applicationName,
          applicationVersion: applicationVersion,
          applicationLegalese: applicationLegalese,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
