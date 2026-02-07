/// User Profile Manager for Matrix user profiles
///
/// Handles managing display names, avatars, and other user profile data
/// See: https://spec.matrix.org/v1.11/client-server-api/#profile-management

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/matrix/src/matrix_client.dart';

/// User Profile Manager
class UserProfileManager {
  /// Create a new user profile manager
  UserProfileManager({
    required this.client,
    required Logger logger,
  }) : _logger = logger;

  /// The Matrix client
  final MatrixClient client;

  /// Logger instance
  final Logger _logger;

  /// Get display name for a user
  ///
  /// [userId] The user ID (optional, defaults to current user)
  Future<String> getDisplayName([String? userId]) async {
    final targetUserId = userId ?? client.userId;
    if (targetUserId == null) {
      throw MatrixException('Cannot get display name: user ID not set');
    }

    _logger.d('Getting display name for user: $targetUserId');

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/profile/$targetUserId/displayname',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['displayname'] as String? ?? '';
    } else {
      throw MatrixException('Failed to get display name: ${response.statusCode}');
    }
  }

  /// Set own display name
  ///
  /// [displayName] The new display name
  Future<void> setDisplayName(String displayName) async {
    _logger.i('Setting display name to: $displayName');

    final userId = client.userId;
    if (userId == null) {
      throw MatrixException('Cannot set display name: user ID not set');
    }

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/profile/$userId/displayname',
    );

    final body = jsonEncode({'displayname': displayName});

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw MatrixException('Failed to set display name: ${response.statusCode}');
    }

    _logger.i('Display name set successfully');
  }

  /// Get avatar URL for a user
  ///
  /// [userId] The user ID (optional, defaults to current user)
  Future<String> getAvatarUrl([String? userId]) async {
    final targetUserId = userId ?? client.userId;
    if (targetUserId == null) {
      throw MatrixException('Cannot get avatar: user ID not set');
    }

    _logger.d('Getting avatar for user: $targetUserId');

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/profile/$targetUserId/avatar_url',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['avatar_url'] as String? ?? '';
    } else {
      throw MatrixException('Failed to get avatar: ${response.statusCode}');
    }
  }

  /// Set own avatar URL
  ///
  /// [avatarUrl] The MXC URI of the avatar
  Future<void> setAvatarUrl(String avatarUrl) async {
    _logger.i('Setting avatar URL to: $avatarUrl');

    final userId = client.userId;
    if (userId == null) {
      throw MatrixException('Cannot set avatar: user ID not set');
    }

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/profile/$userId/avatar_url',
    );

    final body = jsonEncode({'avatar_url': avatarUrl});

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw MatrixException('Failed to set avatar: ${response.statusCode}');
    }

    _logger.i('Avatar URL set successfully');
  }

  /// Upload and set avatar
  ///
  /// [imageData] The image bytes
  /// [filename] The filename
  /// [contentType] The content type (e.g., 'image/jpeg')
  Future<void> uploadAndSetAvatar(
    List<int> imageData,
    String filename, {
    String? contentType,
  }) async {
    _logger.i('Uploading and setting avatar');

    // Upload the image
    final mxcUri = await client.mediaManager.uploadImage(
      imageData,
      filename: filename,
      contentType: contentType,
    );

    // Set the avatar URL
    await setAvatarUrl(mxcUri);

    _logger.i('Avatar uploaded and set successfully');
  }

  /// Get full profile for a user
  ///
  /// [userId] The user ID (optional, defaults to current user)
  Future<UserProfile> getProfile([String? userId]) async {
    final targetUserId = userId ?? client.userId;
    if (targetUserId == null) {
      throw MatrixException('Cannot get profile: user ID not set');
    }

    _logger.d('Getting profile for user: $targetUserId');

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/profile/$targetUserId',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserProfile.fromJson(data);
    } else {
      throw MatrixException('Failed to get profile: ${response.statusCode}');
    }
  }

  /// Set profile
  ///
  /// [displayName] Optional new display name
  /// [avatarUrl] Optional new avatar URL
  Future<void> setProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    if (displayName != null) {
      await setDisplayName(displayName);
    }
    if (avatarUrl != null) {
      await setAvatarUrl(avatarUrl);
    }
  }

  /// Dispose of the user profile manager
  Future<void> dispose() async {
    _logger.i('User profile manager disposed');
  }
}

/// User profile information
class UserProfile {
  /// Create a user profile from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: json['displayname'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  /// Create a new user profile
  UserProfile({
    this.displayName,
    this.avatarUrl,
  });

  /// The display name
  final String? displayName;

  /// The avatar MXC URL
  final String? avatarUrl;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (displayName != null) 'displayname': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }

  /// Whether the profile is empty (no display name or avatar)
  bool get isEmpty => displayName == null && avatarUrl == null;

  /// Whether the profile has a display name
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;

  /// Whether the profile has an avatar
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
}
