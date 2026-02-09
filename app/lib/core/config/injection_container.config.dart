// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter/material.dart' as _i409;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:logger/logger.dart' as _i974;
import 'package:voxmatrix/core/config/injection_container.dart' as _i593;
import 'package:voxmatrix/core/services/call_state_service.dart' as _i55;
import 'package:voxmatrix/core/services/device_verification_service.dart'
    as _i293;
import 'package:voxmatrix/core/services/matrix_client_service.dart' as _i377;
import 'package:voxmatrix/core/services/offline_queue_service.dart' as _i279;
import 'package:voxmatrix/core/services/presence_service.dart' as _i853;
import 'package:voxmatrix/core/services/push_notification_service.dart'
    as _i176;
import 'package:voxmatrix/core/services/typing_service.dart' as _i992;
import 'package:voxmatrix/core/services/upload_progress_service.dart' as _i647;
import 'package:voxmatrix/data/datasources/account_remote_datasource.dart'
    as _i385;
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart' as _i631;
import 'package:voxmatrix/data/datasources/auth_remote_datasource.dart'
    as _i474;
import 'package:voxmatrix/data/datasources/crypto_local_datasource.dart'
    as _i791;
import 'package:voxmatrix/data/datasources/livekit_datasource.dart' as _i721;
import 'package:voxmatrix/data/datasources/matrix_call_signaling_datasource.dart'
    as _i242;
import 'package:voxmatrix/data/datasources/media_remote_datasource.dart'
    as _i59;
import 'package:voxmatrix/data/datasources/media_upload_datasource.dart'
    as _i954;
import 'package:voxmatrix/data/datasources/megolm_session_datasource.dart'
    as _i67;
import 'package:voxmatrix/data/datasources/message_edit_datasource.dart'
    as _i187;
import 'package:voxmatrix/data/datasources/message_remote_datasource.dart'
    as _i267;
import 'package:voxmatrix/data/datasources/olm_account_datasource.dart' as _i14;
import 'package:voxmatrix/data/datasources/olm_session_datasource.dart'
    as _i740;
import 'package:voxmatrix/data/datasources/push_notification_datasource.dart'
    as _i517;
import 'package:voxmatrix/data/datasources/reaction_remote_datasource.dart'
    as _i415;
import 'package:voxmatrix/data/datasources/room_management_remote_datasource.dart'
    as _i376;
import 'package:voxmatrix/data/datasources/room_members_datasource.dart'
    as _i288;
import 'package:voxmatrix/data/datasources/room_remote_datasource.dart'
    as _i633;
import 'package:voxmatrix/data/datasources/search_remote_datasource.dart'
    as _i895;
import 'package:voxmatrix/data/datasources/space_remote_datasource.dart'
    as _i494;
import 'package:voxmatrix/data/datasources/webrtc_datasource.dart' as _i910;
import 'package:voxmatrix/data/repositories/auth_repository_impl.dart' as _i773;
import 'package:voxmatrix/data/repositories/call_repository_impl.dart' as _i942;
import 'package:voxmatrix/data/repositories/chat_repository_impl.dart' as _i459;
import 'package:voxmatrix/data/repositories/crypto_repository_impl.dart'
    as _i784;
import 'package:voxmatrix/data/repositories/profile_repository_impl.dart'
    as _i478;
import 'package:voxmatrix/data/repositories/room_repository_impl.dart' as _i129;
import 'package:voxmatrix/domain/repositories/auth_repository.dart' as _i169;
import 'package:voxmatrix/domain/repositories/call_repository.dart' as _i758;
import 'package:voxmatrix/domain/repositories/chat_repository.dart' as _i80;
import 'package:voxmatrix/domain/repositories/crypto_repository.dart' as _i412;
import 'package:voxmatrix/domain/repositories/profile_repository.dart' as _i646;
import 'package:voxmatrix/domain/repositories/room_repository.dart' as _i688;
import 'package:voxmatrix/domain/usecases/auth/get_current_user_usecase.dart'
    as _i141;
