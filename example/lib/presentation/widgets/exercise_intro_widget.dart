import 'package:flutter/material.dart';
import 'exercise_widgets/exercise_intro_theme.dart';
import 'exercise_widgets/exercise_intro_strings.dart';
import 'exercise_widgets/exercise_header.dart';
import 'exercise_widgets/exercise_video_section.dart';
import 'exercise_widgets/hold_to_speak_button.dart';
import 'exercise_widgets/primary_continue_button.dart';
import 'exercise_widgets/base_exercise_page.dart';

/// Widget for displaying exercise introduction with video, headers, and interactive elements
class ExerciseIntroWidget extends BaseExercisePage {
  const ExerciseIntroWidget({
    super.key,
    required super.page,
    super.onContinue,
  });

  @override
  ExerciseIntroWidgetState createState() => ExerciseIntroWidgetState();
}

/// Public state class to allow external control via GlobalKey
class ExerciseIntroWidgetState extends BaseExerciseState<ExerciseIntroWidget> {
  
  @override
  Widget buildExerciseContent(BuildContext context) {
    final exerciseData = widget.page.exerciseData ?? {};
    
    return Container(
      color: ExerciseIntroTheme.backgroundColor,
      child: Column(
        children: [
          // Scrollable content section
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ExerciseHeader(
                    title: exerciseData['header1'] as String?,
                    transliteration: exerciseData['transliteration'] as String?,
                  ),
                  _buildVideoSection(exerciseData),
                  ExerciseSubheader(
                    text: exerciseData['header2'] as String?,
                  ),
                ],
              ),
            ),
          ),
          
          // Fixed bottom section
          Column(
            children: [
              _buildMicrophoneSection(exerciseData),
              _buildContinueButton(exerciseData),
              const SizedBox(height: ExerciseIntroTheme.paddingLarge),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(Map<String, dynamic> exerciseData) {
    final allowUserVideoControl = exerciseData['allowUserVideoControl'] as bool? ?? false;
    
    return ExerciseVideoSection(
      controller: videoController,
      isReady: isVideoReady,
      isError: videoError,
      isPlaying: videoController?.value.isPlaying ?? false,
      allowUserControl: allowUserVideoControl,
      onPlayPause: () {
        if (videoController?.value.isPlaying ?? false) {
          videoController?.pause();
        } else {
          videoController?.play();
        }
      },
      onRetry: () {
        setState(() {
          videoError = false;
          isVideoReady = false;
        });
        initializeVideo();
      },
    );
  }

  Widget _buildMicrophoneSection(Map<String, dynamic> exerciseData) {
    final showMicrophone = exerciseData['showMicrophone'] as bool? ?? false;
    final microphonePrompt = exerciseData['microphonePrompt'] as String? ?? '';
    
    if (!showMicrophone) {
      return const SizedBox.shrink();
    }
    
    return HoldToSpeakButton(
      prompt: microphonePrompt.isNotEmpty ? microphonePrompt : null,
      isPressed: isMicPressed,
      onHoldStart: onMicrophonePressStart,
      onHoldEnd: onMicrophonePressEnd,
    );
  }

  Widget _buildContinueButton(Map<String, dynamic> exerciseData) {
    final showContinueButton = exerciseData['showContinueButton'] as bool? ?? false;
    
    if (!showContinueButton) {
      return const SizedBox.shrink();
    }
    
    final isEnabled = areRequirementsMet();
    
    // Different button text based on progress state
    String buttonText = ExerciseIntroStrings.continueText;
    if (isEnabled && progressTriggered) {
      buttonText = ExerciseIntroStrings.continueArrowText;
    }
    
    return PrimaryContinueButton(
      text: buttonText,
      enabled: isEnabled,
      onPressed: onContinuePressed,
    );
  }
}
