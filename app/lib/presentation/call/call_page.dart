import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:voxmatrix/domain/entities/call.dart' as entities;
import 'package:voxmatrix/presentation/call/bloc/call_bloc.dart';
import 'package:voxmatrix/presentation/call/bloc/call_event.dart';
import 'package:voxmatrix/presentation/call/bloc/call_state.dart';
import 'package:voxmatrix/presentation/call/widgets/call_controls.dart';

class CallPage extends StatefulWidget {
  const CallPage({
    super.key,
    this.call,
  });

  final entities.CallEntity? call;

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  Timer? _callDurationTimer;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _setOrientationToPortrait();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.call != null && widget.call!.state == entities.CallState.outgoing) {
      _startCallDurationTimer();
    }
  }

  Future<void> _initializeRenderers() async {
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
    await _localRenderer!.initialize();
    await _remoteRenderer!.initialize();
    setState(() {});
  }

  void _setOrientationToPortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _startCallDurationTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration = Duration(seconds: timer.tick);
        });
      }
    });
  }

  void _stopCallDurationTimer() {
    _callDurationTimer?.cancel();
  }

  @override
  void dispose() {
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    _stopCallDurationTimer();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallBloc, CallBlocState>(
      listener: (context, state) {
        if (state.currentCall != null) {
          _updateRenderers(state.currentCall!);

          if (state.currentCall!.state == entities.CallState.active) {
            _startCallDurationTimer();
          }
        }

        if (state.currentCall == null && state.isActive == false) {
          Navigator.of(context).pop();
        }

        if (state.errorMessage != null) {
          _showErrorSnackBar(context, state.errorMessage!);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<CallBloc, CallBlocState>(
          builder: (context, state) {
            return state.currentCall == null
                ? _buildLoading()
                : _buildCallContent(context);
          },
        ),
      ),
    );
  }

  void _updateRenderers(entities.CallEntity call) {
    if (call.localStream != null && _localRenderer != null) {
      _localRenderer!.srcObject = call.localStream;
    }
    if (call.remoteStream != null && _remoteRenderer != null) {
      _remoteRenderer!.srcObject = call.remoteStream;
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildCallContent(BuildContext context) {
    final call = context.watch<CallBloc>().state.currentCall;
    if (call == null) return const SizedBox();

    return Stack(
      children: [
        _buildVideoContent(call),
        _buildOverlayContent(context, call),
      ],
    );
  }

  Widget _buildVideoContent(entities.CallEntity call) {
    if (call.isVideoCall) {
      return Positioned.fill(
        child: Stack(
          children: [
            _buildRemoteVideo(),
            _buildLocalVideo(),
          ],
        ),
      );
    }
    return _buildVoiceCallBackground(call);
  }

  Widget _buildRemoteVideo() {
    return Positioned.fill(
      child: _remoteRenderer != null
          ? RTCVideoView(_remoteRenderer!)
          : Container(
              color: Colors.grey.shade900,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
    );
  }

  Widget _buildLocalVideo() {
    if (_localRenderer == null) return const SizedBox();

    return Positioned(
      right: 16,
      top: 60,
      child: Container(
        width: 100,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: RTCVideoView(_localRenderer!),
      ),
    );
  }

  Widget _buildVoiceCallBackground(entities.CallEntity call) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
              Colors.black87,
            ],
          ),
        ),
        child: Center(
          child: _buildCallerAvatar(call),
        ),
      ),
    );
  }

  Widget _buildCallerAvatar(entities.CallEntity call) {
    final name = call.state == entities.CallState.outgoing
        ? (call.calleeName ?? 'Unknown')
        : call.callerName;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayContent(BuildContext context, entities.CallEntity call) {
    return Column(
      children: [
        _buildTopBar(call),
        const Spacer(),
        _buildBottomControls(context, call),
      ],
    );
  }

  Widget _buildTopBar(entities.CallEntity call) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildCallStatusChip(call),
            const Spacer(),
            _buildDurationChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildCallStatusChip(entities.CallEntity call) {
    String status;
    Color color;

    switch (call.state) {
      case entities.CallState.outgoing:
        status = 'Calling...';
        color = Colors.orange;
        break;
      case entities.CallState.connecting:
        status = 'Connecting...';
        color = Colors.blue;
        break;
      case entities.CallState.active:
        status = 'Connected';
        color = Colors.green;
        break;
      case entities.CallState.ended:
        status = 'Ended';
        color = Colors.grey;
        break;
      case entities.CallState.failed:
        status = 'Failed';
        color = Colors.red;
        break;
      default:
        status = 'Calling...';
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (call.state == entities.CallState.outgoing ||
              call.state == entities.CallState.connecting)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Icon(
              call.state == entities.CallState.active ? Icons.check_circle : Icons.info,
              size: 16,
              color: color,
            ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip() {
    final minutes = _callDuration.inMinutes.toString().padLeft(2, '0');
    final seconds = (_callDuration.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$minutes:$seconds',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, entities.CallEntity call) {
    if (call.state == entities.CallState.outgoing || call.state == entities.CallState.connecting) {
      return OutgoingCallControls(
        onCancel: () => _handleHangup(context, call),
        callState: call.state,
      );
    }

    return CallControls(
      callState: call.state,
      isMuted: call.isMuted,
      isSpeakerEnabled: call.isSpeakerEnabled,
      isCameraEnabled: call.isCameraEnabled,
      showCameraControls: call.isVideoCall,
      onToggleMute: () => _handleToggleMute(context, call),
      onToggleSpeaker: () => _handleToggleSpeaker(context, call),
      onToggleCamera: () => _handleToggleCamera(context, call),
      onSwitchCamera: () => _handleSwitchCamera(context, call),
      onHangup: () => _handleHangup(context, call),
    );
  }

  void _handleToggleMute(BuildContext context, entities.CallEntity call) {
    context.read<CallBloc>().add(
          ToggleMuteEvent(
            callId: call.callId,
            isMuted: !call.isMuted,
          ),
        );
  }

  void _handleToggleSpeaker(BuildContext context, entities.CallEntity call) {
    context.read<CallBloc>().add(
          ToggleSpeakerEvent(
            callId: call.callId,
            isEnabled: !call.isSpeakerEnabled,
          ),
        );
  }

  void _handleToggleCamera(BuildContext context, entities.CallEntity call) {
    context.read<CallBloc>().add(
          ToggleCameraEvent(
            callId: call.callId,
            isEnabled: !call.isCameraEnabled,
          ),
        );
  }

  void _handleSwitchCamera(BuildContext context, entities.CallEntity call) {
    context.read<CallBloc>().add(
          SwitchCameraEvent(callId: call.callId),
        );
  }

  void _handleHangup(BuildContext context, entities.CallEntity call) {
    context.read<CallBloc>().add(
          HangupCallEvent(
            callId: call.callId,
            roomId: call.roomId,
            reason: 'User ended call',
          ),
    );
    Navigator.of(context).pop();
  }
}
