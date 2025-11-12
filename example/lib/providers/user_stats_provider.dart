import 'package:flutter/material.dart';

/// Provider for managing user statistics like streaks and diamonds
class UserStatsProvider extends ChangeNotifier {
  int _streakCount = 0;
  int _diamondCount = 0;

  // Getters
  int get streakCount => _streakCount;
  int get diamondCount => _diamondCount;
  
  bool get hasStreak => _streakCount > 0;
  bool get hasDiamonds => _diamondCount > 0;

  // Methods to update stats
  void updateStreak(int newStreak) {
    _streakCount = newStreak;
    notifyListeners();
  }

  void incrementStreak() {
    _streakCount++;
    notifyListeners();
  }

  void resetStreak() {
    _streakCount = 0;
    notifyListeners();
  }

  void updateDiamonds(int newDiamonds) {
    _diamondCount = newDiamonds;
    notifyListeners();
  }

  void addDiamonds(int amount) {
    _diamondCount += amount;
    notifyListeners();
  }

  void spendDiamonds(int amount) {
    if (_diamondCount >= amount) {
      _diamondCount -= amount;
      notifyListeners();
    }
  }

  // Debug method to set test values
  void setTestValues({int? streak, int? diamonds}) {
    if (streak != null) _streakCount = streak;
    if (diamonds != null) _diamondCount = diamonds;
    notifyListeners();
  }
}
