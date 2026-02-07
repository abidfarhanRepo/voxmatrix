import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/core/constants/app_strings.dart';
import 'package:voxmatrix/core/services/matrix_client_service.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/domain/entities/user_entity.dart';
import 'package:voxmatrix/domain/usecases/auth/login_usecase.dart';
import 'package:voxmatrix/domain/usecases/auth/logout_usecase.dart';
import 'package:voxmatrix/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:voxmatrix/domain/usecases/auth/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._loginUseCase,
    this._logoutUseCase,
    this._getCurrentUserUseCase,
    this._registerUseCase,
    this._matrixClientService,
    this._authLocalDataSource,
  ) : super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onAuthCheckRequested);
  }

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final RegisterUseCase _registerUseCase;
  final MatrixClientService _matrixClientService;
  final AuthLocalDataSource _authLocalDataSource;

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Get current user quickly - without Matrix SDK initialization
      Either<Failure, UserEntity> result;
      try {
        result = await _getCurrentUserUseCase().timeout(
          const Duration(seconds: 3),
        );
      } on TimeoutException {
        result = Left(AuthFailure(message: 'Timeout getting user', statusCode: 408));
      }

      // Handle the result - emit immediately without blocking on Matrix SDK
      if (result.isRight()) {
        final user = result.getOrElse(() => const UserEntity(
          id: '',
          username: '',
          displayName: '',
        ));

        // Emit authenticated state immediately - don't block on Matrix SDK
        emit(AuthAuthenticated(user));

        // Initialize Matrix SDK in background after emitting auth state
        _initializeMatrixInBackground();
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      print('AuthStarted error: $e');
      emit(const AuthUnauthenticated());
    }
  }

  /// Initialize Matrix SDK in background without blocking UI
  Future<void> _initializeMatrixInBackground() async {
    try {
      final accessToken = await _authLocalDataSource.getAccessToken();
      final homeserver = await _authLocalDataSource.getHomeserver();
      final userId = await _authLocalDataSource.getUserId();
      final deviceId = await _authLocalDataSource.getDeviceId();

      if (accessToken != null && homeserver != null && userId != null && userId.isNotEmpty) {
        try {
          await _matrixClientService.initialize(
            homeserver: homeserver,
            accessToken: accessToken,
            userId: userId,
            deviceId: deviceId,
          ).timeout(
            const Duration(seconds: 15),
          );
          // Sync is started automatically by initialize()
        } catch (e) {
          print('Background Matrix SDK init failed: $e');
        }
      }
    } catch (e) {
      print('Error getting credentials for Matrix SDK init: $e');
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      Either<Failure, UserEntity> result;
      try {
        result = await _loginUseCase(
          username: event.username,
          password: event.password,
          homeserver: event.homeserver,
        ).timeout(
          const Duration(seconds: 30),
        );
      } on TimeoutException {
        result = Left(ServerFailure(message: 'Login timeout', statusCode: 408));
      }

      // Handle the result properly
      if (result.isRight()) {
        final user = result.getOrElse(() => const UserEntity(
          id: '',
          username: '',
          displayName: '',
        ));

        // Emit authenticated immediately - don't wait for Matrix SDK
        emit(AuthAuthenticated(user));

        // Initialize Matrix SDK in background
        _initializeMatrixInBackground();
      } else {
        final failure = result.swap().getOrElse(() => ServerFailure(message: 'Unknown error'));
        emit(AuthError(_mapFailureToMessage(failure)));
      }
    } catch (e) {
      print('Login error: $e');
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      Either<Failure, UserEntity> result;
      try {
        result = await _registerUseCase(
          username: event.username,
          password: event.password,
          email: event.email,
          homeserver: event.homeserver,
        ).timeout(
          const Duration(seconds: 30),
        );
      } on TimeoutException {
        result = Left(ServerFailure(message: 'Registration timeout', statusCode: 408));
      }

      // Handle the result properly
      if (result.isRight()) {
        final user = result.getOrElse(() => const UserEntity(
          id: '',
          username: '',
          displayName: '',
        ));

        // Emit authenticated immediately - don't wait for Matrix SDK
        emit(AuthAuthenticated(user));

        // Initialize Matrix SDK in background
        _initializeMatrixInBackground();
      } else {
        final failure = result.swap().getOrElse(() => ServerFailure(message: 'Unknown error'));
        emit(AuthError(_mapFailureToMessage(failure)));
      }
    } catch (e) {
      print('Registration error: $e');
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _logoutUseCase();
    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _getCurrentUserUseCase();
    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return AppStrings.errorNetwork;
      case NetworkFailure:
        return AppStrings.errorNetwork;
      case AuthFailure:
        return AppStrings.errorAuth;
      case ValidationFailure:
        return failure.message;
      default:
        return AppStrings.errorGeneric;
    }
  }
}
