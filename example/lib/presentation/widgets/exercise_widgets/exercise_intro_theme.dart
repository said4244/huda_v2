import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Theme constants for ExerciseIntro widgets
class ExerciseIntroTheme {
  // Colors
  static const Color backgroundColor = Color(0xFFF2EFEB); // Cream background
  static const Color primaryDark = Color(0xFF4D382D); // Dark brown
  static const Color accent = Color(0xFFDDC6A9); // Light brown accent
  static const Color disabledBackground = Color(0xFFE0E0E0); // Light grey for disabled
  static const Color disabledText = Color(0xFF9E9E9E); // Grey for disabled text
  static const Color errorColor = Color(0xFFD32F2F); // Red for errors
  static const Color successColor = Color(0xFF388E3C); // Green for success
  
  // Dimensions and spacing
  static const double paddingLarge = 20.0;
  static const double paddingMedium = 16.0;
  static const double paddingSmall = 12.0;
  static const double paddingTiny = 8.0;
  static const double gapSmall = 8.0;
  static const double gapMedium = 12.0;
  static const double gapLarge = 16.0;
  static const double radius = 12.0;
  static const double micButtonSize = 80.0;
  static const double buttonHeight = 56.0;
  
  // Text styles
  static const TextStyle headerStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryDark,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle transliterationStyle = TextStyle(
    fontSize: 18,
    fontStyle: FontStyle.italic,
    color: primaryDark,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle subheaderStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: primaryDark,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle microphonePromptStyle = TextStyle(
    fontSize: 18,
    color: primaryDark,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle microphoneLabelStyle = TextStyle(
    fontSize: 14,
    color: disabledText,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: 'Roboto',
  );
  
  static const TextStyle videoErrorStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
  );
  
  static const TextStyle videoErrorSubtitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 12,
  );
  
  // Video progress colors
  static const VideoProgressColors videoProgressColors = VideoProgressColors(
    playedColor: accent,
    bufferedColor: Colors.grey,
    backgroundColor: Colors.white24,
  );
  
  // Shadow styles
  static const List<BoxShadow> micButtonShadow = [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
}
