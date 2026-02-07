import 'package:equatable/equatable.dart';
import 'package:voxmatrix/domain/entities/call.dart';

class CallBlocState extends Equatable {
  const CallBlocState({
    this.currentCall,
    this.incomingCall,
    this.isActive = false,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
    this.isConnected = false,
  });

  final CallEntity? currentCall;
  final CallEntity? incomingCall;
  final bool isActive;
  final bool isLoading;
  final bool isInitialized;
  final bool isConnected;
  final String? errorMessage;

  CallBlocState copyWith({
    CallEntity? currentCall,
    CallEntity? incomingCall,
    bool? isActive,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    bool? isConnected,
  }) {
    return CallBlocState(
      currentCall: currentCall ?? this.currentCall,
      incomingCall: incomingCall ?? this.incomingCall,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage ?? this.errorMessage,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  List<Object?> get props {
    return [
      currentCall,
      incomingCall,
      isActive,
      isLoading,
      isInitialized,
      errorMessage,
      isConnected,
    ];
  }
}

class CallInitial extends CallBlocState {
  const CallInitial() : super();
}

class CallLoading extends CallBlocState {
  const CallLoading() : super(isLoading: true);
}

class CallIncoming extends CallBlocState {
  const CallIncoming({required CallEntity call})
      : super(incomingCall: call, isLoading: false);
}

class CallActive extends CallBlocState {
  const CallActive({required CallEntity call})
      : super(currentCall: call, isActive: true, isConnected: true);
}

class CallEnded extends CallBlocState {
  const CallEnded() : super();
}

class CallError extends CallBlocState {
  const CallError({required String message})
      : super(errorMessage: message, isLoading: false);
}
