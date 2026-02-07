/// Account Data Manager for Matrix account data
///
/// Handles storing and retrieving user-specific account data
/// See: https://spec.matrix.org/v1.11/client-server-api/#account-data

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/matrix/src/matrix_client.dart';

/// Account Data Manager
class AccountDataManager {
  /// Create a new account data manager
  AccountDataManager({
    required this.client,
    required Logger logger,
  }) : _logger = logger;

  /// The Matrix client
  final MatrixClient client;

  /// Logger instance
  final Logger _logger;

  /// Set account data
  ///
  /// [type] The event type (e.g., 'm.direct', 'm.ignored_user_list')
  /// [content] The content to set
  Future<void> setAccountData(
    String type,
    Map<String, dynamic> content,
  ) async {
    _logger.i('Setting account data: $type');

    final userId = client.userId;
    if (userId == null) {
      throw MatrixException('Cannot set account data: user ID not set');
    }

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/user/$userId/account_data/$type',
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: jsonEncode(content),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw MatrixException('Failed to set account data: ${response.statusCode}');
    }

    _logger.i('Account data set successfully');
  }

  /// Get account data
  ///
  /// [type] The event type to retrieve
  Future<Map<String, dynamic>> getAccountData(String type) async {
    _logger.d('Getting account data: $type');

    final userId = client.userId;
    if (userId == null) {
      throw MatrixException('Cannot get account data: user ID not set');
    }

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/user/$userId/account_data/$type',
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
      return data;
    } else if (response.statusCode == 404) {
      // Account data not set yet, return empty map
      return {};
    } else {
      throw MatrixException('Failed to get account data: ${response.statusCode}');
    }
  }

  /// Set room-specific account data
  ///
  /// [roomId] The room ID
  /// [type] The event type
  /// [content] The content to set
  Future<void> setRoomAccountData(
    String roomId,
    String type,
    Map<String, dynamic> content,
  ) async {
    _logger.i('Setting room account data: $roomId/$type');

    final userId = client.userId;
    if (userId == null) {
      throw MatrixException('Cannot set room account data: user ID not set');
    }

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/user/$userId/account_data/$roomId/$type',
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: jsonEncode(content),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw MatrixException('Failed to set room account data: ${response.statusCode}');
    }

    _logger.i('Room account data set successfully');
  }

  /// Get room-specific account data
  ///
  /// [roomId] The room ID
  /// [type] The event type
  Future<Map<String, dynamic>> getRoomAccountData(
    String roomId,
    String type,
  ) async {
    _logger.d('Getting room account data: $roomId/$type');

    final userId = client.userId;
    if (userId == null) {
      throw MatrixException('Cannot get room account data: user ID not set');
    }

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/user/$userId/account_data/$roomId/$type',
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
      return data;
    } else if (response.statusCode == 404) {
      // Account data not set yet, return empty map
      return {};
    } else {
      throw MatrixException('Failed to get room account data: ${response.statusCode}');
    }
  }

  /// Set direct message mapping
  ///
  /// [directMessages] Map of user IDs to room IDs for direct messages
  Future<void> setDirectMessages(Map<String, List<String>> directMessages) async {
    await setAccountData('m.direct', directMessages);
  }

  /// Get direct message mapping
  Future<Map<String, List<String>>> getDirectMessages() async {
    final data = await getAccountData('m.direct');
    return data.map(
      (key, value) => MapEntry(
        key,
        value is List ? value.cast<String>() : [],
      ),
    );
  }

  /// Set ignored user list
  ///
  /// [ignoredUsers] List of user IDs to ignore
  Future<void> setIgnoredUsers(List<String> ignoredUsers) async {
    final ignoredData = {
      for (final userId in ignoredUsers)
        userId: <String, dynamic>{},
    };
    await setAccountData('m.ignored_user_list', ignoredData);
  }

  /// Get ignored user list
  Future<List<String>> getIgnoredUsers() async {
    final data = await getAccountData('m.ignored_user_list');
    return data.keys.toList();
  }

  /// Set client-specific account data
  ///
  /// This is useful for storing app-specific settings
  /// [key] The data key
  /// [value] The value to store
  Future<void> setClientData(String key, dynamic value) async {
    final content = {'value': value};
    await setAccountData('io.voxmatrix.$key', content);
  }

  /// Get client-specific account data
  ///
  /// [key] The data key
  Future<dynamic> getClientData(String key) async {
    final data = await getAccountData('io.voxmatrix.$key');
    return data['value'];
  }

  /// Dispose of the account data manager
  Future<void> dispose() async {
    _logger.i('Account data manager disposed');
  }
}
