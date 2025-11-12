import 'package:flutter/foundation.dart';
import '../models/unit_model.dart';
import '../models/level_model.dart';
import '../../config/level_positions.dart';

/// Provider for managing units state and progression
/// Features:
/// - Track unit progress and completion
/// - Handle level unlocking and status updates
/// - Manage user progression through learning path
/// - Future-ready for CRUD operations with Hive
class UnitsProvider extends ChangeNotifier {
  List<UnitModel> _units = [];
  String? _currentUnitId;
  String? _currentLevelId;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<UnitModel> get units => List.unmodifiable(_units);
  String? get currentUnitId => _currentUnitId;
  String? get currentLevelId => _currentLevelId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Gets the current active unit
  UnitModel? get currentUnit {
    if (_currentUnitId == null) return null;
    try {
      return _units.firstWhere((unit) => unit.id == _currentUnitId);
    } catch (_) {
      return null;
    }
  }

  /// Gets the current active level
  LevelModel? get currentLevel {
    final unit = currentUnit;
    if (unit == null || _currentLevelId == null) return null;
    
    try {
      return unit.levels.firstWhere((level) => level.id == _currentLevelId);
    } catch (_) {
      return null;
    }
  }

  /// Gets the next available level to play
  LevelModel? get nextLevel {
    final unit = currentUnit;
    if (unit == null) return null;
    
    return unit.nextLevel;
  }

  /// Gets total completion percentage across all units
  double get overallProgress {
    if (_units.isEmpty) return 0.0;
    
    final totalLevels = _units.fold<int>(0, (sum, unit) => sum + unit.levels.length);
    if (totalLevels == 0) return 0.0;
    
    final completedLevels = _units.fold<int>(0, (sum, unit) {
      return sum + unit.levels.where((level) => level.status == LevelStatus.completed).length;
    });
    
    return completedLevels / totalLevels;
  }

  /// Gets units available for the current section
  List<UnitModel> getUnitsForSection(String sectionId) {
    // For now, return all units. Future: filter by section
    return _units;
  }

  /// Initialize with mock data
  Future<void> loadUnits() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _units = _generateMockUnits();
      
      // Set initial current unit/level if none set
      if (_currentUnitId == null && _units.isNotEmpty) {
        _currentUnitId = _units.first.id;
        final firstUnit = _units.first;
        if (firstUnit.levels.isNotEmpty) {
          _currentLevelId = firstUnit.levels.first.id;
        }
      }
      
