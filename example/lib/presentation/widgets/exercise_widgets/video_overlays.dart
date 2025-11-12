import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'exercise_intro_theme.dart';
import 'exercise_intro_strings.dart';

/// Private widget for video error state overlay
class VideoErrorOverlay extends StatelessWidget {
  final VoidCallback? onRetry;

  const VideoErrorOverlay({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 48,
          ),
          const SizedBox(height: ExerciseIntroTheme.gapSmall),
          const Text(
            ExerciseIntroStrings.videoFailedToLoad,
            style: ExerciseIntroTheme.videoErrorStyle,
          ),
          const SizedBox(height: 4),
          const Text(
            ExerciseIntroStrings.pleaseRetryLater,
            style: ExerciseIntroTheme.videoErrorSubtitleStyle,
          ),
          const SizedBox(height: ExerciseIntroTheme.gapMedium),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: ExerciseIntroTheme.paddingMedium, 
                vertical: ExerciseIntroTheme.gapSmall
              ),
            ),
            child: const Text(ExerciseIntroStrings.retryText),
          ),
        ],
      ),
    );
  }
}

/// Private widget for video controls overlay
class VideoControlsOverlay extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VideoPlayerController videoController;

  const VideoControlsOverlay({
    super.key,
    required this.isPlaying,
    this.onPlayPause,
    required this.videoController,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ExerciseIntroTheme.radius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onPlayPause,
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: ExerciseIntroTheme.accent,
                    size: 24,
                  ),
                ),
                Expanded(
                  child: VideoProgressIndicator(
                    videoController,
                    allowScrubbing: true,
                    colors: ExerciseIntroTheme.videoProgressColors,
                  ),
                ),
                const SizedBox(width: ExerciseIntroTheme.gapSmall),
              ],
            ),
            const SizedBox(height: ExerciseIntroTheme.gapSmall),
          ],
        ),
      ),
    );
  }
}
