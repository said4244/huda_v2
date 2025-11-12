import 'package:flutter/material.dart';
import '../../data/models/page_model.dart';
import 'exercise_intro_widget.dart';
import 'exercise_trace_widget.dart';

/// Factory class for creating appropriate exercise widgets based on exercise type
class ExerciseWidgetFactory {
  /// Creates the appropriate widget for the given page based on its exercise type
  static Widget build(PageModel page, {VoidCallback? onContinue}) {
    final exerciseType = page.exerciseType;
    
    switch (exerciseType) {
      case 'exerciseIntro':
        return ExerciseIntroWidget(
          page: page,
          onContinue: onContinue,
        );
      
      case 'exerciseTrace':
        return ExerciseTraceWidget(
          page: page,
          onContinue: onContinue,
        );
      
      default:
        // Return legacy page display for backward compatibility
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: page.backgroundColor,
          child: Center(
            child: page.randomPlaceholder
                ? const Text(
                    'Legacy Page',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4D382D),
                      fontFamily: 'Roboto',
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        );
    }
  }
}
