import 'package:flutter/material.dart';
import '../../data/models/level_model.dart';
import '../../data/models/unit_model.dart';
import 'level_icons_svg.dart';
import 'hover_label.dart';

/// Core interactive level tile widget
/// Features:
/// - Fixed size: 98x93 container with proper shadows
/// - Circle button (64x64 or 80x64 for chest type)
/// - Dynamic icon based on level type and status
/// - Optional floating hover label (START, JUMP HERE, OPEN)
/// - Touch targets minimum 48x48 despite visual size
/// - 3D depth with shadow layer and border effects
class LevelTile extends StatefulWidget {
  final LevelModel level;
  final UnitModel unit;
  final VoidCallback? onTap;
  final bool showHoverLabel;

  const LevelTile({
    super.key,
    required this.level,
    required this.unit,
    this.onTap,
    this.showHoverLabel = true,
  });

  @override
  State<LevelTile> createState() => _LevelTileState();
}

class _LevelTileState extends State<LevelTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 120), // Fast press
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92, // Slightly more pronounced scale
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // Fast easing out
    ));
    
    _shadowAnimation = Tween<double>(
      begin: 4.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // Fast easing out
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (_canInteract()) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _resetPress();
  }

  void _onTapCancel() {
    _resetPress();
  }

  void _resetPress() {
    // Create slower bouncy landing animation
    _animationController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 250), // Slower landing
      curve: Curves.elasticOut, // Bouncy landing effect
    );
  }

  bool _canInteract() {
    return widget.level.status != LevelStatus.locked || 
           widget.level.type == LevelType.fastForward;
  }

  @override
  Widget build(BuildContext context) {
    // Decreased by 25% from previous 50% increase: 98 * 1.5 * 0.75 = 110
    final containerWidth = widget.level.type == LevelType.chest ? 150.0 : 110.0; // Chest twice as big
    final containerHeight = widget.level.type == LevelType.chest ? 120.0 : 105.0; // Chest twice as big
    
    return SizedBox(
      width: containerWidth,
      height: containerHeight,
      child: Stack(
        clipBehavior: Clip.none, // Allow overflow for label
        children: [
          // Main tile with shadow and 3D effect (rendered first, behind label)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildTileWithShadow(),
              );
            },
          ),
          
          // Hover label (positioned above tile) - rendered last, on top of everything
          if (widget.showHoverLabel && 
              widget.level.getHoverLabel() != null &&
              widget.level.getHoverLabel() != 'OPEN') // Remove OPEN labels
            Positioned(
              top: -8, // Higher position so it doesn't touch the star SVG
              left: (containerWidth - _getLabelWidth()) / 2 - 8, // Move 8px to the left for better centering
              child: getLevelLabel(
                widget.level.getHoverLabel(),
                textColor: widget.unit.backgroundColor, // Use unit's color for text
              ) ?? const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildTileWithShadow() {
    // Decreased by 25% from the previous 50% increase
    // Normal: 64 * 1.5 * 0.75 = 72
    // Chest: 80 * 1.5 * 0.75 = 90, but make it twice as big = 144
    final tileSize = widget.level.type == LevelType.chest
      ? const Size(144, 115) // Chest type - twice as big
      : const Size(72, 72); // Normal type - decreased by 25%
    
    return Center(
      child: SizedBox(
        width: tileSize.width,
        height: tileSize.height,
        child: Stack(
          children: [
            // For chest levels, don't show circle background
            if (widget.level.type != LevelType.chest) ...[
              // Shadow layer (transform: translateY(4))
              AnimatedBuilder(
                animation: _shadowAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _shadowAnimation.value),
                    child: _buildTileButton(
                      color: widget.level.getBorderColor(widget.unit.backgroundColor),
                      isShadow: true,
                    ),
                  );
                },
              ),
              
              // Main button layer
              _buildTileButton(
                color: widget.level.getColor(widget.unit.backgroundColor),
                isShadow: false,
              ),
            ] else ...[
              // For chest levels, just show the icon directly
              Center(child: _buildIcon()),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTileButton({
    required Color color,
    required bool isShadow,
  }) {
    final tileSize = widget.level.type == LevelType.chest
      ? const Size(144, 115) 
      : const Size(72, 72);

    return GestureDetector(
      onTapDown: isShadow ? null : _onTapDown,
      onTapUp: isShadow ? null : _onTapUp,
      onTapCancel: isShadow ? null : _onTapCancel,
      onTap: isShadow ? null : (_canInteract() ? widget.onTap : null),
      child: Container(
        width: tileSize.width,
        height: tileSize.height,
        decoration: BoxDecoration(
          color: isShadow 
            ? color.withOpacity(0.8) 
            : (_canInteract() ? color : _getLockedColor()),
          borderRadius: BorderRadius.circular(tileSize.height / 2),
          border: isShadow 
            ? null 
            : Border.all(
                color: widget.level.getBorderColor(widget.unit.backgroundColor),
                width: isShadow ? 0 : 6, // Increased border for larger tiles
              ),
          boxShadow: isShadow 
            ? null 
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
        ),
        child: isShadow ? null : _buildIcon(),
      ),
    );
  }

  Widget _buildIcon() {
    // Adjusted icon sizes for the new tile sizes
    final iconSize = widget.level.type == LevelType.chest 
        ? 75.0  // Increased by 25% from 60.0
        : widget.level.type == LevelType.dumbbell 
            ? 35.0  // Make dumbbell bigger than other icons
            : 27.0; // Others 25% smaller
    
    // For chest levels, use PNG image instead of SVG icon
    if (widget.level.type == LevelType.chest) {
      return ColorFiltered(
        colorFilter: widget.level.status == LevelStatus.locked 
          ? const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0, // Red
              0.2126, 0.7152, 0.0722, 0, 0, // Green  
              0.2126, 0.7152, 0.0722, 0, 0, // Blue
              0,      0,      0,      1, 0, // Alpha
            ])
          : const ColorFilter.matrix([
              1, 0, 0, 0, 0,
              0, 1, 0, 0, 0,
              0, 0, 1, 0, 0,
              0, 0, 0, 1, 0,
            ]),
        child: Image.asset(
          'assets/images/gift.png', // Using gift.png for chest
          width: iconSize,
          height: iconSize,
        ),
      );
    }
    
    return Center(
      child: getLevelIcon(
        widget.level, 
        size: iconSize,
      ),
    );
  }

  Color _getLockedColor() {
    return const Color(0xFFE5E5E5); // Light gray for locked levels
  }

  double _getLabelWidth() {
    final labelText = widget.level.getHoverLabel();
    if (labelText == null) return 0;
    
    // Approximate width calculation for common labels
    switch (labelText.toUpperCase()) {
      case 'START':
        return 60;
      case 'JUMP HERE?':
        return 90;
      case 'OPEN':
        return 50;
      default:
        return labelText.length * 8.0 + 24; // Approximate
    }
  }
}

/// Custom scroll behavior to remove overscroll glow
class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
