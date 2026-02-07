import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/config/injection_container.config.dart';
import 'package:voxmatrix/core/services/matrix_client_service.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/data/datasources/auth_remote_datasource.dart';
import 'package:voxmatrix/data/datasources/crypto_local_datasource.dart';
import 'package:voxmatrix/data/datasources/matrix_call_signaling_datasource.dart';
import 'package:voxmatrix/data/datasources/media_remote_datasource.dart';
import 'package:voxmatrix/data/datasources/message_remote_datasource.dart';
import 'package:voxmatrix/data/datasources/room_management_remote_datasource.dart';
import 'package:voxmatrix/data/datasources/room_members_datasource.dart';
import 'package:voxmatrix/data/datasources/room_remote_datasource.dart';
import 'package:voxmatrix/data/datasources/webrtc_datasource.dart';
import 'package:voxmatrix/data/repositories/auth_repository_impl.dart';
import 'package:voxmatrix/data/repositories/call_repository_impl.dart';
import 'package:voxmatrix/domain/repositories/call_repository.dart';
import 'package:voxmatrix/data/repositories/crypto_repository_impl.dart';
import 'package:voxmatrix/domain/repositories/crypto_repository.dart';

final sl = GetIt.instance;

@InjectableInit()
Future<void> init() async {
  await sl.init();
}

// Register core dependencies
@module
abstract class CoreModule {
  @lazySingleton
  Logger get logger => Logger();

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @lazySingleton
  Key get rootKey => UniqueKey();
}

// Register repositories
@module
abstract class RepositoryModule {
  @lazySingleton
  AuthRepositoryImpl authRepository(
    AuthRemoteDataSource remoteDataSource,
    AuthLocalDataSource localDataSource,
  ) =>
      AuthRepositoryImpl(
        localDataSource,
        remoteDataSource,
      );

  @lazySingleton
  CallRepositoryImpl callRepository(
    WebRTCDataSource webrtcDataSource,
    MatrixCallSignalingDataSource signalingDataSource,
    RoomMembersDataSource roomMembersDataSource,
    AuthLocalDataSource authLocalDataSource,
    Logger logger,
  ) =>
      CallRepositoryImpl(
        webrtcDataSource,
        signalingDataSource,
        roomMembersDataSource,
        authLocalDataSource,
        logger,
      );
}

// Register data sources
@module
abstract class DataSourceModule {
  @lazySingleton
  AuthRemoteDataSource authRemoteDataSource(
    Logger logger,
  ) =>
      AuthRemoteDataSource();

  @lazySingleton
  AuthLocalDataSource authLocalDataSource(
    FlutterSecureStorage secureStorage,
  ) =>
      AuthLocalDataSource(secureStorage);

  @lazySingleton
  WebRTCDataSource webrtcDataSource(
    Logger logger,
  ) =>
      WebRTCDataSource(logger: logger);

  // Note: LiveKitDataSource is registered via @injectable annotation in the class
  // Note: MatrixCallSignalingDataSource is registered via @injectable annotation in the class

  // MatrixClientService is registered via @singleton annotation
  // RoomRemoteDataSource is registered via @injectable annotation
}
