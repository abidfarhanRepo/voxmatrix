import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'core/config/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'domain/entities/call.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/auth/bloc/auth_event.dart';
import 'presentation/auth/bloc/auth_state.dart';
import 'presentation/auth/pages/login_page.dart';
import 'presentation/call/bloc/call_bloc.dart';
import 'presentation/call/call_page.dart';
import 'presentation/chat/bloc/chat_bloc.dart';
import 'presentation/chat/chat_page.dart';
import 'presentation/crypto/bloc/crypto_bloc.dart';
import 'presentation/home/home_page.dart';
import 'presentation/profile/bloc/profile_bloc.dart';
import 'presentation/room_members/bloc/room_members_bloc.dart';
import 'presentation/room_members/room_members_page.dart';
import 'presentation/room_settings/bloc/room_settings_bloc.dart';
import 'presentation/room_settings/room_settings_page.dart';
import 'presentation/direct_messages/bloc/direct_messages_bloc.dart';
import 'presentation/direct_messages/direct_messages_page.dart';
import 'presentation/rooms/bloc/rooms_bloc.dart';
import 'presentation/rooms/rooms_page.dart';
import 'presentation/search/bloc/search_bloc.dart';
import 'presentation/spaces/bloc/spaces_bloc.dart';
import 'presentation/spaces/spaces_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure Hive (local storage) is initialized before any services use it.
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);
  } catch (e) {
    // If Hive initialization fails, log to console; DI init or services may still
    // try to initialize boxes, but this prevents the app from throwing the
    // HiveError seen in logs when boxes are opened before init.
    // Keep this lightweight to avoid bringing in additional logging deps here.
    // ignore: avoid_print
    print('Warning: Failed to initialize Hive: $e');
  }

  // Configure System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize dependency injection
  await di.init();

  runApp(const VoxMatrixApp());
}

class VoxMatrixApp extends StatelessWidget {
  const VoxMatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<AuthBloc>()..add(AuthStarted())),
        BlocProvider(create: (context) => di.sl<RoomsBloc>()),
        BlocProvider(create: (context) => di.sl<ChatBloc>()),
        BlocProvider(create: (context) => di.sl<RoomMembersBloc>()),
        BlocProvider(create: (context) => di.sl<RoomSettingsBloc>()),
        BlocProvider(create: (context) => di.sl<DirectMessagesBloc>()),
        BlocProvider(create: (context) => di.sl<SearchBloc>()),
        BlocProvider(create: (context) => di.sl<SpacesBloc>()),
        BlocProvider(create: (context) => di.sl<CryptoBloc>()),
        BlocProvider(create: (context) => di.sl<ProfileBloc>()),
        BlocProvider(create: (context) => di.sl<CallBloc>()),
      ],
      child: MaterialApp(
        title: 'VoxMatrix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Default to dark mode
        home: const AuthWrapper(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage());
            case '/home':
              return MaterialPageRoute(builder: (_) => const HomePage());
            case '/rooms':
              return MaterialPageRoute(builder: (_) => const RoomsPage());
            case '/spaces':
              return MaterialPageRoute(builder: (_) => const SpacesPage());
            case '/members':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => RoomMembersPage(
                  roomId: args?['roomId'] ?? '',
                  roomName: args?['roomName'] ?? 'Room',
                  canKick: args?['canKick'] ?? false,
                  canBan: args?['canBan'] ?? false,
                  canInvite: args?['canInvite'] ?? false,
                ),
              );
            case '/settings':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => RoomSettingsPage(
                  roomId: args?['roomId'] ?? '',
                  roomName: args?['roomName'] ?? 'Room',
                ),
              );
            case '/direct-messages':
              return MaterialPageRoute(builder: (_) => const DirectMessagesPage());
            case '/chat':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => ChatPage(
                  roomId: args?['roomId'] ?? '',
                  roomName: args?['roomName'] ?? 'Chat',
                  isDirect: args?['isDirect'] ?? false,
                ),
              );
            case '/call':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => CallPage(
                  call: args?['call'] as CallEntity?,
                ),
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const AuthWrapper(),
              );
          }
        },
      ),
    );
  }
}


/// Widget that wraps the app and handles authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const HomePage();
        } else if (state is AuthUnauthenticated || state is AuthError) {
          return const LoginPage();
        } else if (state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return const LoginPage();
      },
    );
  }
}
