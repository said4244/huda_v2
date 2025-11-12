import 'package:flutter/material.dart';
import 'exercise_widgets/exercise_intro_theme.dart';
import 'exercise_widgets/exercise_header.dart';
import 'exercise_widgets/hold_to_speak_button.dart';
import 'exercise_widgets/primary_continue_button.dart';
import 'exercise_widgets/base_exercise_page.dart';
import 'exercise_widgets/exercise_tracing_section.dart';

/// Widget for displaying tracing exercise with interactive letter tracing
class ExerciseTraceWidget extends BaseExercisePage {
  const ExerciseTraceWidget({
    super.key,
    required super.page,
    super.onContinue,
  });

  @override
  ExerciseTraceWidgetState createState() => ExerciseTraceWidgetState();
}

/// Public state class to allow external control via GlobalKey
class ExerciseTraceWidgetState extends BaseExerciseState<ExerciseTraceWidget> {
  bool _traceCompleted = false; // track if tracing has been completed
  bool _dotCompleted = false;   // track if nuqta dot has been tapped

  @override
  void initState() {
    super.initState();
    // BaseExerciseState handles onStart triggers automatically
  }

  @override
  Widget buildExerciseContent(BuildContext context) {
    final exerciseData = widget.page.exerciseData ?? {};
    
    // Retrieve the exercise data fields (headers, asset names, etc.)
    final header1 = exerciseData['header1'] as String? ?? '';
    final header2 = exerciseData['header2'] as String? ?? '';
    final transliteration = exerciseData['transliteration'] as String? ?? '';
    final letter = exerciseData['letter'] as String? ?? '';
    final showMicrophone = exerciseData['showMicrophone'] as bool? ?? false;
    final showContinueButton = exerciseData['showContinueButton'] as bool? ?? true;
    final microphonePrompt = exerciseData['microphonePrompt'] as String? ?? '';

    return Container(
      color: ExerciseIntroTheme.backgroundColor,
      child: Column(
        children: [
          // Top area: Scrollable content with headers and tracing canvas
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExerciseHeader(
                    title: header1,
                    transliteration: transliteration,
                  ),
                  // Tracing content section
                  if (letter.isNotEmpty)
                    ExerciseTracingSection(
                      letter: letter,
                      onTraceComplete: _handleTraceComplete,
                    ),
                  if (header2.isNotEmpty)
                    ExerciseSubheader(text: header2),
                ],
              ),
            ),
          ),
          
          // Bottom fixed controls: microphone button and continue button
          Column(
            children: [
              if (showMicrophone)
                HoldToSpeakButton(
                  prompt: microphonePrompt.isNotEmpty ? microphonePrompt : null,
                  isPressed: isMicPressed,
                  onHoldStart: onMicrophonePressStart,
                  onHoldEnd: onMicrophonePressEnd,
                ),
              if (showContinueButton)
                _buildContinueButton(),
              const SizedBox(height: ExerciseIntroTheme.paddingLarge),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = areRequirementsMet();
    
    // Different button text based on progress state
    String buttonText = 'Continue';
    if (isEnabled && progressTriggered) {
      buttonText = 'Continue →';
    }
    
    return PrimaryContinueButton(
      text: buttonText,
      enabled: isEnabled,
      onPressed: onContinuePressed,
    );
  }

  // Override areRequirementsMet to include tracing completion as a requirement
  @override
  bool areRequirementsMet() {
    final exerciseData = widget.page.exerciseData ?? {};
    final showContinueButton = exerciseData['showContinueButton'] as bool? ?? true;
    
    // Use BaseExerciseState's checks (video watched, mic used, sequence completed) AND tracing completion
    bool baseRequirements = super.areRequirementsMet();
    bool tracingRequired = showContinueButton ? (_traceCompleted && _dotCompleted) : true;
    
    return baseRequirements && tracingRequired;
  }

  // Handler for trace completion callback from the tracing canvas
  void _handleTraceComplete(bool completed) {
    if (completed) {
      setState(() {
        _traceCompleted = true;
        _dotCompleted = true; // In our enhanced system, completion means both path and dot are done
      });
      
      final exerciseData = widget.page.exerciseData ?? {};
      final showContinueButton = exerciseData['showContinueButton'] as bool? ?? true;
      
      // If there's no continue button, auto-advance to next page
      if (!showContinueButton) {
        onContinuePressed(); // Immediately go to next page if continue button is not shown
      }
      // Otherwise, PrimaryContinueButton will be enabled via areRequirementsMet() now returning true
    } else {
      // Reset was called from tracing canvas
      setState(() {
        _traceCompleted = false;
        _dotCompleted = false;
      });
    }
  }
}

/// Simple subheader widget for exercise instructions
class ExerciseSubheader extends StatelessWidget {
  final String? text;

  const ExerciseSubheader({
    super.key,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ExerciseIntroTheme.paddingMedium,
        vertical: ExerciseIntroTheme.paddingSmall,
      ),
      child: Text(
        text!,
        style: const TextStyle(
          fontSize: 18,
          color: ExerciseIntroTheme.primaryDark,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
