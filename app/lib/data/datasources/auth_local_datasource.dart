import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';

class AuthLocalDataSource {
  const AuthLocalDataSource(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  Future<void> saveAccessToken(String token) async {
    try {
      await _secureStorage.write(key: AppConstants.accessTokenKey, value: token);
    } catch (e) {
      throw CacheException(message: e.toString(), statusCode: 500);
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: AppConstants.accessTokenKey);
    } catch (e) {
      throw CacheException(message: e.toString(), statusCode: 500);
    }
  }

  Future<void> saveUserId(String userId) async {
    try {
      await _secureStorage.write(key: AppConstants.userIdKey, value: userId);
    } catch (e) {
      throw CacheException(message: e.toString(), statusCode: 500);
    }
  }

  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: AppConstants.userIdKey);
    } catch (e) {
      throw CacheException(message: e.toString(), statusCode: 500);
    }
  }

  Future<void> saveDeviceId(String deviceId) async {
    try {
      await _secureStorage.write(key: AppConstants.deviceIdKey, value: deviceId);
    } catch (e) {
      throw CacheException(message: e.toString(), statusCode: 500);
    }
  }

  Future<String?> getDeviceId() async {
    try {
      return await _secureStorage.read(key: AppConstants.deviceIdKey);
    } catch (e) {
      throw CacheException(message: e.toString(), statusCode: 500);
    }
  }

  Future<void> saveHomeserver(String homeserver) async {
    try {
      await _secureStorage.write(
        key: AppConstants.homeserverKey,
        value: homeserver,
      );
    } catch (e) {
      throw CacheException(message: e.toString(), statusCode: 500);
    }
  }

  Future<String?> getHomeserver() async {
    try {
      return await _secureStorage.read(key: AppConstants.homeserverKey);
    } catch (e) {
      throw CacheException(message: e.toString(), statusCode: 500);
    }
  }

  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw CacheException(message: e.toString(), statusCode: 500);
    }
  }

  Future<bool> hasTokens() async {
    try {
      final token = await getAccessToken();
      final userId = await getUserId();
      return token != null && userId != null;
    } catch (e) {
      throw CacheException(message: e.toString(), statusCode: 500);
    }
  }
}
