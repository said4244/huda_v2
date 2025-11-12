import 'dart:math';
import 'package:flutter/material.dart';

/// Configuration for level positioning in the wave pattern
class LevelPositionConfig {
  // Wave pattern for odd-numbered units (Unit 1, 3, 5, etc.)
  static const List<int> oddUnitPattern = [
    0,    // center
    -45,  // left
    -70,  // far left
    -45,  // left
    0,    // center
    45,   // right
    70,   // far right
    45,   // right
  ];
  
  // Wave pattern for even-numbered units (Unit 2, 4, 6, etc.)
  static const List<int> evenUnitPattern = [
    0,    // center (starts mirrored)
    45,   // right
    70,   // far right
    45,   // right
    0,    // center
    -45,  // left
    -70,  // far left
    -45,  // left
  ];
  
  // Vertical spacing constants
  static const double verticalSpacing = 94.6; // Increased by 10% from 86.0 (86 * 1.1)
  static const double tileHeight = 105.0; // Decreased by 25% from 140 (93 * 1.125) 
  static const double overlapMargin = -18.0; // Adjusted negative margin
  
  // Unit header constants
  static const double unitHeaderHeight = 80.0;
  static const double unitHeaderMarginBottom = 60.0; // Increased from 16 to 40
  
  /// Calculates total height needed for a unit with given number of levels
  static double calculateUnitHeight(int levelCount) {
    if (levelCount == 0) return unitHeaderHeight + unitHeaderMarginBottom;
    
    return unitHeaderHeight + 
           unitHeaderMarginBottom + 
           (levelCount * verticalSpacing) + 
           32.0; // Bottom padding
  }
  
  /// Gets the horizontal offset pattern for a unit
  static List<int> getPatternForUnit(int unitNumber) {
    return unitNumber % 2 == 1 ? oddUnitPattern : evenUnitPattern;
  }
  
  /// Gets horizontal offset for a specific level in a unit
  static int getHorizontalOffset(int unitNumber, int levelIndex) {
    final pattern = getPatternForUnit(unitNumber);
    return pattern[levelIndex % pattern.length];
  }
}

/// Calculator for level positions in the wave layout
class LevelPositionCalculator {
  /// Calculates positions for all levels in a unit
  static List<Offset> calculateForUnit(int unitNumber, int levelCount) {
    final positions = <Offset>[];
    final pattern = LevelPositionConfig.getPatternForUnit(unitNumber);
    
    for (int i = 0; i < levelCount; i++) {
      final horizontalOffset = pattern[i % pattern.length].toDouble();
      final verticalOffset = i * LevelPositionConfig.verticalSpacing;
      
      positions.add(Offset(horizontalOffset, verticalOffset));
    }
    
    return positions;
  }
  
  /// Calculates the center X position for the wave pattern
  static double getCenterX(double containerWidth) {
    return containerWidth / 2;
  }
  
  /// Gets the absolute position for a level
  static Offset getAbsolutePosition({
    required int unitNumber,
    required int levelIndex,
    required double containerWidth,
    required double unitTopOffset,
  }) {
    final horizontalOffset = LevelPositionConfig.getHorizontalOffset(unitNumber, levelIndex);
    final centerX = getCenterX(containerWidth);
    
    final x = centerX + horizontalOffset;
    final y = unitTopOffset + 
              LevelPositionConfig.unitHeaderHeight + 
              LevelPositionConfig.unitHeaderMarginBottom +
              (levelIndex * LevelPositionConfig.verticalSpacing);
    
    return Offset(x, y);
  }
  
  /// Validates that a position is within bounds
  static bool isPositionValid(Offset position, Size containerSize) {
    return position.dx >= 0 && 
           position.dx <= containerSize.width &&
           position.dy >= 0 && 
           position.dy <= containerSize.height;
  }
  
  /// Calculates bounds for a unit (min/max X and Y)
  static Rect calculateUnitBounds({
    required int unitNumber,
    required int levelCount,
    required double containerWidth,
    required double unitTopOffset,
  }) {
    if (levelCount == 0) {
      return Rect.fromLTWH(
        0, 
        unitTopOffset, 
        containerWidth, 
        LevelPositionConfig.unitHeaderHeight
      );
    }
    
    final pattern = LevelPositionConfig.getPatternForUnit(unitNumber);
    final centerX = getCenterX(containerWidth);
    
    // Find min and max horizontal offsets
    final minOffset = pattern.reduce(min);
    final maxOffset = pattern.reduce(max);
    
    final minX = centerX + minOffset - 49; // Half tile width (98/2)
    final maxX = centerX + maxOffset + 49; // Half tile width (98/2)
    
    final topY = unitTopOffset;
    final bottomY = unitTopOffset + LevelPositionConfig.calculateUnitHeight(levelCount);
    
    return Rect.fromLTRB(minX, topY, maxX, bottomY);
  }
}

/// Helper for responsive positioning calculations
class ResponsivePositionHelper {
  /// Adjusts wave amplitude based on screen width
  static List<int> getResponsivePattern(int unitNumber, double screenWidth) {
    final basePattern = LevelPositionConfig.getPatternForUnit(unitNumber);
    
    if (screenWidth < 400) {
      // Reduce amplitude for very small screens
      return basePattern.map((offset) => (offset * 0.7).round()).toList();
    } else if (screenWidth < 600) {
      // Slightly reduce amplitude for mobile
      return basePattern.map((offset) => (offset * 0.85).round()).toList();
    } else if (screenWidth > 1200) {
      // Increase amplitude for desktop
      return basePattern.map((offset) => (offset * 1.2).round()).toList();
    }
    
    return basePattern;
  }
  
  /// Gets responsive tile spacing
  static double getResponsiveSpacing(double screenWidth) {
    if (screenWidth < 400) {
      return LevelPositionConfig.verticalSpacing * 0.8;
    } else if (screenWidth > 1200) {
      return LevelPositionConfig.verticalSpacing * 1.1;
    }
    
    return LevelPositionConfig.verticalSpacing;
  }
  
  /// Calculates responsive margins
  static EdgeInsets getResponsiveMargins(double screenWidth) {
    if (screenWidth < 600) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    } else if (screenWidth < 1200) {
      return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 64.0, vertical: 24.0);
    }
  }
}
