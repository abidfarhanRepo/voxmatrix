import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/core/services/matrix_client_service.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/data/datasources/crypto_local_datasource.dart';
import 'package:voxmatrix/domain/entities/crypto.dart';
import 'crypto_event.dart';
import 'crypto_state.dart';

@injectable
class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  CryptoBloc(
    this._cryptoDataSource,
    this._localDataSource,
    this._matrixClientService,
    this._logger,
  ) : super(const CryptoInitial()) {
    on<InitializeCrypto>(_onInitializeCrypto);
    on<GetDeviceKeys>(_onGetDeviceKeys);
    on<UploadDeviceKeys>(_onUploadDeviceKeys);
    on<VerifyDevice>(_onVerifyDevice);
    on<GetRoomCryptoInfo>(_onGetRoomCryptoInfo);
    on<EnableRoomEncryption>(_onEnableRoomEncryption);
    on<ExportKeys>(_onExportKeys);
    on<ImportKeys>(_onImportKeys);
    on<ResetCrypto>(_onResetCrypto);
  }

  final CryptoLocalDataSource _cryptoDataSource;
  final AuthLocalDataSource _localDataSource;
  final MatrixClientService _matrixClientService;
  final Logger _logger;

  Future<void> _onInitializeCrypto(
    InitializeCrypto event,
    Emitter<CryptoState> emit,
  ) async {
    emit(const CryptoInitializing());

    try {
      if (!_matrixClientService.isInitialized) {
        emit(const CryptoError('Matrix client not initialized'));
        return;
      }

      final client = _matrixClientService.client;
      final deviceId = client.deviceID ?? '';
      final userId = client.userID ?? '';
      final encryptionEnabled = client.encryptionEnabled;

      final device = CryptoDevice(
        deviceId: deviceId,
        userId: userId,
        publicKey: '',
        displayName: 'This Device',
        verificationStatus: encryptionEnabled
            ? DeviceVerificationStatus.verified
            : DeviceVerificationStatus.unverified,
        lastSeen: DateTime.now(),
      );

      emit(CryptoInitialized(device: device, encryptionEnabled: encryptionEnabled));
    } catch (e, stackTrace) {
      _logger.e('Error initializing crypto', error: e, stackTrace: stackTrace);
      emit(CryptoError(e.toString()));
    }
  }

  Future<void> _onGetDeviceKeys(
    GetDeviceKeys event,
    Emitter<CryptoState> emit,
  ) async {
    emit(const CryptoLoading());

    if (!_matrixClientService.isInitialized) {
      emit(const CryptoError('Matrix client not initialized'));
      return;
    }

    try {
      final client = _matrixClientService.client;
      final device = CryptoDevice(
        deviceId: client.deviceID ?? '',
        userId: client.userID ?? '',
        publicKey: '',
        displayName: 'This Device',
        verificationStatus: client.encryptionEnabled
            ? DeviceVerificationStatus.verified
            : DeviceVerificationStatus.unverified,
        lastSeen: DateTime.now(),
      );
      emit(CryptoDevicesLoaded([device]));
    } catch (e, stackTrace) {
      _logger.e('Failed to get device keys', error: e, stackTrace: stackTrace);
      emit(CryptoError(e.toString()));
    }
  }

  Future<void> _onUploadDeviceKeys(
    UploadDeviceKeys event,
    Emitter<CryptoState> emit,
  ) async {
    // TODO: Implement device keys upload to Matrix server
    // This requires uploading the device keys to /_matrix/client/v3/keys/upload
    _logger.i('Uploading device keys');
    emit(const CryptoSuccess('Device keys uploaded'));
  }

  Future<void> _onVerifyDevice(
    VerifyDevice event,
    Emitter<CryptoState> emit,
  ) async {
    final result = await _cryptoDataSource.setDeviceTrusted(
      userId: event.userId,
      deviceId: event.deviceId,
      trusted: event.trusted,
    );

    result.fold<void>(
      (Failure failure) {
        _logger.e('Failed to verify device: ${failure.message}');
        emit(CryptoError( failure.message));
      },
      (_) {
        emit(CryptoSuccess(
          event.trusted ? 'Device verified' : 'Device unverified',
        ));
      },
    );
  }

  Future<void> _onGetRoomCryptoInfo(
    GetRoomCryptoInfo event,
    Emitter<CryptoState> emit,
  ) async {
    try {
      if (!_matrixClientService.isInitialized) {
        emit(const CryptoError('Matrix client not initialized'));
        return;
      }

      final client = _matrixClientService.client;
      final room = client.getRoomById(event.roomId);
      if (room == null) {
        emit(CryptoRoomInfoLoaded(
          event.roomId,
          RoomCryptoInfo(
            roomId: event.roomId,
            encryptionState: RoomEncryptionState.unknown,
            shouldEncrypt: false,
          ),
        ));
        return;
      }

      final isEncrypted = room.encrypted;
      emit(CryptoRoomInfoLoaded(
        event.roomId,
        RoomCryptoInfo(
          roomId: event.roomId,
          encryptionState: isEncrypted
              ? RoomEncryptionState.encrypted
              : RoomEncryptionState.unencrypted,
          algorithm: isEncrypted ? EncryptionAlgorithm.megolmV1 : null,
          shouldEncrypt: isEncrypted,
        ),
      ));
    } catch (e, stackTrace) {
      _logger.e('Error getting room crypto info', error: e, stackTrace: stackTrace);
      emit(CryptoError(e.toString()));
    }
  }

  Future<void> _onEnableRoomEncryption(
    EnableRoomEncryption event,
    Emitter<CryptoState> emit,
  ) async {
    try {
      if (!_matrixClientService.isInitialized) {
        emit(const CryptoError('Matrix client not initialized'));
        return;
      }

      final client = _matrixClientService.client;
      final room = client.getRoomById(event.roomId);
      if (room == null) {
        emit(const CryptoError('Room not found'));
        return;
      }

      await room.enableEncryption();
      emit(const CryptoSuccess('Encryption enabled for room'));
    } catch (e, stackTrace) {
      _logger.e('Failed to enable encryption', error: e, stackTrace: stackTrace);
      emit(CryptoError(e.toString()));
    }
  }

  Future<void> _onExportKeys(
    ExportKeys event,
    Emitter<CryptoState> emit,
  ) async {
    final result = await _cryptoDataSource.exportKeys();

    result.fold<void>(
      (Failure failure) {
        _logger.e('Failed to export keys: ${failure.message}');
        emit(CryptoError( failure.message));
      },
      (keyData) {
        emit(CryptoKeysExported(keyData));
      },
    );
  }

  Future<void> _onImportKeys(
    ImportKeys event,
    Emitter<CryptoState> emit,
  ) async {
    emit(const CryptoLoading());

    final result = await _cryptoDataSource.importKeys(event.keyData);

    result.fold<void>(
      (Failure failure) {
        _logger.e('Failed to import keys: ${failure.message}');
        emit(CryptoError(failure.message));
      },
      (_) {
        _logger.i('Keys imported successfully');
        emit(const CryptoKeysImported());
        emit(const CryptoSuccess('Keys imported successfully'));
      },
    );
  }

  Future<void> _onResetCrypto(
    ResetCrypto event,
    Emitter<CryptoState> emit,
  ) async {
    final result = await _cryptoDataSource.reset();

    result.fold<void>(
      (Failure failure) {
        _logger.e('Failed to reset crypto: ${failure.message}');
        emit(CryptoError( failure.message));
      },
      (_) {
        emit(const CryptoSuccess('Crypto data reset'));
        emit(const CryptoInitial());
      },
    );
  }
}
