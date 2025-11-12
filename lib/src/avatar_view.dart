import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'tavus_avatar_service.dart';
import 'models/avatar_state.dart';
import 'widgets/video_track_widget.dart';

/// Widget for displaying the Tavus avatar video with Picture-in-Picture support
class TavusAvatarView extends StatefulWidget {
  /// The avatar instance to display
  final TavusAvatar avatar;
  
  /// Aspect ratio of the video display (default: 9:16 portrait)
  final double aspectRatio;
  
  /// Border radius for the video container
  final BorderRadius? borderRadius;
  
  /// Custom placeholder widget when video is not available
  final Widget? placeholder;
  
  /// Whether to show a loading indicator when connecting
  final bool showLoadingIndicator;
  
  /// Whether to show status messages
  final bool showStatus;
  
  /// Background color when video is not available
  final Color backgroundColor;
  
  /// Custom error widget
  final Widget Function(String error)? errorBuilder;
  
  /// Video fit mode
  final VideoViewFit videoFit;

  const TavusAvatarView({
    Key? key,
    required this.avatar,
    this.aspectRatio = 9 / 16,
    this.borderRadius,
    this.placeholder,
    this.showLoadingIndicator = true,
    this.showStatus = true,
    this.backgroundColor = Colors.black,
    this.errorBuilder,
    this.videoFit = VideoViewFit.cover,
  }) : super(key: key);

  @override
  State<TavusAvatarView> createState() => TavusAvatarViewState();
}

class TavusAvatarViewState extends State<TavusAvatarView> {
  RemoteVideoTrack? _currentVideoTrack;
  
  @override
  void initState() {
    super.initState();
    
    // Listen to video track changes and trigger setState
    widget.avatar.videoTrackStream.listen((track) {
      print("TavusAvatarViewState - Video track changed: ${track?.sid}");
      if (mounted && _currentVideoTrack != track) {
        setState(() {
          _currentVideoTrack = track;
        });
      }
    });
    
    // Set initial video track if available
    _currentVideoTrack = widget.avatar.videoTrack;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video or placeholder - wrapped in SizedBox.expand to ensure proper sizing
              SizedBox.expand(
                child: StreamBuilder<RemoteVideoTrack?>(
                  stream: widget.avatar.videoTrackStream,
                  builder: (context, snapshot) {
                    // Use the latest video track from either stream or state
                    final videoTrack = snapshot.data ?? _currentVideoTrack;
                    
                    print("StreamBuilder rebuild - videoTrack: ${videoTrack?.sid}");
                    print("HasData: ${snapshot.hasData}, Data: ${snapshot.data?.sid}");
                    print("Current state track: ${_currentVideoTrack?.sid}");
                    
                    if (videoTrack != null) {
                      return VideoTrackWidget(
                        videoTrack: videoTrack,
                        fit: widget.videoFit,
                      );
                    }
                    
                    // Show placeholder when no video
                    return _buildPlaceholder(context);
                  },
                ),
              ),
              
              // Status overlay
              if (widget.showStatus)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildStatusOverlay(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return StreamBuilder<AvatarState>(
      stream: widget.avatar.stateStream,
      initialData: widget.avatar.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        
        if (state == AvatarState.error && widget.errorBuilder != null) {
          return widget.errorBuilder!(widget.avatar.status);
        }
        
        if (widget.placeholder != null) {
          return widget.placeholder!;
        }
        
        // Default placeholder
        return Container(
          color: widget.backgroundColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state == AvatarState.connecting && widget.showLoadingIndicator)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                else
                  Icon(
                    _getIconForState(state),
                    size: 64,
                    color: Colors.white.withOpacity(0.5),
                  ),
                const SizedBox(height: 16),
                Text(
                  _getTextForState(state),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (state == AvatarState.error)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.avatar.status,
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusOverlay(BuildContext context) {
    return StreamBuilder<String>(
      stream: widget.avatar.statusStream,
      initialData: widget.avatar.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? '';
        if (status.isEmpty || widget.avatar.hasVideo) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  IconData _getIconForState(AvatarState state) {
    switch (state) {
      case AvatarState.connecting:
      case AvatarState.reconnecting:
        return Icons.sync;
      case AvatarState.connected:
        return Icons.person;
      case AvatarState.error:
        return Icons.error_outline;
      case AvatarState.disconnected:
        return Icons.videocam_off;
    }
  }

  String _getTextForState(AvatarState state) {
    switch (state) {
      case AvatarState.connecting:
        return 'Connecting to avatar...';
      case AvatarState.reconnecting:
        return 'Reconnecting...';
      case AvatarState.connected:
        return 'Avatar connected';
      case AvatarState.error:
        return 'Connection error';
      case AvatarState.disconnected:
        return 'Disconnected. Tap to start';
    }
  }
}