class AppConstants {
  AppConstants._();

  static const String appName = 'VoxMatrix';
  static const String appVersion = '1.0.0';

  // Matrix Configuration
  static const String defaultHomeserver = 'http://192.168.10.4:8008';
  static const int syncTimeout = 30000;
  static const int syncFilterLimit = 20;

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String userIdKey = 'user_id';
  static const String deviceIdKey = 'device_id';
  static const String homeserverKey = 'homeserver';

  // UI Constants
  static const double borderRadius = 8.0;
  static const double spacing = 16.0;
  static const double iconSize = 24.0;

  // Pagination
  static const int pageSize = 50;
  static const int initialLoadCount = 20;
}
