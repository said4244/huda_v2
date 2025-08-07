import 'package:flutter/material.dart';

/// Level types in the learning path
enum LevelType { 
  star, 
  book, 
  dumbbell, 
  chest, 
  trophy, 
  fastForward 
}

/// Status of a level
enum LevelStatus { 
  locked, 
  unlocked, 
  current, 
  completed 
}

/// Model representing a single level in a unit
class LevelModel {
  final String id;
  final int index;
  final LevelType type;
  final LevelStatus status;
  final String? title;
  final int horizontalOffset; // -70, -45, 0, 45, 70 pixels
  final bool showStartLabel;
  final bool isSpecialWidth; // chest = 80x64, others = 64x64

  const LevelModel({
    required this.id,
    required this.index,
    required this.type,
    required this.status,
    this.title,
    required this.horizontalOffset,
    this.showStartLabel = false,
    this.isSpecialWidth = false,
  });

  /// Returns the appropriate color based on status and level type
  Color getColor(Color unitColor) {
    switch (status) {
      case LevelStatus.locked:
        return const Color(0xFFE5E5E5); // Light gray
      case LevelStatus.current:
        return unitColor; // Unit theme color
      case LevelStatus.completed:
        return const Color(0xFFFFD700); // Gold
      case LevelStatus.unlocked:
        return unitColor; // Unit theme color
    }
  }

  /// Returns the border color (darker shade of main color)
  Color getBorderColor(Color unitColor) {
    switch (status) {
      case LevelStatus.locked:
        return const Color(0xFFCCCCCC); // Darker gray
      case LevelStatus.current:
      case LevelStatus.unlocked:
        return _darken(unitColor, 0.2);
      case LevelStatus.completed:
        return const Color(0xFFDAA520); // Darker gold
    }
  }

  /// Gets the appropriate icon asset path
  String getIconAsset() {
    const String basePath = 'assets/svg/';
    
    switch (type) {
      case LevelType.star:
        return '${basePath}star-in-lesson-white.svg';
      case LevelType.book:
        return '${basePath}book.svg';
      case LevelType.dumbbell:
        return '${basePath}dumbbell.svg';
      case LevelType.chest:
        return 'assets/images/gift.png'; // PNG for chest
      case LevelType.trophy:
        return '${basePath}bronze-league.svg';
      case LevelType.fastForward:
        return '${basePath}next.svg';
    }
  }

  /// Gets the hover label text
  String? getHoverLabel() {
    if (showStartLabel) return 'START';
    // Jump Here only for first level of locked units
    if (status == LevelStatus.locked && type == LevelType.fastForward && index == 0) {
      return 'JUMP HERE?';
    }
    // Remove OPEN labels completely
    return null;
  }

  /// Copy with new properties
  LevelModel copyWith({
    String? id,
    int? index,
    LevelType? type,
    LevelStatus? status,
    String? title,
    int? horizontalOffset,
    bool? showStartLabel,
    bool? isSpecialWidth,
  }) {
    return LevelModel(
      id: id ?? this.id,
      index: index ?? this.index,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      horizontalOffset: horizontalOffset ?? this.horizontalOffset,
      showStartLabel: showStartLabel ?? this.showStartLabel,
      isSpecialWidth: isSpecialWidth ?? this.isSpecialWidth,
    );
  }

  /// Helper to darken a color
  static Color _darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1');
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LevelModel &&
        other.id == id &&
        other.index == index &&
        other.type == type &&
        other.status == status &&
        other.title == title &&
        other.horizontalOffset == horizontalOffset &&
        other.showStartLabel == showStartLabel &&
        other.isSpecialWidth == isSpecialWidth;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        index.hashCode ^
        type.hashCode ^
        status.hashCode ^
        title.hashCode ^
        horizontalOffset.hashCode ^
        showStartLabel.hashCode ^
        isSpecialWidth.hashCode;
  }

  @override
  String toString() {
    return 'LevelModel(id: $id, index: $index, type: $type, status: $status, title: $title, horizontalOffset: $horizontalOffset, showStartLabel: $showStartLabel, isSpecialWidth: $isSpecialWidth)';
  }
}
