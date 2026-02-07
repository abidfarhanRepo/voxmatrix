/// Push Manager for Matrix push notifications
///
/// Handles push notification setup and processing using the Matrix Push Gateway API
/// Supports UnifiedPush and FCM/APNs integration
///
/// See: https://spec.matrix.org/v1.11/client-server-api/#push-notifications
/// See: https://spec.matrix.org/v1.11/push-gateway-api/

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/matrix/src/matrix_client.dart';
import 'package:voxmatrix/core/matrix/src/models/event.dart';

/// Push Manager for Matrix push notifications
class PushManager {
  /// Create a new push manager
  PushManager({
    required this.client,
    required Logger logger,
  }) : _logger = logger;

  /// The Matrix client
  final MatrixClient client;

  /// Logger instance
  final Logger _logger;

  /// Push gateway URL
  String? _pushGatewayUrl;

  /// Push token (FCM/APNs/UnifiedPush)
  String? _pushToken;

  /// Is push enabled
  bool _isEnabled = false;

  /// Get the push gateway URL
  String? get pushGatewayUrl => _pushGatewayUrl;

  /// Get the push token
  String? get pushToken => _pushToken;

  /// Check if push is enabled
  bool get isEnabled => _isEnabled;

  /// Enable push notifications with a push gateway
  ///
  /// [gatewayUrl] The URL of the push gateway (e.g., 'https://matrix.org/_matrix/push/v1/notify')
  /// [token] The push token from FCM/APNs/UnifiedPush
  /// [appId] The app ID for push notifications
  /// [deviceName] Optional device name
  Future<void> enablePush({
    required String gatewayUrl,
    required String token,
    String? appId,
    String? deviceName,
  }) async {
    _logger.i('Enabling push notifications');

    _pushGatewayUrl = gatewayUrl;
    _pushToken = token;

    // Register push notifications with the homeserver
    await _registerPushNotifications(
      gatewayUrl: gatewayUrl,
      token: token,
      appId: appId ?? 'io.voxmatrix.app',
      deviceName: deviceName ?? 'VoxMatrix',
    );

    _isEnabled = true;
    _logger.i('Push notifications enabled');
  }

  /// Disable push notifications
  Future<void> disablePush() async {
    _logger.i('Disabling push notifications');

    if (!_isEnabled) {
      _logger.w('Push notifications already disabled');
      return;
    }

    // Delete pushers from the homeserver
    await _deletePushers();

    _isEnabled = false;
    _pushToken = null;
    _pushGatewayUrl = null;

    _logger.i('Push notifications disabled');
  }

  /// Update the push token
  Future<void> setPushToken(String token) async {
    _logger.i('Updating push token');

    _pushToken = token;

    if (_isEnabled && _pushGatewayUrl != null) {
      // Re-register with the new token
      await _registerPushNotifications(
        gatewayUrl: _pushGatewayUrl!,
        token: token,
        appId: 'io.voxmatrix.app',
        deviceName: 'VoxMatrix',
      );
    }
  }

  /// Register push notifications with the homeserver
  Future<void> _registerPushNotifications({
    required String gatewayUrl,
    required String token,
    required String appId,
    required String deviceName,
  }) async {
    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/pushers/set');

    final pusher = {
      'pushkey': token,
      'kind': 'http',
      'app_id': appId,
      'app_display_name': 'VoxMatrix',
      'device_display_name': deviceName,
      'profile_tag': 'voxmatrix',
      'lang': 'en',
      'data': {
        'url': gatewayUrl,
        'format': 'event_id_only',
      },
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: jsonEncode(pusher),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw MatrixException('Failed to register push notifications: ${response.statusCode}');
    }

    _logger.d('Push notifications registered successfully');
  }

  /// Delete all pushers
  Future<void> _deletePushers() async {
    if (_pushToken == null) return;

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/pushers/set');

    // Delete by setting enabled to false
    final pusher = {
      'pushkey': _pushToken,
      'kind': 'http',
      'app_id': 'io.voxmatrix.app',
      'app_display_name': 'VoxMatrix',
      'device_display_name': 'VoxMatrix',
      'profile_tag': 'voxmatrix',
      'lang': 'en',
      'data': {
        'url': _pushGatewayUrl ?? '',
        'format': 'event_id_only',
      },
      'enabled': false,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: jsonEncode(pusher),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      _logger.w('Failed to delete pushers: ${response.statusCode}');
    }
  }

  /// Get all pushers for the user
  Future<List<Pusher>> getPushers() async {
    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/pushers');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final pushers = data['pushers'] as List? ?? [];
      return pushers
          .map((p) => p is Map<String, dynamic> ? Pusher.fromJson(p) : null)
          .whereType<Pusher>()
          .toList();
    } else {
      throw MatrixException('Failed to get pushers: ${response.statusCode}');
    }
  }

  /// Get push rules
  Future<PushRules> getPushRules() async {
    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/pushrules/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PushRules.fromJson(data);
    } else {
      throw MatrixException('Failed to get push rules: ${response.statusCode}');
    }
  }

  /// Dispose of the push manager
  Future<void> dispose() async {
    _logger.i('Push manager disposed');
  }
}

