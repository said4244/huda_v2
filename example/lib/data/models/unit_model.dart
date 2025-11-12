import 'package:flutter/material.dart';
import 'level_model.dart';
import '../../config/level_positions.dart';

/// Model representing a learning unit with its levels
class UnitModel {
  final String id;
  final int number;
  final String title;
  final String description;
  final Color backgroundColor; // #58CC02 for Unit 1
  final Color borderColor;     // #46A302 for Unit 1
  final List<LevelModel> levels;
  final bool showJumpButton;

  const UnitModel({
    required this.id,
    required this.number,
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.borderColor,
    required this.levels,
    this.showJumpButton = false,
  });

  /// Computed property for zigzag pattern positions
  List<Offset> get levelPositions => 
    LevelPositionCalculator.calculateForUnit(number, levels.length);

  /// Gets the total height needed for this unit
  double get totalHeight {
    return LevelPositionConfig.calculateUnitHeight(levels.length);
  }

  /// Returns true if this unit has any unlocked levels
  bool get hasUnlockedLevels {
    return levels.any((level) => 
      level.status == LevelStatus.unlocked || 
      level.status == LevelStatus.current ||
      level.status == LevelStatus.completed
    );
  }

  /// Returns the current active level (if any)
  LevelModel? get currentLevel {
    try {
      return levels.firstWhere((level) => level.status == LevelStatus.current);
    } catch (_) {
      return null;
    }
  }

  /// Returns the next unlocked level to play
  LevelModel? get nextLevel {
    final unlockedLevels = levels.where((level) => 
      level.status == LevelStatus.unlocked ||
      level.status == LevelStatus.current
    );
    
    if (unlockedLevels.isEmpty) return null;
    
    // Return the current level if exists, otherwise first unlocked
    final current = levels.where((level) => level.status == LevelStatus.current);
    if (current.isNotEmpty) return current.first;
    
    return unlockedLevels.first;
  }

  /// Returns completion percentage (0.0 to 1.0)
  double get completionPercentage {
    if (levels.isEmpty) return 0.0;
    final completedCount = levels.where((level) => level.status == LevelStatus.completed).length;
    return completedCount / levels.length;
  }

  /// Returns true if all levels are completed
  bool get isCompleted {
    return levels.isNotEmpty && levels.every((level) => level.status == LevelStatus.completed);
  }

  /// Updates a specific level's status
  UnitModel updateLevelStatus(String levelId, LevelStatus newStatus) {
    final updatedLevels = levels.map((level) {
      if (level.id == levelId) {
        return level.copyWith(status: newStatus);
      }
      return level;
    }).toList();

    return copyWith(levels: updatedLevels);
  }

  /// Unlocks the next level in sequence
  UnitModel unlockNextLevel() {
    final lockedLevels = levels.where((level) => level.status == LevelStatus.locked).toList();
    if (lockedLevels.isEmpty) return this;

    // Find the first locked level by index
    lockedLevels.sort((a, b) => a.index.compareTo(b.index));
    final nextLevel = lockedLevels.first;

    return updateLevelStatus(nextLevel.id, LevelStatus.unlocked);
  }

  /// Creates unit with predefined color scheme
  factory UnitModel.withColorScheme({
    required String id,
    required int number,
    required String title,
    required String description,
    required List<LevelModel> levels,
    bool showJumpButton = false,
    UnitColorScheme? colorScheme,
  }) {
    final scheme = colorScheme ?? UnitColorScheme.getForUnit(number);
    return UnitModel(
      id: id,
      number: number,
      title: title,
      description: description,
      backgroundColor: scheme.backgroundColor,
      borderColor: scheme.borderColor,
      levels: levels,
      showJumpButton: showJumpButton,
    );
  }

  /// Copy with new properties
  UnitModel copyWith({
    String? id,
    int? number,
    String? title,
    String? description,
    Color? backgroundColor,
    Color? borderColor,
    List<LevelModel>? levels,
    bool? showJumpButton,
  }) {
    return UnitModel(
      id: id ?? this.id,
      number: number ?? this.number,
      title: title ?? this.title,
      description: description ?? this.description,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      levels: levels ?? this.levels,
      showJumpButton: showJumpButton ?? this.showJumpButton,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnitModel &&
        other.id == id &&
        other.number == number &&
        other.title == title &&
        other.description == description &&
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor &&
        other.showJumpButton == showJumpButton;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        number.hashCode ^
        title.hashCode ^
        description.hashCode ^
        backgroundColor.hashCode ^
        borderColor.hashCode ^
        showJumpButton.hashCode;
  }

  @override
  String toString() {
    return 'UnitModel(id: $id, number: $number, title: $title, levels: ${levels.length})';
  }
}

/// Predefined color schemes for units
class UnitColorScheme {
  final Color backgroundColor;
  final Color borderColor;

  const UnitColorScheme({
    required this.backgroundColor,
    required this.borderColor,
  });

  /// Default Duolingo green scheme
  static const UnitColorScheme duolingoGreen = UnitColorScheme(
    backgroundColor: Color(0xFF58CC02), // Duolingo green
    borderColor: Color(0xFF46A302),     // Darker green
  );

  /// Blue scheme for later units
  static const UnitColorScheme blue = UnitColorScheme(
    backgroundColor: Color(0xFF1CB0F6), // Duolingo blue
    borderColor: Color(0xFF1899D6),     // Darker blue
  );

  /// Purple scheme
  static const UnitColorScheme purple = UnitColorScheme(
    backgroundColor: Color(0xFF9C27B0), // Material purple
    borderColor: Color(0xFF7B1FA2),     // Darker purple
  );

  /// Orange scheme
  static const UnitColorScheme orange = UnitColorScheme(
    backgroundColor: Color(0xFFFF9800), // Material orange
    borderColor: Color(0xFFF57C00),     // Darker orange
  );

  /// Red scheme
  static const UnitColorScheme red = UnitColorScheme(
    backgroundColor: Color(0xFFF44336), // Material red
    borderColor: Color(0xFFD32F2F),     // Darker red
  );

  /// Gets color scheme for a specific unit number
  static UnitColorScheme getForUnit(int unitNumber) {
    switch (unitNumber % 5) {
      case 1:
        return duolingoGreen;
      case 2:
        return blue;
      case 3:
        return purple;
      case 4:
        return orange;
      case 0: // unitNumber % 5 == 0
        return red;
      default:
        return duolingoGreen;
    }
  }
}