      notifyListeners();
    } catch (error) {
      _setError('Failed to load units: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Updates a level's status
  Future<void> updateLevelStatus(String unitId, String levelId, LevelStatus newStatus) async {
    try {
      final unitIndex = _units.indexWhere((unit) => unit.id == unitId);
      if (unitIndex == -1) {
        throw Exception('Unit not found: $unitId');
      }

      final updatedUnit = _units[unitIndex].updateLevelStatus(levelId, newStatus);
      _units[unitIndex] = updatedUnit;

      // Update current level if this is a current/unlocked level
      if (newStatus == LevelStatus.current) {
        _currentUnitId = unitId;
        _currentLevelId = levelId;
      }

      // Auto-unlock next level if current was completed
      if (newStatus == LevelStatus.completed) {
        await _autoUnlockNextLevel(unitId, levelId);
      }

      notifyListeners();
    } catch (error) {
      _setError('Failed to update level: $error');
    }
  }

  /// Marks a level as completed and unlocks the next one
  Future<void> completeLevel(String unitId, String levelId) async {
    await updateLevelStatus(unitId, levelId, LevelStatus.completed);
  }

  /// Starts a level (sets as current)
  Future<void> startLevel(String unitId, String levelId) async {
    await updateLevelStatus(unitId, levelId, LevelStatus.current);
  }

  /// Unlocks all levels in a unit (for debugging/testing)
  Future<void> unlockAllLevelsInUnit(String unitId) async {
    try {
      final unitIndex = _units.indexWhere((unit) => unit.id == unitId);
      if (unitIndex == -1) return;

      final unit = _units[unitIndex];
      final updatedLevels = unit.levels.map((level) {
        if (level.status == LevelStatus.locked) {
          return level.copyWith(status: LevelStatus.unlocked);
        }
        return level;
      }).toList();

      _units[unitIndex] = unit.copyWith(levels: updatedLevels);
      notifyListeners();
    } catch (error) {
      _setError('Failed to unlock levels: $error');
    }
  }

  /// Resets all progress (for debugging/testing)
  Future<void> resetProgress() async {
    try {
      _units = _generateMockUnits();
      _currentUnitId = _units.isNotEmpty ? _units.first.id : null;
      _currentLevelId = null;
      
      if (_units.isNotEmpty && _units.first.levels.isNotEmpty) {
        _currentLevelId = _units.first.levels.first.id;
      }
      
      notifyListeners();
    } catch (error) {
      _setError('Failed to reset progress: $error');
    }
  }

  /// Auto-unlocks the next level after completing one
  Future<void> _autoUnlockNextLevel(String unitId, String completedLevelId) async {
    final unitIndex = _units.indexWhere((unit) => unit.id == unitId);
    if (unitIndex == -1) return;

    final unit = _units[unitIndex];
    final completedLevelIndex = unit.levels.indexWhere((level) => level.id == completedLevelId);
    
    if (completedLevelIndex == -1 || completedLevelIndex >= unit.levels.length - 1) {
      // Last level in unit, try to unlock first level of next unit
      if (unitIndex < _units.length - 1) {
        final nextUnit = _units[unitIndex + 1];
        if (nextUnit.levels.isNotEmpty && nextUnit.levels.first.status == LevelStatus.locked) {
          _units[unitIndex + 1] = nextUnit.updateLevelStatus(
            nextUnit.levels.first.id, 
            LevelStatus.unlocked
          );
        }
      }
      return;
    }

    // Unlock next level in same unit
    final nextLevel = unit.levels[completedLevelIndex + 1];
    if (nextLevel.status == LevelStatus.locked) {
      _units[unitIndex] = unit.updateLevelStatus(nextLevel.id, LevelStatus.unlocked);
    }
  }

  /// Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _clearError();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
  }

  void _clearError() {
    _error = null;
  }

  /// Generates mock units data for development
  List<UnitModel> _generateMockUnits() {
    return [
      // Unit 1: Basic Arabic Letters
      UnitModel.withColorScheme(
        id: 'unit_1',
        number: 1,
        title: 'Basic Letters',
        description: 'Learn the fundamentals of Arabic letters',
        levels: _generateLevelsForUnit(1, 8),
      ),
      
      // Unit 2: Letter Combinations
      UnitModel.withColorScheme(
        id: 'unit_2',
        number: 2,
        title: 'Letter Combinations',
        description: 'Combine letters to form simple words',
        levels: _generateLevelsForUnit(2, 10),
      ),
      
      // Unit 3: Basic Words
      UnitModel.withColorScheme(
        id: 'unit_3',
        number: 3,
        title: 'Basic Words',
        description: 'Practice reading and writing basic Arabic words',
        levels: _generateLevelsForUnit(3, 12),
      ),
    ];
  }

  /// Generates levels for a specific unit
  List<LevelModel> _generateLevelsForUnit(int unitNumber, int levelCount) {
    final levels = <LevelModel>[];
    final pattern = LevelPositionConfig.getPatternForUnit(unitNumber);
    
    // Determine if this unit should have unlocked levels
    final isFirstUnit = unitNumber == 1;
    final hasUnlockedLevels = isFirstUnit;
    
    for (int i = 0; i < levelCount; i++) {
      final horizontalOffset = pattern[i % pattern.length];
      
      // Determine level type based on position
      LevelType type;
      if (i == 0) {
        type = LevelType.star;
      } else if (i == levelCount - 1) {
        type = LevelType.trophy;
      } else if (i % 4 == 0) {
        type = LevelType.chest;
      } else if (i % 3 == 0) {
        type = LevelType.dumbbell;
      } else {
        type = LevelType.book;
      }
      
      // Determine initial status
      LevelStatus status;
      if (hasUnlockedLevels) {
        if (i == 0) {
          status = LevelStatus.current; // First level is current
        } else {
          status = LevelStatus.locked; // All other levels locked
        }
      } else {
        status = LevelStatus.locked; // All locked for non-first units
      }
      
      levels.add(LevelModel(
        id: 'level_${unitNumber}_${i + 1}',
        index: i,
        type: type,
        status: status,
        title: 'Level ${i + 1}',
        horizontalOffset: horizontalOffset,
        showStartLabel: (hasUnlockedLevels && i == 0), // Show START on first level of unlocked units
        isSpecialWidth: type == LevelType.chest,
      ));
    }
    
    // Add jump button ONLY at the beginning of locked units (not first unit)
    if (!hasUnlockedLevels && levels.isNotEmpty) {
      levels.insert(0, LevelModel(
        id: 'jump_${unitNumber}_0',
        index: 0,
        type: LevelType.fastForward,
        status: LevelStatus.locked,
        title: 'Jump Here',
        horizontalOffset: pattern[0],
        showStartLabel: false,
        isSpecialWidth: false,
      ));
      
      // Update indices for the rest of the levels
      for (int i = 1; i < levels.length; i++) {
        levels[i] = levels[i].copyWith(index: i);
      }
    }
    
    return levels;
  }
}
