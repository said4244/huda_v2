import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/level_model.dart';

/// Level icons using actual SVG assets from the project
/// Updated to use specific asset files as requested:
/// - Star: star-in-lesson-white.svg
/// - Book: book.svg 
/// - Dumbbell: dumbbell.svg
/// - Jump Here: next.svg
/// - Chest: chest.png (PNG image, not SVG)

/// Star icon widget using SVG asset
class StarIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const StarIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/star-in-lesson-white.svg',
      width: size,
      height: size,
      colorFilter: color != null 
        ? ColorFilter.mode(color!, BlendMode.srcIn)
        : null,
    );
  }
}

/// Book icon widget using SVG asset
class BookIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const BookIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/book.svg',
      width: size,
      height: size,
      colorFilter: color != null 
        ? ColorFilter.mode(color!, BlendMode.srcIn)
        : null,
    );
  }
}

/// Dumbbell icon widget using SVG asset
class DumbbellIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const DumbbellIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/dumbbell.svg',
      width: size,
      height: size,
      colorFilter: color != null 
        ? ColorFilter.mode(color!, BlendMode.srcIn)
        : null,
    );
  }
}

/// Next/Jump Here icon widget using SVG asset
class NextIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const NextIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/next.svg',
      width: size,
      height: size,
      colorFilter: color != null 
        ? ColorFilter.mode(color!, BlendMode.srcIn)
        : null,
    );
  }
}

/// Trophy icon widget using SVG asset
class TrophyIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const TrophyIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/bronze-league.svg',
      width: size,
      height: size,
      colorFilter: color != null 
        ? ColorFilter.mode(color!, BlendMode.srcIn)
        : null,
    );
  }
}

/// Chest icon widget using PNG asset (handled separately in level_tile.dart)
class ChestIcon extends StatelessWidget {
  final double size;
  final bool isLocked;

  const ChestIcon({
    super.key,
    this.size = 24.0,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/gift.png', // Using gift.png for chest
      width: size,
      height: size,
      color: isLocked ? Colors.grey : null,
      colorBlendMode: isLocked ? BlendMode.saturation : null,
    );
  }
}

/// Checkmark icon for completed levels
class CheckmarkIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const CheckmarkIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/correct-tick-white.svg',
      width: size,
      height: size,
      colorFilter: color != null 
        ? ColorFilter.mode(color!, BlendMode.srcIn)
        : null,
    );
  }
}

/// Utility function to get the appropriate icon for a level
Widget getLevelIcon(LevelModel level, {double size = 24.0}) {
  final color = level.status == LevelStatus.completed 
    ? Colors.white 
    : Colors.white;

  if (level.status == LevelStatus.completed) {
    return CheckmarkIcon(size: size, color: color);
  }

  switch (level.type) {
    case LevelType.star:
      return StarIcon(size: size, color: color);
    case LevelType.book:
      return BookIcon(size: size, color: color);
    case LevelType.dumbbell:
      return DumbbellIcon(size: size, color: color);
    case LevelType.chest:
      // Chest is handled separately as PNG in level_tile.dart
      return Container(width: size, height: size);
    case LevelType.trophy:
      return TrophyIcon(size: size, color: color);
    case LevelType.fastForward:
      return NextIcon(size: size, color: color);
  }
}