import 'package:voxmatrix/domain/usecases/auth/login_usecase.dart' as _i773;
import 'package:voxmatrix/domain/usecases/auth/logout_usecase.dart' as _i71;
import 'package:voxmatrix/domain/usecases/auth/register_usecase.dart' as _i193;
import 'package:voxmatrix/domain/usecases/call/answer_call_usecase.dart'
    as _i1066;
import 'package:voxmatrix/domain/usecases/call/create_call_usecase.dart'
    as _i537;
import 'package:voxmatrix/domain/usecases/call/hangup_call_usecase.dart'
    as _i724;
import 'package:voxmatrix/domain/usecases/chat/add_reaction_usecase.dart'
    as _i384;
import 'package:voxmatrix/domain/usecases/chat/delete_message_usecase.dart'
    as _i227;
import 'package:voxmatrix/domain/usecases/chat/edit_message_usecase.dart'
    as _i895;
import 'package:voxmatrix/domain/usecases/chat/get_messages_usecase.dart'
    as _i348;
import 'package:voxmatrix/domain/usecases/chat/mark_as_read_usecase.dart'
    as _i764;
import 'package:voxmatrix/domain/usecases/chat/remove_reaction_usecase.dart'
    as _i330;
import 'package:voxmatrix/domain/usecases/chat/send_message_usecase.dart'
    as _i759;
import 'package:voxmatrix/domain/usecases/chat/send_typing_notification_usecase.dart'
    as _i385;
import 'package:voxmatrix/domain/usecases/chat/subscribe_to_messages_usecase.dart'
    as _i804;
import 'package:voxmatrix/domain/usecases/chat/upload_file_usecase.dart'
    as _i183;
import 'package:voxmatrix/domain/usecases/rooms/create_room_usecase.dart'
    as _i376;
import 'package:voxmatrix/domain/usecases/rooms/get_rooms_usecase.dart'
    as _i600;
import 'package:voxmatrix/domain/usecases/rooms/join_room_usecase.dart'
    as _i1003;
import 'package:voxmatrix/domain/usecases/rooms/leave_room_usecase.dart'
    as _i642;
import 'package:voxmatrix/presentation/auth/bloc/auth_bloc.dart' as _i1018;
import 'package:voxmatrix/presentation/call/bloc/call_bloc.dart' as _i331;
import 'package:voxmatrix/presentation/chat/bloc/chat_bloc.dart' as _i887;
import 'package:voxmatrix/presentation/crypto/bloc/crypto_bloc.dart' as _i1015;
import 'package:voxmatrix/presentation/direct_messages/bloc/direct_messages_bloc.dart'
    as _i252;
import 'package:voxmatrix/presentation/profile/bloc/profile_bloc.dart' as _i201;
import 'package:voxmatrix/presentation/room_members/bloc/room_members_bloc.dart'
    as _i798;
import 'package:voxmatrix/presentation/room_settings/bloc/room_settings_bloc.dart'
    as _i1011;
