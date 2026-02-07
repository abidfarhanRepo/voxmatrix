# VoxMatrix

A Matrix messaging app built with Flutter and Clean Architecture principles.

## Project Structure

```
lib/
├── core/                   # Core functionality
│   ├── config/            # Dependency injection configuration
│   ├── constants/         # App constants and strings
│   ├── error/             # Error handling (failures, exceptions)
│   ├── theme/             # App themes and colors
│   └── utils/             # Utility functions (logger, validators)
├── domain/                # Domain layer (business logic)
│   ├── entities/          # Business entities
│   ├── repositories/      # Repository interfaces
│   └── usecases/          # Use cases
├── data/                  # Data layer (implementation)
│   ├── datasources/       # Remote and local data sources
│   ├── models/            # Data models
│   └── repositories/      # Repository implementations
└── presentation/          # Presentation layer (UI)
    ├── auth/              # Authentication screens and BLoCs
    ├── chat/              # Chat screens and BLoCs
    ├── rooms/             # Room screens and BLoCs
    ├── settings/          # Settings screens
    ├── widgets/           # Shared widgets
    └── bloc/              # Global BLoCs
```

## Architecture

This project follows Clean Architecture principles with clear separation of concerns:

- **Domain Layer**: Contains business logic, entities, use cases, and repository interfaces
- **Data Layer**: Implements repositories, handles data sources, and contains data models
- **Presentation Layer**: Contains UI components, BLoCs for state management, and navigation

## State Management

The app uses `flutter_bloc` for state management with the following BLoCs:
- `AuthBloc`: Handles authentication state
- `ChatBloc`: Manages chat messages and interactions
- `RoomBloc`: Manages rooms and their states

## Dependencies

### Core Dependencies
- `matrix_sdk_flutter`: Matrix protocol implementation
- `flutter_bloc`: State management
- `get_it` + `injectable`: Dependency injection
- `dartz`: Functional programming (Either type for error handling)
- `equatable`: Value equality

### Code Generation
- `build_runner`: Code generation runner
- `json_serializable`: JSON serialization
- `freezed`: Immutable data classes
- `injectable_generator`: DI code generation

## Getting Started

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Generate code:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Features

- [ ] Authentication (login/logout)
- [ ] Room management
- [ ] Real-time messaging
- [ ] File sharing
- [ ] Typing indicators
- [ ] Read receipts
- [ ] Push notifications
- [ ] End-to-end encryption

## Contributing

This is a template project. Feel free to customize and extend it for your needs.
