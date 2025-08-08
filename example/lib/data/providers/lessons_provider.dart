import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../models/page_model.dart';

/// Provider for managing lessons state and CRUD operations
/// Features:
/// - Load and cache lessons in memory
/// - Create new lessons automatically for admin users
/// - CRUD operations for pages within lessons
/// - Future-ready for Hive or other persistent storage
class LessonsProvider extends ChangeNotifier {
  final Map<String, LessonModel> _lessons = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, LessonModel> get lessons => Map.unmodifiable(_lessons);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Gets a lesson key for the combination of unitId and levelId
  String _getLessonKey(String unitId, String levelId) {
    return '${unitId}_$levelId';
  }

  /// Gets or creates a lesson for the specified unit and level
  /// If admin mode is enabled and no lesson exists, creates a blank lesson
  /// If admin mode is disabled and no lesson exists, returns null
  LessonModel? getLesson(String unitId, String levelId, {bool adminMode = false}) {
    final key = _getLessonKey(unitId, levelId);
    
    // Return existing lesson if found
    if (_lessons.containsKey(key)) {
      return _lessons[key];
    }

    // Create new lesson only in admin mode
    if (adminMode) {
      final newLesson = LessonModel.blank(
        unitId: unitId,
        levelId: levelId,
        title: 'Lesson for Unit $unitId - Level $levelId',
        description: 'Auto-created lesson',
      );
      
      _lessons[key] = newLesson;
      notifyListeners();
      
      print('Created new lesson: ${newLesson.id} for unit $unitId, level $levelId');
      return newLesson;
    }

    // No lesson exists and not in admin mode
    return null;
  }

  /// Creates a sample lesson with multiple pages (for testing)
  LessonModel createSampleLesson(String unitId, String levelId) {
    final key = _getLessonKey(unitId, levelId);
    final sampleLesson = LessonModel.sample(
      unitId: unitId,
      levelId: levelId,
      title: 'Sample Lesson - Unit $unitId Level $levelId',
    );
    
    _lessons[key] = sampleLesson;
    notifyListeners();
    
    print('Created sample lesson: ${sampleLesson.id} with ${sampleLesson.pageCount} pages');
    return sampleLesson;
  }

  /// Inserts a page at the specified index in a lesson
  void insertPage(String unitId, String levelId, int index, PageModel page) {
    final key = _getLessonKey(unitId, levelId);
    final lesson = _lessons[key];
    
    if (lesson == null) {
      print('Error: Lesson not found for unit $unitId, level $levelId');
      return;
    }

    _lessons[key] = lesson.insertPage(index, page);
    notifyListeners();
    
    print('Inserted page at index $index in lesson ${lesson.id}. Total pages: ${_lessons[key]!.pageCount}');
  }

  /// Deletes a page at the specified index in a lesson
  /// Only allows deletion if more than one page exists
  bool deletePage(String unitId, String levelId, int index) {
    final key = _getLessonKey(unitId, levelId);
    final lesson = _lessons[key];
    
    if (lesson == null) {
      print('Error: Lesson not found for unit $unitId, level $levelId');
      return false;
    }

    if (lesson.isSinglePage) {
      print('Cannot delete page: Lesson must have at least one page');
      return false;
    }

    if (index < 0 || index >= lesson.pageCount) {
      print('Error: Invalid page index $index for lesson with ${lesson.pageCount} pages');
      return false;
    }

    _lessons[key] = lesson.removePage(index);
    notifyListeners();
    
    print('Deleted page at index $index in lesson ${lesson.id}. Remaining pages: ${_lessons[key]!.pageCount}');
    return true;
  }

