import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/lesson_model.dart';
import '../models/page_model.dart';
import '../services/lessons_service.dart';

/// Provider for managing lessons state and CRUD operations with Firebase Firestore
/// Features:
/// - Real-time streaming from Firestore
/// - CRUD operations for lessons and pages with Firebase persistence
/// - Optional Hive caching for offline support
/// - Automatic lesson creation for admin users
class LessonsProvider extends ChangeNotifier {
  final LessonsService _lessonsService;
  final Box _cacheBox; // Optional local cache
  final Map<String, LessonModel> _lessons = {};
  final Map<String, Stream<List<PageModel>>> _pageStreams = {};
  bool _isLoading = false;
  String? _error;

  /// Constructor that accepts Firebase service and optional Hive cache
  LessonsProvider(this._lessonsService, this._cacheBox);

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get availableLessons => _lessons.keys.toList();

  /// Get a lesson by unitId and levelId, fetch from Firestore if not cached
  Future<LessonModel?> getLesson(String unitId, String levelId, {bool adminLogin = false}) async {
    final lessonId = '${unitId}_${levelId}';
    
    // Return cached lesson if available
    if (_lessons.containsKey(lessonId)) {
      return _lessons[lessonId];
    }

    _setLoading(true);
    try {
      // Fetch from Firestore
      final lesson = await _lessonsService.fetchLesson(unitId, levelId);
      
      if (lesson != null) {
        _lessons[lessonId] = lesson;
        _cacheToHive(lessonId, lesson);
        print('Loaded lesson $lessonId from Firestore');
      } else if (adminLogin) {
        // Create new lesson for admin users
        await _lessonsService.createLesson(unitId, levelId);
        final newLesson = await _lessonsService.fetchLesson(unitId, levelId);
        if (newLesson != null) {
          _lessons[lessonId] = newLesson;
          _cacheToHive(lessonId, newLesson);
          print('Created new lesson $lessonId for admin');
        }
        return newLesson;
      }
      
      return lesson;
    } catch (error) {
      _setError('Error loading lesson: $error');
      print('Error in getLesson: $error');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get real-time stream of pages for a lesson
  Stream<List<PageModel>> getPagesStream(String unitId, String levelId) {
    final lessonId = '${unitId}_${levelId}';
    
    if (!_pageStreams.containsKey(lessonId)) {
      _pageStreams[lessonId] = _lessonsService.pageStream(unitId, levelId);
    }
    
    return _pageStreams[lessonId]!;
  }

  /// Insert a new page at the specified index (Firebase)
  Future<void> insertPage(String unitId, String levelId, int index, PageModel page) async {
    _setLoading(true);
    try {
      await _lessonsService.addPage(unitId, levelId, page, atIndex: index);
      
      // Update local cache
      final lessonId = '${unitId}_${levelId}';
      if (_lessons.containsKey(lessonId)) {
        final lesson = _lessons[lessonId]!;
        final updatedLesson = lesson.insertPage(index, page);
        _lessons[lessonId] = updatedLesson;
        _cacheToHive(lessonId, updatedLesson);
      }
      
      print('Inserted page at index $index in lesson $lessonId');
      notifyListeners();
    } catch (error) {
      _setError('Error inserting page: $error');
      print('Error in insertPage: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Remove a page at the specified index (Firebase)
  Future<void> removePage(String unitId, String levelId, int index) async {
    final lessonId = '${unitId}_${levelId}';
    final lesson = _lessons[lessonId];
    
    if (lesson == null || index < 0 || index >= lesson.pages.length) {
      print('Invalid page index or lesson not found');
      return;
    }

    // Get the page to find its Firestore document ID
    final pageToDelete = lesson.pages[index];
    final pageId = pageToDelete.id;

    _setLoading(true);
    try {
      await _lessonsService.deletePage(unitId, levelId, pageId);
      
      // Update local cache
      final updatedLesson = lesson.removePage(index);
      _lessons[lessonId] = updatedLesson;
      _cacheToHive(lessonId, updatedLesson);
      
      print('Removed page at index $index from lesson $lessonId');
      notifyListeners();
    } catch (error) {
      _setError('Error removing page: $error');
      print('Error in removePage: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Update a page at the specified index (Firebase)
  Future<void> updatePage(String unitId, String levelId, int index, PageModel updatedPage) async {
    final lessonId = '${unitId}_${levelId}';
    final lesson = _lessons[lessonId];
    
    if (lesson == null || index < 0 || index >= lesson.pages.length) {
      print('Invalid page index or lesson not found');
      return;
    }

    final pageToUpdate = lesson.pages[index];
    final pageId = pageToUpdate.id;

    _setLoading(true);
    try {
      await _lessonsService.updatePage(unitId, levelId, pageId, updatedPage);
      
      // Update local cache
      final updatedLesson = lesson.updatePage(index, updatedPage);
      _lessons[lessonId] = updatedLesson;
      _cacheToHive(lessonId, updatedLesson);
      
      print('Updated page at index $index in lesson $lessonId');
      notifyListeners();
    } catch (error) {
      _setError('Error updating page: $error');
      print('Error in updatePage: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Move a page from one index to another (Firebase)
  Future<void> movePage(String unitId, String levelId, int fromIndex, int toIndex) async {
    final lessonId = '${unitId}_${levelId}';
    final lesson = _lessons[lessonId];
    
    if (lesson == null || fromIndex < 0 || fromIndex >= lesson.pages.length ||
        toIndex < 0 || toIndex >= lesson.pages.length) {
      print('Invalid indices for page move');
      return;
    }

    if (fromIndex == toIndex) return;

    _setLoading(true);
    try {
      final pageToMove = lesson.pages[fromIndex];
      
      // This is complex in Firestore - we need to update multiple page indices
      // For simplicity, we'll remove and re-add the page
      await _lessonsService.deletePage(unitId, levelId, pageToMove.id);
      await _lessonsService.addPage(unitId, levelId, pageToMove, atIndex: toIndex);
      
      // Update local cache
      final updatedLesson = lesson.movePage(fromIndex, toIndex);
      _lessons[lessonId] = updatedLesson;
      _cacheToHive(lessonId, updatedLesson);
      
      print('Moved page from index $fromIndex to $toIndex in lesson $lessonId');
      notifyListeners();
    } catch (error) {
      _setError('Error moving page: $error');
      print('Error in movePage: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Duplicate a page at the specified index (Firebase)
  Future<void> duplicatePage(String unitId, String levelId, int index) async {
    final lessonId = '${unitId}_${levelId}';
    final lesson = _lessons[lessonId];
    
    if (lesson == null || index < 0 || index >= lesson.pages.length) {
      print('Invalid page index or lesson not found');
      return;
    }

    _setLoading(true);
    try {
      final originalPage = lesson.pages[index];
      final duplicatedPage = originalPage.copyWith(); // Remove id to create new
      
      await _lessonsService.addPage(unitId, levelId, duplicatedPage, atIndex: index + 1);
      
      // Update local cache
      final updatedLesson = lesson.insertPage(index + 1, duplicatedPage);
      _lessons[lessonId] = updatedLesson;
      _cacheToHive(lessonId, updatedLesson);
      
      print('Duplicated page at index $index in lesson $lessonId');
      notifyListeners();
    } catch (error) {
      _setError('Error duplicating page: $error');
      print('Error in duplicatePage: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Update background color of a specific page (Firebase)
  Future<void> updatePageBackgroundColor(String unitId, String levelId, int index, Color color) async {
    final lessonId = '${unitId}_${levelId}';
    final lesson = _lessons[lessonId];
    
    if (lesson == null || index < 0 || index >= lesson.pages.length) {
      print('Invalid page index or lesson not found');
      return;
    }

    final page = lesson.pages[index];
    final updatedPage = page.copyWith(backgroundColor: color);
    await updatePage(unitId, levelId, index, updatedPage);
  }

  /// Toggle random placeholder for a specific page (Firebase)
  Future<void> togglePageRandomPlaceholder(String unitId, String levelId, int index) async {
    final lessonId = '${unitId}_${levelId}';
    final lesson = _lessons[lessonId];
    
    if (lesson == null || index < 0 || index >= lesson.pages.length) {
      print('Invalid page index or lesson not found');
      return;
    }

    final page = lesson.pages[index];
    final updatedPage = page.copyWith(randomPlaceholder: !page.randomPlaceholder);
    await updatePage(unitId, levelId, index, updatedPage);
  }

  /// Update exercise type for a specific page (Firebase)
  Future<void> updatePageExerciseType(String unitId, String levelId, int index, String exerciseType) async {
    final lessonId = '${unitId}_${levelId}';
    final lesson = _lessons[lessonId];
    
    if (lesson == null || index < 0 || index >= lesson.pages.length) {
      print('Invalid page index or lesson not found');
      return;
    }

    final page = lesson.pages[index];
    final updatedPage = page.copyWith(exerciseType: exerciseType);
    await updatePage(unitId, levelId, index, updatedPage);
  }

  /// Check if a lesson exists (Firebase)
  Future<bool> lessonExists(String unitId, String levelId) async {
    try {
      return await _lessonsService.lessonExists(unitId, levelId);
    } catch (error) {
      print('Error checking lesson existence: $error');
      return false;
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _cacheToHive(String lessonId, LessonModel lesson) {
    try {
      _cacheBox.put(lessonId, lesson.toJson());
    } catch (error) {
      print('Error caching to Hive: $error');
    }
  }

  /// Clear all cached data
  void clearCache() {
    _lessons.clear();
    _pageStreams.clear();
    _cacheBox.clear();
    notifyListeners();
  }

  /// Refresh a specific lesson from Firestore
  Future<void> refreshLesson(String unitId, String levelId) async {
    final lessonId = '${unitId}_${levelId}';
    _lessons.remove(lessonId);
    _pageStreams.remove(lessonId);
    await getLesson(unitId, levelId);
  }
}
