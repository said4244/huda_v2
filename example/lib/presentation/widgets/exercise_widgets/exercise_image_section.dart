import 'package:flutter/material.dart';
import 'exercise_intro_theme.dart';

/// Stateless widget for an image section with the same layout as the video section.
/// Expects an asset file name under assets/images (e.g., "camel.png").
class ExerciseImageSection extends StatelessWidget {
  final String imageFileName;

  const ExerciseImageSection({super.key, required this.imageFileName});

  @override
  Widget build(BuildContext context) {
    if (imageFileName.isEmpty) return const SizedBox.shrink();

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
            child: Image.asset(
              'assets/images/' + imageFileName,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Text(
                    'Image not found',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
