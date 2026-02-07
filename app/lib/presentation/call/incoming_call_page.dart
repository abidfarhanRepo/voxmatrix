import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voxmatrix/domain/entities/call.dart';
import 'package:voxmatrix/presentation/call/bloc/call_bloc.dart';
import 'package:voxmatrix/presentation/call/bloc/call_event.dart';
import 'package:voxmatrix/presentation/call/bloc/call_state.dart';
import 'package:voxmatrix/presentation/call/widgets/call_controls.dart';

class IncomingCallPage extends StatelessWidget {
  const IncomingCallPage({
    super.key,
    required this.call,
  });

  final CallEntity call;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackground(),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade900,
              Colors.black,
              Colors.black,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildCallerInfo(),
          const Spacer(flex: 3),
          _buildCallTypeIndicator(),
          const Spacer(),
          _buildControls(context),
        ],
      ),
    );
  }

  Widget _buildCallerInfo() {
    return Column(
      children: [
        _buildAvatar(),
        const SizedBox(height: 24),
        _buildCallerName(),
        const SizedBox(height: 8),
        _buildRoomInfo(),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade800,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 3,
        ),
        image: call.callerAvatarUrl != null
            ? DecorationImage(
                image: NetworkImage(call.callerAvatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: call.callerAvatarUrl == null
          ? _buildAvatarPlaceholder()
          : null,
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        call.callerName.isNotEmpty
            ? call.callerName[0].toUpperCase()
            : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCallerName() {
    return Text(
      call.callerName,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRoomInfo() {
    return Text(
      'Incoming call',
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 16,
      ),
    );
  }

  Widget _buildCallTypeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            call.isVideoCall ? Icons.videocam : Icons.call,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            call.isVideoCall ? 'Video Call' : 'Voice Call',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return IncomingCallControls(
      onAnswer: () => _handleAnswer(context),
      onReject: () => _handleReject(context),
    );
  }

  void _handleAnswer(BuildContext context) {
    context.read<CallBloc>().add(
          AnswerCallEvent(
            callId: call.callId,
            roomId: call.roomId,
          ),
        );
  }

  void _handleReject(BuildContext context) {
    context.read<CallBloc>().add(
          RejectCallEvent(
            callId: call.callId,
            roomId: call.roomId,
          ),
        );
    Navigator.of(context).pop();
  }
}
