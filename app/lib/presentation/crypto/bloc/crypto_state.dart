import 'package:equatable/equatable.dart';
import 'package:voxmatrix/domain/entities/crypto.dart';

abstract class CryptoState extends Equatable {
  const CryptoState();

  @override
  List<Object?> get props => [];
}

class CryptoInitial extends CryptoState {
  const CryptoInitial();
}

class CryptoInitializing extends CryptoState {
  const CryptoInitializing();
}

class CryptoInitialized extends CryptoState {
  const CryptoInitialized({
    this.device,
    this.encryptionEnabled = true,
  });

  final CryptoDevice? device;
  final bool encryptionEnabled;

  @override
  List<Object?> get props => [device, encryptionEnabled];
}

class CryptoLoading extends CryptoState {
  const CryptoLoading();
}

class CryptoDevicesLoaded extends CryptoState {
  const CryptoDevicesLoaded(this.devices);

  final List<CryptoDevice> devices;

  @override
  List<Object?> get props => [devices];
}

class CryptoRoomInfoLoaded extends CryptoState {
  const CryptoRoomInfoLoaded(this.roomId, this.info);

  final String roomId;
  final RoomCryptoInfo info;

  @override
  List<Object?> get props => [roomId, info];
}

class CryptoSuccess extends CryptoState {
  const CryptoSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class CryptoError extends CryptoState {
  const CryptoError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Success state with message
class CryptoSuccessMessage extends CryptoState {
  const CryptoSuccessMessage(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class CryptoKeysExported extends CryptoState {
  const CryptoKeysExported(this.keys);

  final String keys;

  @override
  List<Object?> get props => [keys];
}

class CryptoKeysImported extends CryptoState {
  const CryptoKeysImported();
}
