import 'package:flutter/material.dart';
import 'exercise_intro_theme.dart';

/// Stateless widget for exercise headers with title and transliteration
class ExerciseHeader extends StatelessWidget {
  final String? title;
  final String? transliteration;

  const ExerciseHeader({
    super.key,
    this.title,
    this.transliteration,
  });

  @override
  Widget build(BuildContext context) {
    if (title == null && transliteration == null) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.all(ExerciseIntroTheme.paddingLarge),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Expanded(
              flex: 3,
              child: Text(
                title!,
                style: ExerciseIntroTheme.headerStyle,
              ),
            ),
          if (title != null && transliteration != null)
            const SizedBox(width: ExerciseIntroTheme.gapLarge),
          if (transliteration != null)
            Expanded(
              flex: 2,
              child: Text(
                transliteration!,
                style: ExerciseIntroTheme.transliterationStyle,
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }
}

/// Stateless widget for exercise subheader
class ExerciseSubheader extends StatelessWidget {
  final String? text;

  const ExerciseSubheader({
    super.key,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (text == null) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.all(ExerciseIntroTheme.paddingLarge),
      child: Text(
        text!,
        style: ExerciseIntroTheme.subheaderStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}
