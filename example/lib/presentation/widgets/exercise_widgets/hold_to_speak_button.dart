import 'package:flutter/material.dart';
import 'exercise_intro_theme.dart';
import 'exercise_intro_strings.dart';

/// Stateless widget for hold-to-speak microphone button
class HoldToSpeakButton extends StatelessWidget {
  final String? prompt;
  final bool isPressed;
  final VoidCallback? onHoldStart;
  final VoidCallback? onHoldEnd;
  final bool enabled;
  final String? label;

  const HoldToSpeakButton({
    super.key,
    this.prompt,
    required this.isPressed,
    this.onHoldStart,
    this.onHoldEnd,
    this.enabled = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ExerciseIntroTheme.paddingLarge),
      child: Column(
        children: [
          if (prompt != null && prompt!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: ExerciseIntroTheme.gapLarge),
              child: Text(
                prompt!,
                style: ExerciseIntroTheme.microphonePromptStyle,
                textAlign: TextAlign.center,
              ),
            ),
          GestureDetector(
            onLongPressStart: enabled ? (_) => onHoldStart?.call() : null,
            onLongPressEnd: enabled ? (_) => onHoldEnd?.call() : null,
            child: Container(
              width: ExerciseIntroTheme.micButtonSize,
              height: ExerciseIntroTheme.micButtonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getButtonColor(),
                boxShadow: enabled ? ExerciseIntroTheme.micButtonShadow : null,
              ),
              child: Icon(
                Icons.mic,
                color: _getIconColor(),
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: ExerciseIntroTheme.gapMedium),
          Text(
            label ?? ExerciseIntroStrings.holdToSpeakText,
            style: ExerciseIntroTheme.microphoneLabelStyle,
          ),
        ],
      ),
    );
  }

  Color _getButtonColor() {
    if (!enabled) return ExerciseIntroTheme.disabledBackground;
    return isPressed 
        ? ExerciseIntroTheme.primaryDark 
        : ExerciseIntroTheme.accent;
  }

  Color _getIconColor() {
    if (!enabled) return ExerciseIntroTheme.disabledText;
    return isPressed 
        ? Colors.white 
        : ExerciseIntroTheme.primaryDark;
  }
}
