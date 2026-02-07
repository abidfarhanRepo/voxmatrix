import 'package:equatable/equatable.dart';

abstract class CryptoEvent extends Equatable {
  const CryptoEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCrypto extends CryptoEvent {
  const InitializeCrypto();
}

class GetDeviceKeys extends CryptoEvent {
  const GetDeviceKeys();
}

class UploadDeviceKeys extends CryptoEvent {
  const UploadDeviceKeys();
}

class VerifyDevice extends CryptoEvent {
  const VerifyDevice({
    required this.userId,
    required this.deviceId,
    required this.trusted,
  });

  final String userId;
  final String deviceId;
  final bool trusted;

  @override
  List<Object?> get props => [userId, deviceId, trusted];
}

class GetRoomCryptoInfo extends CryptoEvent {
  const GetRoomCryptoInfo(this.roomId);

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

class EnableRoomEncryption extends CryptoEvent {
  const EnableRoomEncryption(this.roomId);

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

class ExportKeys extends CryptoEvent {
  const ExportKeys({this.password});

  final String? password;

  @override
  List<Object?> get props => [password];
}

class ImportKeys extends CryptoEvent {
  const ImportKeys({
    required this.keyData,
    this.password,
  });

  final String keyData;
  final String? password;

  @override
  List<Object?> get props => [keyData, password];
}

class ResetCrypto extends CryptoEvent {
  const ResetCrypto();
}
