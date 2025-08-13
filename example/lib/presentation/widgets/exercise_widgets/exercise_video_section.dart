import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'exercise_intro_theme.dart';
import 'video_overlays.dart';

/// Stateless widget for exercise video section with controls and error handling
class ExerciseVideoSection extends StatelessWidget {
  final VideoPlayerController? controller;
  final bool isReady;
  final bool isError;
  final bool isPlaying;
  final bool allowUserControl;
  final VoidCallback? onPlayPause;
  final VoidCallback? onRetry;

  const ExerciseVideoSection({
    super.key,
    required this.controller,
    required this.isReady,
    required this.isError,
    required this.isPlaying,
    this.allowUserControl = false,
    this.onPlayPause,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ExerciseIntroTheme.paddingLarge),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ExerciseIntroTheme.radius),
            color: Colors.black,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ExerciseIntroTheme.radius),
            child: _buildVideoContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (isError) {
      return VideoErrorOverlay(onRetry: onRetry);
    }
    
    if (!isReady) {
      return const Center(
        child: CircularProgressIndicator(
          color: ExerciseIntroTheme.primaryDark,
        ),
      );
    }
    
    return Stack(
      children: [
        VideoPlayer(controller!),
        if (allowUserControl)
          VideoControlsOverlay(
            isPlaying: isPlaying,
            onPlayPause: onPlayPause,
            videoController: controller!,
          ),
      ],
    );
  }
}
