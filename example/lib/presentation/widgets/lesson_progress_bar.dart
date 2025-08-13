import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../providers/lesson_progress_provider.dart';

/// Reusable lesson progress bar widget that displays lesson completion progress
/// Features:
/// - Linear progress indicator with smooth animations
/// - Gray background (#808080) for unfilled portion
/// - Brown fill (#4D382D) for completed portion
/// - Listens to LessonProgressProvider for automatic updates
class LessonProgressBar extends StatelessWidget {
  /// Height of the progress bar line
  final double lineHeight;
  
  /// Duration of the animation when progress changes
  final int animationDuration;
  
  /// Horizontal padding around the progress bar
  final double horizontalPadding;
  
  /// Vertical padding around the progress bar
  final double verticalPadding;
  
  /// Whether to show progress percentage text
  final bool showPercentage;

  const LessonProgressBar({
    super.key,
    this.lineHeight = 8.0,
    this.animationDuration = 500,
    this.horizontalPadding = 16.0,
    this.verticalPadding = 8.0,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    // Watch the progress provider for changes
    return Consumer<LessonProgressProvider>(
      builder: (context, progressProvider, child) {
        final fraction = progressProvider.progressFraction;
        final percentage = progressProvider.progressPercentage;
        
        // Always show the progress bar when in a lesson context
        // Even if totalPages is 0, show it as empty (will update when data loads)

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              LinearPercentIndicator(
                lineHeight: lineHeight,
                percent: fraction,
                animation: true,
                animateFromLastPercent: true,
                animationDuration: animationDuration,
                backgroundColor: const Color(0xFF808080), // Gray background
                progressColor: const Color(0xFF4D382D),   // Brown fill
                barRadius: const Radius.circular(4),
                padding: EdgeInsets.zero,
              ),
              
              // Optional percentage text
              if (showPercentage) ...[
                const SizedBox(height: 4),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4D382D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// A more detailed progress bar that shows page numbers
class DetailedLessonProgressBar extends StatelessWidget {
  /// Whether to show the current page number
  final bool showPageNumbers;
  
  /// Whether to show the progress percentage
  final bool showPercentage;

  const DetailedLessonProgressBar({
    super.key,
    this.showPageNumbers = true,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LessonProgressProvider>(
      builder: (context, progressProvider, child) {
        final completed = progressProvider.completedPages;
        final total = progressProvider.totalPages;
        final percentage = progressProvider.progressPercentage;
        
        // Don't show if no lesson is loaded
        if (total == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info row
              if (showPageNumbers || showPercentage)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (showPageNumbers)
                      Text(
                        '$completed of $total pages',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (showPercentage)
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4D382D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              
              if (showPageNumbers || showPercentage)
                const SizedBox(height: 6),
              
              // Progress bar
              LinearPercentIndicator(
                lineHeight: 8.0,
                percent: progressProvider.progressFraction,
                animation: true,
                animateFromLastPercent: true,
                animationDuration: 500,
                backgroundColor: const Color(0xFF808080),
                progressColor: const Color(0xFF4D382D),
                barRadius: const Radius.circular(4),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      },
    );
  }
}