/// Pusher configuration
class Pusher {
  /// Create a pusher from JSON
  factory Pusher.fromJson(Map<String, dynamic> json) {
    return Pusher(
      pushKey: json['pushkey'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      appId: json['app_id'] as String? ?? '',
      appDisplayName: json['app_display_name'] as String? ?? '',
      deviceDisplayName: json['device_display_name'] as String? ?? '',
      profileTag: json['profile_tag'] as String?,
      lang: json['lang'] as String? ?? 'en',
      data: json['data'] as Map<String, dynamic>? ?? {},
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  /// Create a new pusher
  Pusher({
    required this.pushKey,
    required this.kind,
    required this.appId,
    required this.appDisplayName,
    required this.deviceDisplayName,
    this.profileTag,
    required this.lang,
    required this.data,
    this.enabled = true,
  });

  /// The push key
  final String pushKey;

  /// The kind of pusher (http, email, etc.)
  final String kind;

  /// The app ID
  final String appId;

  /// The app display name
  final String appDisplayName;

  /// The device display name
  final String deviceDisplayName;

  /// The profile tag
  final String? profileTag;

  /// The language
  final String lang;

  /// Additional data
  final Map<String, dynamic> data;

  /// Whether the pusher is enabled
  final bool enabled;
}

/// Push rules
class PushRules {
  /// Create push rules from JSON
  factory PushRules.fromJson(Map<String, dynamic> json) {
    return PushRules(
      global: _parseRuleScope(json['global'] as Map<String, dynamic>?),
      device: _parseRuleScope(json['device'] as Map<String, dynamic>?),
    );
  }

  /// Create new push rules
  PushRules({
    required this.global,
    this.device = const {},
  });

  /// Parse a rule scope
  static Map<String, List<PushRule>> _parseRuleScope(Map<String, dynamic>? json) {
    if (json == null) return {};

    final result = <String, List<PushRule>>{};

    for (final entry in json.entries) {
      final scope = entry.key;
      final rules = entry.value as Map<String, dynamic>? ?? {};

      for (final ruleEntry in rules.entries) {
        final ruleKind = ruleEntry.key;
        final rulesList = ruleEntry.value as List? ?? [];

        final key = '$scope.$ruleKind';
        result[key] = rulesList
            .map((r) => r is Map<String, dynamic> ? PushRule.fromJson(r) : null)
            .whereType<PushRule>()
            .toList();
      }
    }

    return result;
  }

  /// Global rules
  final Map<String, List<PushRule>> global;

  /// Device-specific rules
  final Map<String, List<PushRule>> device;
}

/// Push rule
class PushRule {
  /// Create a push rule from JSON
  factory PushRule.fromJson(Map<String, dynamic> json) {
    return PushRule(
      ruleId: json['rule_id'] as String? ?? '',
      scope: json['scope'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      actions: (json['actions'] as List?)
              ?.map((a) => a is Map<String, dynamic> ? PushAction.fromJson(a) : null)
              .whereType<PushAction>()
              .toList() ??
          [],
      conditions: (json['conditions'] as List?)
              ?.map((c) => c is Map<String, dynamic> ? PushCondition.fromJson(c) : null)
              .whereType<PushCondition>()
              .toList() ??
          [],
      pattern: json['pattern'] as String?,
    );
  }

  /// Create a new push rule
  PushRule({
    required this.ruleId,
    required this.scope,
    required this.kind,
    this.enabled = true,
    this.actions = const [],
    this.conditions = const [],
    this.pattern,
  });

  /// The rule ID
  final String ruleId;

  /// The scope (global, device, etc.)
  final String scope;

  /// The kind (override, underride, sender, room, content)
  final String kind;

  /// Whether the rule is enabled
  final bool enabled;

  /// The actions to take
  final List<PushAction> actions;

  /// The conditions
  final List<PushCondition> conditions;

  /// The pattern for content rules
  final String? pattern;
}

/// Push action
class PushAction {
  /// Create a push action from JSON
  factory PushAction.fromJson(Map<String, dynamic> json) {
    return PushAction(
      action: json['action'] as String? ?? '',
      parameters: json['parameters'] as Map<String, dynamic>?,
      ruleId: json['rule_id'] as String?,
    );
  }

  /// Create a new push action
  PushAction({
    required this.action,
    this.parameters,
    this.ruleId,
  });

  /// The action (notify, dont_notify, set_tweak, etc.)
  final String action;

  /// The parameters
  final Map<String, dynamic>? parameters;

  /// The rule ID
  final String? ruleId;
}

/// Push condition
class PushCondition {
  /// Create a push condition from JSON
  factory PushCondition.fromJson(Map<String, dynamic> json) {
    return PushCondition(
      kind: json['kind'] as String? ?? '',
      key: json['key'] as String?,
      pattern: json['pattern'] as String?,
      isEnabled: json['is'] as String?,
    );
  }

  /// Create a new push condition
  PushCondition({
    required this.kind,
    this.key,
    this.pattern,
    this.isEnabled,
  });

  /// The kind of condition (event_match, contains, etc.)
  final String kind;

  /// The key
  final String? key;

  /// The pattern
  final String? pattern;

  /// The comparison value
  final String? isEnabled;
}
