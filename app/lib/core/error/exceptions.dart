import 'package:equatable/equatable.dart';

/// Base exception class for all custom exceptions
abstract class AppException extends Equatable implements Exception {
  const AppException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => message;
}

class ServerException extends AppException {
  const ServerException({required super.message, required super.statusCode});
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network error occurred',
    super.statusCode = 500,
  });
}

class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error occurred',
    super.statusCode = 500,
  });
}

class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication failed',
    super.statusCode = 401,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    super.message = 'Validation failed',
    super.statusCode = 400,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.statusCode = 404,
  });
}

class PermissionException extends AppException {
  const PermissionException({
    super.message = 'Permission denied',
    super.statusCode = 403,
  });
}

class WebRTCException extends AppException {
  const WebRTCException({
    super.message = 'WebRTC error occurred',
    super.statusCode = 500,
  });
}

class CryptoException extends AppException {
  const CryptoException({
    super.message = 'Cryptographic operation failed',
    super.statusCode = 500,
  });
}

class EncryptionException extends AppException {
  const EncryptionException({
    super.message = 'Encryption failed',
    super.statusCode = 500,
  });
}

class DecryptionException extends AppException {
  const DecryptionException({
    super.message = 'Decryption failed',
    super.statusCode = 500,
  });
}

class SessionException extends AppException {
  const SessionException({
    super.message = 'Session operation failed',
    super.statusCode = 500,
  });
}