  /// Updates a page at the specified index in a lesson
  void updatePage(String unitId, String levelId, int index, PageModel updatedPage) {
    final key = _getLessonKey(unitId, levelId);
    final lesson = _lessons[key];
    
    if (lesson == null) {
      print('Error: Lesson not found for unit $unitId, level $levelId');
      return;
    }

    if (index < 0 || index >= lesson.pageCount) {
      print('Error: Invalid page index $index for lesson with ${lesson.pageCount} pages');
      return;
    }

    _lessons[key] = lesson.updatePage(index, updatedPage);
    notifyListeners();
    
    print('Updated page at index $index in lesson ${lesson.id}');
  }

  /// Updates the background color of a page
  void updatePageBackgroundColor(String unitId, String levelId, int index, Color newColor) {
    final key = _getLessonKey(unitId, levelId);
    final lesson = _lessons[key];
    
    if (lesson == null || index < 0 || index >= lesson.pageCount) return;

    final currentPage = lesson.pages[index];
    final updatedPage = currentPage.copyWith(backgroundColor: newColor);
    
    updatePage(unitId, levelId, index, updatedPage);
  }

  /// Toggles the random placeholder flag for a page
  void togglePageRandomPlaceholder(String unitId, String levelId, int index) {
    final key = _getLessonKey(unitId, levelId);
    final lesson = _lessons[key];
    
    if (lesson == null || index < 0 || index >= lesson.pageCount) return;

    final currentPage = lesson.pages[index];
    final updatedPage = currentPage.copyWith(randomPlaceholder: !currentPage.randomPlaceholder);
    
    updatePage(unitId, levelId, index, updatedPage);
  }

  /// Deletes an entire lesson
  void deleteLesson(String unitId, String levelId) {
    final key = _getLessonKey(unitId, levelId);
    if (_lessons.containsKey(key)) {
      _lessons.remove(key);
      notifyListeners();
      print('Deleted lesson for unit $unitId, level $levelId');
    }
  }

  /// Checks if a lesson exists for the given unit and level
  bool hasLesson(String unitId, String levelId) {
    final key = _getLessonKey(unitId, levelId);
    return _lessons.containsKey(key);
  }

  /// Gets all lessons for a specific unit
  List<LessonModel> getLessonsForUnit(String unitId) {
    return _lessons.values
        .where((lesson) => lesson.unitId == unitId)
        .toList()
      ..sort((a, b) => a.levelId.compareTo(b.levelId));
  }

  /// Loads lessons from persistent storage (placeholder for future Hive implementation)
  Future<void> loadLessons() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // TODO: Implement Hive loading
      // For now, create some sample lessons for testing
      _createSampleLessons();
      
      notifyListeners();
    } catch (error) {
      _setError('Failed to load lessons: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Saves lessons to persistent storage (placeholder for future Hive implementation)
  Future<void> saveLessons() async {
    try {
      // TODO: Implement Hive saving
      print('Saving ${_lessons.length} lessons to storage...');
      
      // Simulate save delay
      await Future.delayed(const Duration(milliseconds: 200));
      
      print('Lessons saved successfully');
    } catch (error) {
      _setError('Failed to save lessons: $error');
    }
  }

  /// Creates sample lessons for testing and development
  void _createSampleLessons() {
    // Create sample lessons for first unit
    for (int level = 1; level <= 3; level++) {
      createSampleLesson('unit_1', 'level_1_$level');
    }
    
    print('Created sample lessons for testing');
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

  /// Clears all lessons (for testing/debugging)
  void clearAllLessons() {
    _lessons.clear();
    notifyListeners();
    print('Cleared all lessons');
  }

  /// Gets lesson statistics
  Map<String, int> getStatistics() {
    int totalLessons = _lessons.length;
    int totalPages = _lessons.values.fold(0, (sum, lesson) => sum + lesson.pageCount);
    int lessonsWithRandomPlaceholders = _lessons.values
        .where((lesson) => lesson.pages.any((page) => page.randomPlaceholder))
        .length;

    return {
      'totalLessons': totalLessons,
      'totalPages': totalPages,
      'lessonsWithRandomPlaceholders': lessonsWithRandomPlaceholders,
    };
  }
}
