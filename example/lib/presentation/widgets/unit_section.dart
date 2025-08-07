import 'package:flutter/material.dart';
import '../../data/models/unit_model.dart';
import '../../data/models/level_model.dart';
import '../../config/level_positions.dart';
import 'unit_header.dart';
import 'level_tile.dart';

/// Container widget that manages an entire unit with Stack-based positioning
/// Features:
/// - Uses Stack with Positioned widgets for absolute control
/// - Height calculated as (levelCount * 77) + headerHeight
/// - Wraps levels in OverflowBox to allow negative margins
/// - Implements pixel-perfect zigzag wave pattern
/// - Handles responsive design and touch interactions
class UnitSection extends StatelessWidget {
  final UnitModel unit;
  final Function(LevelModel)? onLevelTap;
  final VoidCallback? onJumpTap;
  final bool showLevelLabels;

  const UnitSection({
    super.key,
    required this.unit,
    this.onLevelTap,
    this.onJumpTap,
    this.showLevelLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerHeight = _calculateTotalHeight();
    
    return Container(
      width: double.infinity,
      height: containerHeight,
      margin: const EdgeInsets.only(bottom: 32),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Unit header at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: UnitHeader(
              unit: unit,
              onJumpTap: onJumpTap,
            ),
          ),
          
          // Levels positioned in wave pattern
          ..._buildPositionedLevels(screenWidth),
        ],
      ),
    );
  }

  /// Calculates the total height needed for this unit
  double _calculateTotalHeight() {
    return LevelPositionConfig.calculateUnitHeight(unit.levels.length);
  }

  /// Builds all level tiles with absolute positioning
  List<Widget> _buildPositionedLevels(double screenWidth) {
    final levels = <Widget>[];
    final centerX = screenWidth / 2;
    final levelsStartY = LevelPositionConfig.unitHeaderHeight + 
                        LevelPositionConfig.unitHeaderMarginBottom;

    for (int i = 0; i < unit.levels.length; i++) {
      final level = unit.levels[i];
      final position = _calculateLevelPosition(i, centerX, levelsStartY);
      
      levels.add(
        Positioned(
          left: position.dx - (level.type == LevelType.chest ? 75.0 : 55.0), // Center tiles: chest=150/2=75, normal=110/2=55
          top: position.dy,
          child: LevelTile(
            level: level,
            unit: unit,
            onTap: () => onLevelTap?.call(level),
            showHoverLabel: showLevelLabels,
          ),
        ),
      );
    }

    return levels;
  }

  /// Calculates the exact position for a level based on wave pattern
  Offset _calculateLevelPosition(int levelIndex, double centerX, double startY) {
    final horizontalOffset = LevelPositionConfig.getHorizontalOffset(
      unit.number, 
      levelIndex,
    );
    
    final x = centerX + horizontalOffset;
    final y = startY + (levelIndex * LevelPositionConfig.verticalSpacing);
    
    return Offset(x, y);
  }
}

/// Custom layout delegate for complex wave positioning (alternative approach)
/// This provides more control over the layout but is more complex to implement
class WaveLayoutDelegate extends MultiChildLayoutDelegate {
  final UnitModel unit;
  final double containerWidth;

  WaveLayoutDelegate({
    required this.unit,
    required this.containerWidth,
  });

  @override
  void performLayout(Size size) {
    final centerX = containerWidth / 2;
    final levelsStartY = LevelPositionConfig.unitHeaderHeight + 
                        LevelPositionConfig.unitHeaderMarginBottom;

    for (int i = 0; i < unit.levels.length; i++) {
      final levelId = 'level_$i';
      
      if (hasChild(levelId)) {
        final levelSize = layoutChild(
          levelId,
          BoxConstraints.loose(const Size(98, 93)),
        );
        
        final horizontalOffset = LevelPositionConfig.getHorizontalOffset(
          unit.number, 
          i,
        );
        
        final position = Offset(
          centerX + horizontalOffset - (levelSize.width / 2),
          levelsStartY + (i * LevelPositionConfig.verticalSpacing),
        );
        
        positionChild(levelId, position);
      }
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return oldDelegate is! WaveLayoutDelegate ||
           oldDelegate.unit != unit ||
           oldDelegate.containerWidth != containerWidth;
  }
}

/// Responsive unit section that adapts to different screen sizes
class ResponsiveUnitSection extends StatelessWidget {
  final UnitModel unit;
  final Function(LevelModel)? onLevelTap;
  final VoidCallback? onJumpTap;

  const ResponsiveUnitSection({
    super.key,
    required this.unit,
    this.onLevelTap,
    this.onJumpTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        if (screenWidth < 400) {
          // Very small screens - reduce spacing and amplitude
          return _buildCompactUnit();
        } else if (screenWidth < 600) {
          // Mobile - standard layout
          return UnitSection(
            unit: unit,
            onLevelTap: onLevelTap,
            onJumpTap: onJumpTap,
          );
        } else if (screenWidth < 1200) {
          // Tablet - slightly increased spacing
          return _buildTabletUnit();
        } else {
          // Desktop - max width with centered content
          return _buildDesktopUnit();
        }
      },
    );
  }

  Widget _buildCompactUnit() {
    // Compact version for very small screens
    return UnitSection(
      unit: unit,
      onLevelTap: onLevelTap,
      onJumpTap: onJumpTap,
      showLevelLabels: false, // Hide labels on very small screens
    );
  }

  Widget _buildTabletUnit() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: UnitSection(
          unit: unit,
          onLevelTap: onLevelTap,
          onJumpTap: onJumpTap,
        ),
      ),
    );
  }

  Widget _buildDesktopUnit() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: UnitSection(
          unit: unit,
          onLevelTap: onLevelTap,
          onJumpTap: onJumpTap,
        ),
      ),
    );
  }
}
