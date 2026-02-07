import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class LoginRequested extends AuthEvent {
  const LoginRequested({
    required this.username,
    required this.password,
    required this.homeserver,
  });

  final String username;
  final String password;
  final String homeserver;

  @override
  List<Object> get props => [username, password, homeserver];
}

class RegisterRequested extends AuthEvent {
  const RegisterRequested({
    required this.username,
    required this.password,
    required this.email,
    required this.homeserver,
  });

  final String username;
  final String password;
  final String email;
  final String homeserver;

  @override
  List<Object> get props => [username, password, email, homeserver];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}
