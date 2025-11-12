import 'package:flutter/material.dart';
import '../../data/models/unit_model.dart';
import '../../data/models/level_model.dart';

/// Header widget for each unit section
/// Features:
/// - Full width rounded container with unit colors
/// - Unit number, title, and description
/// - Progress indicator showing completion percentage
/// - Responsive design for mobile and desktop
/// - Jump button for units with skip functionality
class UnitHeader extends StatelessWidget {
  final UnitModel unit;
  final VoidCallback? onJumpTap;
  final bool showProgress;

  const UnitHeader({
    super.key,
    required this.unit,
    this.onJumpTap,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 8,
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: unit.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unit.borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: unit.borderColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with unit info and optional jump button
          Row(
            children: [
              Expanded(
                child: _buildUnitInfo(isMobile),
              ),
              
              if (unit.showJumpButton && onJumpTap != null)
                _buildJumpButton(isMobile),
            ],
          ),
          
          // Progress indicator (if enabled and unit has progress)
          if (showProgress && unit.levels.isNotEmpty)
            ..._buildProgressSection(isMobile),
        ],
      ),
    );
  }

  Widget _buildUnitInfo(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unit number and title
        Row(
          children: [
            _buildUnitBadge(isMobile),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                unit.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 6),
        
        // Unit description
        Text(
          unit.description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildUnitBadge(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        'Unit ${unit.number}',
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 12 : 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildJumpButton(bool isMobile) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onJumpTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fast_forward,
                color: Colors.white,
                size: isMobile ? 16 : 18,
              ),
              const SizedBox(width: 6),
              Text(
                'JUMP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProgressSection(bool isMobile) {
    final completionPercentage = unit.completionPercentage;
    final completedLevels = unit.levels
        .where((level) => level.status == LevelStatus.completed)
        .length;
    final totalLevels = unit.levels.length;

    return [
      const SizedBox(height: 12),
      
      // Progress bar
      Container(
        height: 6,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(3),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: completionPercentage,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
      
      const SizedBox(height: 6),
      
      // Progress text
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$completedLevels of $totalLevels completed',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          if (completionPercentage > 0)
            Text(
              '${(completionPercentage * 100).round()}%',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    ];
  }
}
