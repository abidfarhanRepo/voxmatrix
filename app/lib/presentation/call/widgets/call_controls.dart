import 'package:flutter/material.dart';
import 'package:voxmatrix/domain/entities/call.dart';

class CallControls extends StatelessWidget {
  const CallControls({
    super.key,
    required this.callState,
    required this.isMuted,
    required this.isSpeakerEnabled,
    required this.isCameraEnabled,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onHangup,
    this.showCameraControls = true,
  });

  final CallState callState;
  final bool isMuted;
  final bool isSpeakerEnabled;
  final bool isCameraEnabled;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onHangup;
  final bool showCameraControls;

  @override
  Widget build(BuildContext context) {
    final isActive = callState == CallState.active;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              _buildCallTimer(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMuteButton(),
                if (showCameraControls) ...[
                  _buildCameraButton(),
                  _buildSwitchCameraButton(),
                ],
                _buildSpeakerButton(),
                _buildHangupButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallTimer() {
    return const Text(
      '00:00',
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildMuteButton() {
    return _ControlButton(
      icon: isMuted ? Icons.mic_off : Icons.mic,
      label: 'Mute',
      backgroundColor: isMuted ? Colors.red : Colors.white24,
      onPressed: onToggleMute,
    );
  }

  Widget _buildSpeakerButton() {
    return _ControlButton(
      icon: isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
      label: 'Speaker',
      backgroundColor: isSpeakerEnabled ? Colors.green : Colors.white24,
      onPressed: onToggleSpeaker,
    );
  }

  Widget _buildCameraButton() {
    return _ControlButton(
      icon: isCameraEnabled ? Icons.videocam : Icons.videocam_off,
      label: 'Camera',
      backgroundColor: isCameraEnabled ? Colors.white24 : Colors.red,
      onPressed: onToggleCamera,
    );
  }

  Widget _buildSwitchCameraButton() {
    return _ControlButton(
      icon: Icons.flip_camera_ios,
      label: 'Flip',
      backgroundColor: Colors.white24,
      onPressed: onSwitchCamera,
    );
  }

  Widget _buildHangupButton() {
    return _ControlButton(
      icon: Icons.call_end,
      label: 'End',
      backgroundColor: Colors.red,
      iconColor: Colors.white,
      onPressed: onHangup,
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor ?? Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class IncomingCallControls extends StatelessWidget {
  const IncomingCallControls({
    super.key,
    required this.onAnswer,
    required this.onReject,
  });

  final VoidCallback onAnswer;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAction(
              icon: Icons.call_end,
              label: 'Decline',
              color: Colors.red,
              onPressed: onReject,
            ),
            _buildAction(
              icon: Icons.call,
              label: 'Answer',
              color: Colors.green,
              onPressed: onAnswer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(35),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class OutgoingCallControls extends StatelessWidget {
  const OutgoingCallControls({
    super.key,
    required this.onCancel,
    this.callState = CallState.outgoing,
  });

  final VoidCallback onCancel;
  final CallState callState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusText(),
            const SizedBox(height: 24),
            _buildCancelButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    String status;
    switch (callState) {
      case CallState.outgoing:
        status = 'Calling...';
        break;
      case CallState.connecting:
        status = 'Connecting...';
        break;
      default:
        status = 'Calling...';
    }

    return Column(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          status,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return InkWell(
      onTap: onCancel,
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.call_end,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
