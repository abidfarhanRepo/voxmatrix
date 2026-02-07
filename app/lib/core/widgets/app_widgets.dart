import 'package:flutter/material.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';

/// Gradient background wrapper for dark mode
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.glowAlignment = Alignment.topRight,
  });

  final Widget child;
  final Alignment glowAlignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.gradientStart,
                  AppColors.gradientMid,
                  AppColors.gradientEnd,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: glowAlignment,
                radius: 1.2,
                colors: [
                  AppColors.primary.withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Custom styled buttons for VoxMatrix
class AppButtons {
  /// Primary elevated button with custom styling
  static Widget primary({
    required VoidCallback onPressed,
    required Widget child,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return ElevatedButton(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
              ),
            )
          : child,
    );
  }

  /// Secondary outlined button
  static Widget secondary({
    required VoidCallback onPressed,
    required Widget child,
    bool isEnabled = true,
  }) {
    return OutlinedButton(
      onPressed: isEnabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: child,
    );
  }

  /// Text button with custom styling
  static Widget text({
    required VoidCallback onPressed,
    required Widget child,
    Color? color,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: child,
    );
  }

  /// Icon button with tooltip
  static Widget icon({
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
    Color? color,
  }) {
    final button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      splashRadius: 24,
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }
}

/// Custom cards for VoxMatrix
class AppCards {
  /// Basic card with elevation and border radius
  static Widget basic({
    required Widget child,
    VoidCallback? onTap,
    Color? backgroundColor,
    double elevation = 1,
  }) {
    final card = Card(
      elevation: elevation,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    return card;
  }

  /// Room list card with avatar and details
  static Widget room({
    required String name,
    String? topic,
    String? avatarUrl,
    int unreadCount = 0,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _AvatarWithInitial(
                name: name,
                avatarUrl: avatarUrl,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (topic != null)
                      Text(
                        topic,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.onSurface.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              if (unreadCount > 0) _UnreadBadge(count: unreadCount),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar with initial letter fallback
class _AvatarWithInitial extends StatelessWidget {
  const _AvatarWithInitial({
    required this.name,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      child: avatarUrl != null
          ? null // TODO: Add cached network image
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
    );
  }
}

/// Unread message badge
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: AppColors.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Empty state widget with illustration
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.6),
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface.withOpacity(0.4),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            AppButtons.primary(
              onPressed: onAction!,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state widget with retry option
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  }) : assert(onRetry != null, 'onRetry should not be null');

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
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
            'Something went wrong',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface.withOpacity(0.4),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            AppButtons.secondary(
              onPressed: onRetry!,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
