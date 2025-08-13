import 'package:flutter/material.dart';
import 'exercise_intro_theme.dart';
import 'exercise_intro_strings.dart';

/// Stateless widget for primary continue button
class PrimaryContinueButton extends StatelessWidget {
  final String? text;
  final bool enabled;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryContinueButton({
    super.key,
    this.text,
    required this.enabled,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ExerciseIntroTheme.paddingLarge),
      child: SizedBox(
        width: double.infinity,
        height: ExerciseIntroTheme.buttonHeight,
        child: ElevatedButton(
          onPressed: enabled && !isLoading ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ExerciseIntroTheme.primaryDark,
            disabledBackgroundColor: ExerciseIntroTheme.disabledBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ExerciseIntroTheme.radius),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text ?? ExerciseIntroStrings.continueText,
                  style: ExerciseIntroTheme.buttonTextStyle.copyWith(
                    color: enabled ? Colors.white : ExerciseIntroTheme.disabledText,
                  ),
                ),
        ),
      ),
    );
  }
}
