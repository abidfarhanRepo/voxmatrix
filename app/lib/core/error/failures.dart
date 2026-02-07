import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Network error occurred',
    super.statusCode,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Cache error occurred',
    super.statusCode,
  });
}

class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed',
    super.statusCode,
  });
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Validation failed',
    super.statusCode,
  });
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Resource not found',
    super.statusCode,
  });
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'Permission denied',
    super.statusCode,
  });
}

class WebRTCFailure extends Failure {
  const WebRTCFailure({
    super.message = 'WebRTC error occurred',
    super.statusCode,
  });
}

class CryptoFailure extends Failure {
  const CryptoFailure({
    super.message = 'Cryptographic operation failed',
    super.statusCode,
  });
}

class EncryptionFailure extends Failure {
  const EncryptionFailure({
    super.message = 'Encryption failed',
    super.statusCode,
  });
}

class DecryptionFailure extends Failure {
  const DecryptionFailure({
    super.message = 'Decryption failed',
    super.statusCode,
  });
}

class SessionFailure extends Failure {
  const SessionFailure({
    super.message = 'Session operation failed',
    super.statusCode,
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unknown error occurred',
    super.statusCode,
  });
}