import 'package:voxmatrix/presentation/rooms/bloc/rooms_bloc.dart' as _i139;
import 'package:voxmatrix/presentation/search/bloc/search_bloc.dart' as _i649;
import 'package:voxmatrix/presentation/spaces/bloc/spaces_bloc.dart' as _i427;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final coreModule = _$CoreModule();
    final dataSourceModule = _$DataSourceModule();
    final repositoryModule = _$RepositoryModule();
    gh.lazySingleton<_i974.Logger>(() => coreModule.logger);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
        () => coreModule.secureStorage);
    gh.lazySingleton<_i409.Key>(() => coreModule.rootKey);
    gh.lazySingleton<_i474.AuthRemoteDataSource>(
        () => dataSourceModule.authRemoteDataSource(gh<_i974.Logger>()));
    gh.factory<_i67.MegolmSessionDataSource>(() => _i67.MegolmSessionDataSource(
          gh<_i558.FlutterSecureStorage>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i14.OlmAccountDataSource>(() => _i14.OlmAccountDataSource(
          gh<_i558.FlutterSecureStorage>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i740.OlmSessionDataSource>(() => _i740.OlmSessionDataSource(
          gh<_i558.FlutterSecureStorage>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i721.LiveKitDataSource>(
        () => _i721.LiveKitDataSource(logger: gh<_i974.Logger>()));
    gh.factory<_i910.WebRTCDataSource>(
        () => _i910.WebRTCDataSource(logger: gh<_i974.Logger>()));
    gh.singleton<_i377.MatrixClientService>(
        () => _i377.MatrixClientService(logger: gh<_i974.Logger>()));
    gh.lazySingleton<_i631.AuthLocalDataSource>(() =>
        dataSourceModule.authLocalDataSource(gh<_i558.FlutterSecureStorage>()));
    gh.factory<_i176.PushNotificationService>(
        () => _i176.PushNotificationService(gh<_i974.Logger>()));
    gh.factory<_i954.MediaUploadDataSource>(
        () => _i954.MediaUploadDataSource(gh<_i974.Logger>()));
    gh.factory<_i494.SpaceRemoteDataSource>(
        () => _i494.SpaceRemoteDataSource(gh<_i974.Logger>()));
    gh.factory<_i895.SearchRemoteDataSource>(
        () => _i895.SearchRemoteDataSource(gh<_i974.Logger>()));
    gh.factory<_i59.MediaRemoteDataSource>(
        () => _i59.MediaRemoteDataSource(gh<_i974.Logger>()));
    gh.factory<_i415.ReactionRemoteDataSource>(
        () => _i415.ReactionRemoteDataSource(gh<_i974.Logger>()));
    gh.factory<_i267.MessageRemoteDataSource>(
        () => _i267.MessageRemoteDataSource(gh<_i974.Logger>()));
    gh.factory<_i187.MessageEditDataSource>(
        () => _i187.MessageEditDataSource(gh<_i974.Logger>()));
    gh.factory<_i376.RoomManagementRemoteDataSource>(
        () => _i376.RoomManagementRemoteDataSource(gh<_i974.Logger>()));
    gh.factory<_i288.RoomMembersDataSource>(
        () => _i288.RoomMembersDataSource(gh<_i974.Logger>()));
    gh.factory<_i385.AccountRemoteDataSource>(
        () => _i385.AccountRemoteDataSource(gh<_i974.Logger>()));
    gh.factory<_i517.PushNotificationDataSource>(
        () => _i517.PushNotificationDataSource(gh<_i974.Logger>()));
    gh.factory<_i279.OfflineQueueService>(
        () => _i279.OfflineQueueService(gh<_i974.Logger>()));
    gh.factory<_i55.CallStateService>(
        () => _i55.CallStateService(gh<_i974.Logger>()));
    gh.factory<_i647.UploadProgressService>(
        () => _i647.UploadProgressService(gh<_i974.Logger>()));
    gh.factory<_i853.PresenceService>(() => _i853.PresenceService(
          gh<_i377.MatrixClientService>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i992.TypingService>(() => _i992.TypingService(
          gh<_i377.MatrixClientService>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i798.RoomMembersBloc>(() => _i798.RoomMembersBloc(
          gh<_i288.RoomMembersDataSource>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i293.DeviceVerificationService>(
        () => _i293.DeviceVerificationService(gh<_i377.MatrixClientService>()));
    gh.lazySingleton<_i80.ChatRepository>(() => _i459.ChatRepositoryImpl(
          gh<_i267.MessageRemoteDataSource>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i377.MatrixClientService>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i427.SpacesBloc>(() => _i427.SpacesBloc(
          gh<_i494.SpaceRemoteDataSource>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i974.Logger>(),
        ));
    gh.lazySingleton<_i773.AuthRepositoryImpl>(
        () => repositoryModule.authRepository(
              gh<_i474.AuthRemoteDataSource>(),
              gh<_i631.AuthLocalDataSource>(),
            ));
    gh.factory<_i385.SendTypingNotificationUseCase>(
        () => _i385.SendTypingNotificationUseCase(gh<_i80.ChatRepository>()));
    gh.factory<_i759.SendMessageUseCase>(
        () => _i759.SendMessageUseCase(gh<_i80.ChatRepository>()));
    gh.factory<_i384.AddReactionUseCase>(
        () => _i384.AddReactionUseCase(gh<_i80.ChatRepository>()));
    gh.factory<_i183.UploadFileUseCase>(
        () => _i183.UploadFileUseCase(gh<_i80.ChatRepository>()));
    gh.factory<_i348.GetMessagesUseCase>(
        () => _i348.GetMessagesUseCase(gh<_i80.ChatRepository>()));
    gh.factory<_i330.RemoveReactionUseCase>(
        () => _i330.RemoveReactionUseCase(gh<_i80.ChatRepository>()));
    gh.factory<_i895.EditMessageUseCase>(
        () => _i895.EditMessageUseCase(gh<_i80.ChatRepository>()));
    gh.factory<_i804.SubscribeToMessagesUseCase>(
        () => _i804.SubscribeToMessagesUseCase(gh<_i80.ChatRepository>()));
    gh.factory<_i227.DeleteMessageUseCase>(
        () => _i227.DeleteMessageUseCase(gh<_i80.ChatRepository>()));
    gh.lazySingleton<_i764.MarkAsReadUseCase>(
        () => _i764.MarkAsReadUseCase(gh<_i80.ChatRepository>()));
    gh.factory<_i1011.RoomSettingsBloc>(() => _i1011.RoomSettingsBloc(
          gh<_i376.RoomManagementRemoteDataSource>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i974.Logger>(),
        ));
    gh.lazySingleton<_i169.AuthRepository>(() => _i773.AuthRepositoryImpl(
          gh<_i631.AuthLocalDataSource>(),
          gh<_i474.AuthRemoteDataSource>(),
        ));
    gh.lazySingleton<_i646.ProfileRepository>(() => _i478.ProfileRepositoryImpl(
          gh<_i385.AccountRemoteDataSource>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i242.MatrixCallSignalingDataSource>(
        () => _i242.MatrixCallSignalingDataSource(
              gh<_i631.AuthLocalDataSource>(),
              gh<_i974.Logger>(),
            ));
    gh.factory<_i791.CryptoLocalDataSource>(() => _i791.CryptoLocalDataSource(
          gh<_i558.FlutterSecureStorage>(),
          gh<_i14.OlmAccountDataSource>(),
          gh<_i740.OlmSessionDataSource>(),
          gh<_i67.MegolmSessionDataSource>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i633.RoomRemoteDataSource>(() => _i633.RoomRemoteDataSource(
          gh<_i974.Logger>(),
          gh<_i377.MatrixClientService>(),
        ));
    gh.lazySingleton<_i942.CallRepositoryImpl>(
        () => repositoryModule.callRepository(
              gh<_i910.WebRTCDataSource>(),
              gh<_i242.MatrixCallSignalingDataSource>(),
              gh<_i288.RoomMembersDataSource>(),
              gh<_i631.AuthLocalDataSource>(),
              gh<_i974.Logger>(),
            ));
    gh.factory<_i887.ChatBloc>(() => _i887.ChatBloc(
          gh<_i348.GetMessagesUseCase>(),
          gh<_i759.SendMessageUseCase>(),
          gh<_i183.UploadFileUseCase>(),
          gh<_i384.AddReactionUseCase>(),
          gh<_i330.RemoveReactionUseCase>(),
          gh<_i895.EditMessageUseCase>(),
          gh<_i227.DeleteMessageUseCase>(),
          gh<_i804.SubscribeToMessagesUseCase>(),
          gh<_i764.MarkAsReadUseCase>(),
          gh<_i377.MatrixClientService>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i992.TypingService>(),
          gh<_i279.OfflineQueueService>(),
          gh<_i647.UploadProgressService>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i252.DirectMessagesBloc>(() => _i252.DirectMessagesBloc(
          gh<_i376.RoomManagementRemoteDataSource>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i633.RoomRemoteDataSource>(),
          gh<_i377.MatrixClientService>(),
          gh<_i974.Logger>(),
        ));
    gh.lazySingleton<_i412.CryptoRepository>(() => _i784.CryptoRepositoryImpl(
          gh<_i791.CryptoLocalDataSource>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i633.RoomRemoteDataSource>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i201.ProfileBloc>(() => _i201.ProfileBloc(
          gh<_i646.ProfileRepository>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i773.LoginUseCase>(
        () => _i773.LoginUseCase(gh<_i169.AuthRepository>()));
    gh.factory<_i141.GetCurrentUserUseCase>(
        () => _i141.GetCurrentUserUseCase(gh<_i169.AuthRepository>()));
    gh.factory<_i71.LogoutUseCase>(
        () => _i71.LogoutUseCase(gh<_i169.AuthRepository>()));
    gh.factory<_i193.RegisterUseCase>(
        () => _i193.RegisterUseCase(gh<_i169.AuthRepository>()));
    gh.lazySingleton<_i688.RoomRepository>(() => _i129.RoomRepositoryImpl(
          gh<_i633.RoomRemoteDataSource>(),
          gh<_i376.RoomManagementRemoteDataSource>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i974.Logger>(),
        ));
    gh.lazySingleton<_i758.CallRepository>(() => _i942.CallRepositoryImpl(
          gh<_i910.WebRTCDataSource>(),
          gh<_i242.MatrixCallSignalingDataSource>(),
          gh<_i288.RoomMembersDataSource>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i537.CreateCallUseCase>(
        () => _i537.CreateCallUseCase(gh<_i758.CallRepository>()));
    gh.factory<_i724.HangupCallUseCase>(
        () => _i724.HangupCallUseCase(gh<_i758.CallRepository>()));
    gh.factory<_i1066.AnswerCallUseCase>(
        () => _i1066.AnswerCallUseCase(gh<_i758.CallRepository>()));
    gh.factory<_i1015.CryptoBloc>(() => _i1015.CryptoBloc(
          gh<_i791.CryptoLocalDataSource>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i377.MatrixClientService>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i600.GetRoomsUseCase>(
        () => _i600.GetRoomsUseCase(gh<_i688.RoomRepository>()));
    gh.factory<_i1003.JoinRoomUseCase>(
        () => _i1003.JoinRoomUseCase(gh<_i688.RoomRepository>()));
    gh.factory<_i642.LeaveRoomUseCase>(
        () => _i642.LeaveRoomUseCase(gh<_i688.RoomRepository>()));
    gh.factory<_i376.CreateRoomUseCase>(
        () => _i376.CreateRoomUseCase(gh<_i688.RoomRepository>()));
    gh.factory<_i1018.AuthBloc>(() => _i1018.AuthBloc(
          gh<_i773.LoginUseCase>(),
          gh<_i71.LogoutUseCase>(),
          gh<_i141.GetCurrentUserUseCase>(),
          gh<_i193.RegisterUseCase>(),
          gh<_i377.MatrixClientService>(),
          gh<_i631.AuthLocalDataSource>(),
        ));
    gh.factory<_i649.SearchBloc>(() => _i649.SearchBloc(
          gh<_i895.SearchRemoteDataSource>(),
          gh<_i688.RoomRepository>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i974.Logger>(),
        ));
    gh.factory<_i331.CallBloc>(() => _i331.CallBloc(
          gh<_i758.CallRepository>(),
          gh<_i55.CallStateService>(),
        ));
    gh.factory<_i139.RoomsBloc>(() => _i139.RoomsBloc(
          gh<_i600.GetRoomsUseCase>(),
          gh<_i376.CreateRoomUseCase>(),
          gh<_i1003.JoinRoomUseCase>(),
          gh<_i642.LeaveRoomUseCase>(),
          gh<_i377.MatrixClientService>(),
          gh<_i631.AuthLocalDataSource>(),
          gh<_i974.Logger>(),
        ));
    return this;
  }
}

class _$CoreModule extends _i593.CoreModule {}

class _$DataSourceModule extends _i593.DataSourceModule {}

class _$RepositoryModule extends _i593.RepositoryModule {}
