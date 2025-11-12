import 'package:flutter/foundation.dart';

/// Provider for managing lesson progress state
/// Tracks total pages and completed pages for the current lesson
/// Provides smooth animated updates to the progress bar
class LessonProgressProvider extends ChangeNotifier {
  int _totalPages = 0;
  int _completedPages = 0;

  /// Get the total number of pages in the current lesson
  int get totalPages => _totalPages;
  
  /// Get the number of completed pages
  int get completedPages => _completedPages;
  
  /// Get the progress as a fraction (0.0 to 1.0)
  double get progressFraction {
    if (_totalPages == 0) return 0.0;
    return (_completedPages / _totalPages).clamp(0.0, 1.0);
  }
  
  /// Get the progress as a percentage (0 to 100)
  double get progressPercentage => progressFraction * 100;
  
  /// Check if the lesson is completed
  bool get isCompleted => _completedPages >= _totalPages && _totalPages > 0;

  /// Initialize or reset the progress for a new lesson
  /// This should be called when a lesson is loaded
  void setTotalPages(int total) {
    if (total < 0) total = 0;
    _totalPages = total;
    _completedPages = 0;
    print('📊 LessonProgressProvider: Set total pages to $_totalPages, reset completed to 0');
    notifyListeners();
  }

  /// Mark one page as completed
  /// Called when a page is finished (first continue click)
  void incrementCompleted() {
    if (_completedPages < _totalPages) {
      _completedPages++;
      print('📊 LessonProgressProvider: Incremented completed to $_completedPages/$_totalPages (${progressPercentage.toStringAsFixed(1)}%)');
      notifyListeners();
    } else {
      print('📊 LessonProgressProvider: Cannot increment - already at maximum ($_completedPages/$_totalPages)');
    }
  }

  /// Set completed pages directly (useful for navigation or admin features)
  void setCompletedPages(int completed) {
    if (completed < 0) completed = 0;
    if (completed > _totalPages) completed = _totalPages;
    
    if (_completedPages != completed) {
      _completedPages = completed;
      print('📊 LessonProgressProvider: Set completed pages to $_completedPages/$_totalPages (${progressPercentage.toStringAsFixed(1)}%)');
      notifyListeners();
    }
  }

  /// Reset all progress (useful for restarting a lesson)
  void reset() {
    _totalPages = 0;
    _completedPages = 0;
    print('📊 LessonProgressProvider: Reset all progress');
    notifyListeners();
  }

  /// Get progress info for debugging
  Map<String, dynamic> getProgressInfo() {
    return {
      'totalPages': _totalPages,
      'completedPages': _completedPages,
      'progressFraction': progressFraction,
      'progressPercentage': progressPercentage,
      'isCompleted': isCompleted,
    };
  }

  @override
  String toString() {
    return 'LessonProgressProvider(completed: $_completedPages/$_totalPages, ${progressPercentage.toStringAsFixed(1)}%)';
  }
}
