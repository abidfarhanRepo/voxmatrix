import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/services/call_state_service.dart';
import 'package:voxmatrix/domain/entities/call.dart';
import 'package:voxmatrix/domain/repositories/call_repository.dart';
import 'package:voxmatrix/presentation/call/bloc/call_event.dart';
import 'package:voxmatrix/presentation/call/bloc/call_state.dart';

@injectable
class CallBloc extends Bloc<CallEvent, CallBlocState> {
  CallBloc(
    this._callRepository,
    this._callStateService,
  ) : super(const CallBlocState()) {
    on<CallInitEvent>(_onInit);
    on<CreateCallEvent>(_onCreateCall);
    on<AnswerCallEvent>(_onAnswerCall);
    on<RejectCallEvent>(_onRejectCall);
    on<HangupCallEvent>(_onHangupCall);
    on<ToggleMuteEvent>(_onToggleMute);
    on<ToggleSpeakerEvent>(_onToggleSpeaker);
    on<ToggleCameraEvent>(_onToggleCamera);
    on<SwitchCameraEvent>(_onSwitchCamera);
    on<CallStateUpdatedEvent>(_onCallBlocStateUpdated);
    on<IncomingCallReceivedEvent>(_onIncomingCallReceived);
  }

  final CallRepository _callRepository;
  final CallStateService _callStateService;
  StreamSubscription? _callStateSubscription;
  StreamSubscription? _incomingCallSubscription;

  Future<void> _onInit(
    CallInitEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    // Initialize call state service
    await _callStateService.initialize();

    final result = await _callRepository.initialize();
    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
      ),
      (_) async {
        _listenToCallStreams();
        
        // Try to restore saved call state
        final savedCall = await _callStateService.restoreCallState();
        
        emit(
          state.copyWith(
            isLoading: false,
            isInitialized: true,
            currentCall: savedCall,
            isActive: savedCall != null,
            isConnected: savedCall?.state == CallState.active,
          ),
        );
      },
    );
  }

  Future<void> _onCreateCall(
    CreateCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await _callRepository.createCall(
      roomId: event.roomId,
      calleeId: event.calleeId,
      isVideoCall: event.isVideoCall,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
      ),
      (call) async {
        // Save call state for recovery
        await _callStateService.saveCallState(call);
        
        emit(
          state.copyWith(
            currentCall: call,
            isLoading: false,
            isActive: true,
            isConnected: call.state == CallState.active,
          ),
        );
      },
    );
  }

  Future<void> _onAnswerCall(
    AnswerCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, incomingCall: null));

    final result = await _callRepository.answerCall(
      callId: event.callId,
      roomId: event.roomId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
          incomingCall: state.incomingCall,
        ),
      ),
      (_) async {
        final activeCall = state.incomingCall?.copyWith(
          state: CallState.connecting,
        );
        
        // Save call state for recovery
        if (activeCall != null) {
          await _callStateService.saveCallState(activeCall);
        }
        
        emit(
          state.copyWith(
            currentCall: activeCall,
            isLoading: false,
            isActive: true,
          ),
        );
      },
    );
  }

  Future<void> _onRejectCall(
    RejectCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _callRepository.rejectCall(
      callId: event.callId,
      roomId: event.roomId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          isLoading: false,
          incomingCall: null,
        ),
      ),
    );
  }

  Future<void> _onHangupCall(
    HangupCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _callRepository.hangupCall(
      callId: event.callId,
      roomId: event.roomId,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
      ),
      (_) async {
        // Clear saved call state
        await _callStateService.clearCallState();
        
        emit(
          state.copyWith(
            isLoading: false,
            currentCall: null,
            isActive: false,
            isConnected: false,
          ),
        );
      },
    );
  }

  Future<void> _onToggleMute(
    ToggleMuteEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    final result = await _callRepository.toggleMute(
      callId: event.callId,
      isMuted: event.isMuted,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(errorMessage: failure.message),
      ),
      (_) => emit(state.copyWith()),
    );
  }

  Future<void> _onToggleSpeaker(
    ToggleSpeakerEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    final result = await _callRepository.toggleSpeaker(
      callId: event.callId,
      isEnabled: event.isEnabled,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(errorMessage: failure.message),
      ),
      (_) => emit(state.copyWith()),
    );
  }

  Future<void> _onToggleCamera(
    ToggleCameraEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    final result = await _callRepository.toggleCamera(
      callId: event.callId,
      isEnabled: event.isEnabled,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(errorMessage: failure.message),
      ),
      (_) => emit(state.copyWith()),
    );
  }

  Future<void> _onSwitchCamera(
    SwitchCameraEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    final result = await _callRepository.switchCamera(
      callId: event.callId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(errorMessage: failure.message),
      ),
      (_) => emit(state.copyWith()),
    );
  }

  void _onCallBlocStateUpdated(
    CallStateUpdatedEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    // Update saved call state when state changes
    await _callStateService.saveCallState(event.call);
    
    emit(
      state.copyWith(
        currentCall: event.call,
        isConnected: event.call.state == CallState.active,
      ),
    );
  }

  void _onIncomingCallReceived(
    IncomingCallReceivedEvent event,
    Emitter<CallBlocState> emit,
  ) {
    emit(
      state.copyWith(incomingCall: event.call),
    );
  }

  void _listenToCallStreams() {
    _callStateSubscription?.cancel();
    _incomingCallSubscription?.cancel();

    _callStateSubscription = _callRepository.callStateStream.listen(
      (call) {
        add(CallStateUpdatedEvent(call));
      },
    );

    _incomingCallSubscription = _callRepository.incomingCallStream.listen(
      (call) {
        add(IncomingCallReceivedEvent(call));
      },
    );
  }

  @override
  Future<void> close() {
    _callStateSubscription?.cancel();
    _incomingCallSubscription?.cancel();
    return super.close();
  }
}
