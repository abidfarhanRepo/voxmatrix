import 'package:flutter/widgets.dart';

/// Stub implementations for flutter_webrtc types
/// These are placeholder classes to avoid compilation errors when
/// flutter_webrtc has compatibility issues.

class RTCVideoRenderer {
  MediaStream? srcObject;
  bool _initialized = false;

  Future<void> initialize() async {
    _initialized = true;
  }

  Future<void> dispose() async {
    _initialized = false;
    srcObject = null;
  }
}

class RTCVideoView extends StatelessWidget {
  final RTCVideoRenderer renderer;

  const RTCVideoView(
    this.renderer, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2C2C2C),
      child: const Center(
        child: Text(
          'Video Call (Stub)\nflutter_webrtc has compatibility issues',
          style: TextStyle(color: Color(0xFF888888)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class MediaStream {
  final String id;
  MediaStream(this.id);
}
