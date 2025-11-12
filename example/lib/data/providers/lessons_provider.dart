import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/lesson_model.dart';
import '../models/page_model.dart';

/// Provider for managing lessons state and CRUD operations with Hive persistence
/// Features:
/// - Load and cache lessons from Hive storage
/// - Create new lessons automatically for admin users
/// - CRUD operations for pages within lessons with automatic persistence
/// - Real-time data persistence using Hive Box
class LessonsProvider extends ChangeNotifier {
  final Box _box;
  final Map<String, LessonModel> _lessons = {};
  bool _isLoading = false;
  String? _error;

  /// Constructor that accepts a Hive box for persistence
  LessonsProvider(this._box) {
    _loadFromStorage();
  }

  /// Load lessons from Hive storage on initialization
  void _loadFromStorage() {
    try {
      final stored = _box.get('data');
      if (stored is Map<String, dynamic>) {
        final Map<String, dynamic> lessonsData = Map<String, dynamic>.from(stored);
        _lessons.clear();
        
        for (final entry in lessonsData.entries) {
          final lessonJson = Map<String, dynamic>.from(entry.value);
          _lessons[entry.key] = LessonModel.fromJson(lessonJson);
        }
        
        print('Loaded ${_lessons.length} lessons from storage');
      } else {
        print('No existing lessons found in storage, starting fresh');
      }
    } catch (error) {
      print('Error loading lessons from storage: $error');
      _setError('Failed to load lessons from storage: $error');
    }
  }

  /// Save lessons to Hive storage
  void _saveToDisk() {
    try {
      final data = _lessons.map((key, lesson) => MapEntry(key, lesson.toJson()));
      _box.put('data', data);
      print('Saved ${_lessons.length} lessons to storage');
    } catch (error) {
      print('Error saving lessons to storage: $error');
      _setError('Failed to save lessons to storage: $error');
    }
  }

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
      _saveToDisk(); // Persist to storage
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
    _saveToDisk(); // Persist to storage
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
    _saveToDisk(); // Persist to storage
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
    _saveToDisk(); // Persist to storage
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
    _saveToDisk(); // Persist to storage
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
      _saveToDisk(); // Persist to storage
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

  /// Loads lessons from persistent storage (now uses Hive)
  Future<void> loadLessons() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Data is already loaded in constructor via _loadFromStorage()
      // This method is kept for compatibility with existing UI
      
      notifyListeners();
    } catch (error) {
      _setError('Failed to load lessons: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Saves lessons to persistent storage (now uses Hive)
  Future<void> saveLessons() async {
    try {
      // Data is automatically saved after each operation via _saveToDisk()
      // This method is kept for compatibility with existing UI
      print('Lessons are automatically saved after each operation');
    } catch (error) {
      _setError('Failed to save lessons: $error');
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

  /// Clears all lessons (for testing/debugging)
  void clearAllLessons() {
    _lessons.clear();
    _saveToDisk(); // Persist to storage
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
