import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';

/// Voice recorder widget with recording controls
class VoiceRecorderWidget extends StatefulWidget {
  const VoiceRecorderWidget({
    super.key,
    required this.onSend,
    required this.onCancel,
  });

  final Future<void> Function(String path, int duration) onSend;
  final VoidCallback onCancel;

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _recordPath;
  Timer? _timer;
  int _recordDuration = 0;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required')),
          );
          widget.onCancel();
        }
        return;
      }

      await _recorder.openRecorder();
      setState(() {
        _isRecorderInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize recorder: $e')),
        );
        widget.onCancel();
      }
    }
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) return;

    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _recordPath = path;
        _recordDuration = 0;
      });

      // Start timer to track recording duration
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordDuration++;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopAndSend() async {
    _timer?.cancel();

    try {
      final path = await _recorder.stopRecorder();

      if (path != null && _recordDuration > 0) {
        await widget.onSend(path, _recordDuration);
      } else {
        widget.onCancel();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();

    try {
      await _recorder.stopRecorder();

      // Delete the recording file
      if (_recordPath != null && File(_recordPath!).existsSync()) {
        await File(_recordPath!).delete();
      }
    } catch (e) {
      // Ignore errors during cleanup
    }

    widget.onCancel();
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Audio visualization animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => AnimatedContainer(
                    duration: Duration(milliseconds: 150 + (index * 30)),
                    height: _isRecording ? 30 + (value * 20) : 20,
                    width: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _isRecording ? AppColors.primary : Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            },
            onEnd: () {
              if (_isRecording && mounted) {
                setState(() {}); // Trigger rebuild to loop animation
              }
            },
          ),

          const SizedBox(height: 24),

          // Duration
          Text(
            _formatDuration(_recordDuration),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),
          Text(
            _isRecording ? 'Recording...' : 'Ready to record',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 24),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Cancel button
              Material(
                color: Colors.red[50],
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _isRecording ? _cancelRecording : widget.onCancel,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.delete, color: Colors.red),
                  ),
                ),
              ),

              // Record/Stop button
              if (!_isRecording)
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _startRecording,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Icon(
                        Icons.mic,
                        color: AppColors.onPrimary,
                        size: 32,
                      ),
                    ),
                  ),
                )
              else
                Material(
                  color: Colors.red,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _stopAndSend,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(
                        Icons.stop,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Voice message player widget
class VoiceMessagePlayer extends StatefulWidget {
  const VoiceMessagePlayer({
    super.key,
    required this.url,
    required this.duration,
    this.isOutgoing = false,
  });

  final String url;
  final int duration;
  final bool isOutgoing;

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  int _currentPosition = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position.inSeconds;
        });
      }
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = 0;
        });
      }
    });
  }

  Future<void> _togglePlay() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (_isPlaying) {
        await _player.pause();
        setState(() {
          _isPlaying = false;
          _isLoading = false;
        });
      } else {
        await _player.play(UrlSource(widget.url));
        setState(() {
          _isPlaying = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '$mins:${secs.toString().padLeft(2, '0')}';
    }
      return ':${secs.toString().padLeft(2, '0')}';
  }

  double get _progress => widget.duration > 0
      ? _currentPosition / widget.duration
      : 0.0;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 200,
        maxWidth: 300,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isOutgoing
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isOutgoing
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.onSurface.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _isLoading ? null : _togglePlay,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: widget.isOutgoing
                            ? AppColors.primary
                            : AppColors.onSurface,
                      ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Waveform visualization
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // Progress bar with waveform visualization
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: widget.isOutgoing
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.onSurface.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isOutgoing ? AppColors.primary : AppColors.onSurface,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Duration
          Text(
            _formatDuration(widget.duration),
            style: TextStyle(
              fontSize: 12,
              color: widget.isOutgoing
                  ? AppColors.primary
                  : AppColors.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
