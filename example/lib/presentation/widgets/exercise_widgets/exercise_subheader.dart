import 'package:flutter/material.dart';
import 'exercise_intro_theme.dart';

/// Widget for displaying exercise subheader text
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ExerciseIntroTheme.paddingMedium),
      child: Text(
        text!,
        style: ExerciseIntroTheme.subheaderStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}
