import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';

/// A widget that properly renders a RemoteVideoTrack using RTCVideoRenderer
class VideoTrackWidget extends StatefulWidget {
  final RemoteVideoTrack videoTrack;
  final VideoViewFit fit;

  const VideoTrackWidget({
    Key? key,
    required this.videoTrack,
    this.fit = VideoViewFit.cover,
  }) : super(key: key);

  @override
  State<VideoTrackWidget> createState() => _VideoTrackWidgetState();
}

class _VideoTrackWidgetState extends State<VideoTrackWidget> {
  RTCVideoRenderer? _renderer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeRenderer();
  }

  @override
  void didUpdateWidget(VideoTrackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoTrack != widget.videoTrack) {
      _updateVideoTrack();
    }
  }

  Future<void> _initializeRenderer() async {
    try {
      print("Initializing RTCVideoRenderer for track: ${widget.videoTrack.sid}");
      
      _renderer = RTCVideoRenderer();
      await _renderer!.initialize();
      
      // Attach the video track's MediaStream to the renderer
      print("Attaching mediaStream to renderer");
      _renderer!.srcObject = widget.videoTrack.mediaStream;
      
      setState(() {
        _isInitialized = true;
      });
      
      print("RTCVideoRenderer initialized successfully");
    } catch (e) {
      print("Error initializing RTCVideoRenderer: $e");
    }
  }

  Future<void> _updateVideoTrack() async {
    if (_renderer != null) {
      print("Updating video track for renderer");
      _renderer!.srcObject = widget.videoTrack.mediaStream;
      setState(() {});
    }
  }

  RTCVideoViewObjectFit _getObjectFit() {
    switch (widget.fit) {
      case VideoViewFit.contain:
        return RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;
      case VideoViewFit.cover:
        return RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
    }
  }

  @override
  void dispose() {
    print("Disposing RTCVideoRenderer");
    _renderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _renderer == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: RTCVideoView(
        _renderer!,
        objectFit: _getObjectFit(),
        mirror: false,
        placeholderBuilder: (context) => Container(
          color: Colors.black,
          child: const Center(
            child: Icon(
              Icons.videocam_off,
              color: Colors.white54,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}
