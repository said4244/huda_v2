import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';
import '../models/page_model.dart';

/// Firebase Firestore service for managing lessons and pages
/// Features:
/// - Real-time streaming of lesson pages
/// - CRUD operations for lessons and pages
/// - Auto-indexing for page ordering
/// - Unit/Level based lesson organization
class LessonsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get lesson document ID from unitId and levelId
  String _getLessonId(String unitId, String levelId) => '${unitId}_${levelId}';

  /// Fetch a lesson by unitId and levelId
  /// Returns null if lesson doesn't exist
  Future<LessonModel?> fetchLesson(String unitId, String levelId) async {
    try {
      final lessonId = _getLessonId(unitId, levelId);
      final lessonDoc = await _db.collection('lessons').doc(lessonId).get();
      
      if (!lessonDoc.exists) {
        print('Lesson $lessonId not found in Firestore');
        return null;
      }

      // Get lesson metadata
      final lessonData = lessonDoc.data()!;
      
      // Get pages subcollection
      final pagesSnapshot = await _db
          .collection('lessons')
          .doc(lessonId)
          .collection('pages')
          .orderBy('index')
          .get();

      // Convert pages to PageModel list
      final pages = pagesSnapshot.docs
          .map((doc) => PageModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      print('Fetched lesson $lessonId with ${pages.length} pages');
      
      return LessonModel(
        id: lessonId,
        unitId: unitId,
        levelId: levelId,
        title: lessonData['title'] ?? 'Lesson $unitId-$levelId',
        createdAt: (lessonData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (lessonData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        pages: pages,
      );
    } catch (e) {
      print('Error fetching lesson: $e');
      return null;
    }
  }

  /// Create a new lesson with one blank page
  Future<void> createLesson(String unitId, String levelId) async {
    try {
      final lessonId = _getLessonId(unitId, levelId);
      
      // Create lesson document
      await _db.collection('lessons').doc(lessonId).set({
        'title': 'Lesson $unitId-$levelId',
        'unitId': unitId,
        'levelId': levelId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create first blank page
      final blankPage = PageModel.blank();
      await _db
          .collection('lessons')
          .doc(lessonId)
          .collection('pages')
          .add({
        ...blankPage.toJson(),
        'index': 0,
      });

      print('Created lesson $lessonId with blank page');
    } catch (e) {
      print('Error creating lesson: $e');
      rethrow;
    }
  }

  /// Add a new page to a lesson
  Future<void> addPage(String unitId, String levelId, PageModel page, {int? atIndex}) async {
    try {
      final lessonId = _getLessonId(unitId, levelId);
      
      // Get current pages count to determine index
      final pagesSnapshot = await _db
          .collection('lessons')
          .doc(lessonId)
          .collection('pages')
          .get();

      final targetIndex = atIndex ?? pagesSnapshot.docs.length;
      
      // If inserting at specific index, need to update other page indices
      if (atIndex != null) {
        final batch = _db.batch();
        
        // Update indices of pages that come after the insertion point
        for (final doc in pagesSnapshot.docs) {
          final currentIndex = doc.data()['index'] as int;
          if (currentIndex >= targetIndex) {
            batch.update(doc.reference, {'index': currentIndex + 1});
          }
        }
        
        await batch.commit();
      }

      // Add the new page
      await _db
          .collection('lessons')
          .doc(lessonId)
          .collection('pages')
          .add({
        ...page.toJson(),
        'index': targetIndex,
      });

      print('Added page at index $targetIndex to lesson $lessonId');
    } catch (e) {
      print('Error adding page: $e');
      rethrow;
    }
  }

  /// Update an existing page
  Future<void> updatePage(String unitId, String levelId, String pageId, PageModel page) async {
    try {
      final lessonId = _getLessonId(unitId, levelId);
      
      await _db
          .collection('lessons')
          .doc(lessonId)
          .collection('pages')
          .doc(pageId)
          .update(page.toJson());

      print('Updated page $pageId in lesson $lessonId');
    } catch (e) {
      print('Error updating page: $e');
      rethrow;
    }
  }

  /// Delete a page from a lesson
  Future<void> deletePage(String unitId, String levelId, String pageId) async {
    try {
      final lessonId = _getLessonId(unitId, levelId);
      
      // Get the page to delete to know its index
      final pageDoc = await _db
          .collection('lessons')
          .doc(lessonId)
          .collection('pages')
          .doc(pageId)
          .get();

      if (!pageDoc.exists) {
        print('Page $pageId not found');
        return;
      }

      final deletedIndex = pageDoc.data()!['index'] as int;
      
      // Delete the page
      await pageDoc.reference.delete();
      
      // Update indices of pages that come after the deleted page
      final remainingPages = await _db
          .collection('lessons')
          .doc(lessonId)
          .collection('pages')
          .where('index', isGreaterThan: deletedIndex)
          .get();

      final batch = _db.batch();
      for (final doc in remainingPages.docs) {
        final currentIndex = doc.data()['index'] as int;
        batch.update(doc.reference, {'index': currentIndex - 1});
      }
      await batch.commit();

      print('Deleted page $pageId at index $deletedIndex from lesson $lessonId');
    } catch (e) {
      print('Error deleting page: $e');
      rethrow;
    }
  }

  /// Get real-time stream of pages for a lesson
  Stream<List<PageModel>> pageStream(String unitId, String levelId) {
    final lessonId = _getLessonId(unitId, levelId);
    
    return _db
        .collection('lessons')
        .doc(lessonId)
        .collection('pages')
        .orderBy('index')
        .snapshots()
        .map((snapshot) {
      final pages = snapshot.docs
          .map((doc) => PageModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      print('Page stream updated: ${pages.length} pages for lesson $lessonId');
      return pages;
    });
  }

  /// Check if a lesson exists
  Future<bool> lessonExists(String unitId, String levelId) async {
    try {
      final lessonId = _getLessonId(unitId, levelId);
      final doc = await _db.collection('lessons').doc(lessonId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking lesson existence: $e');
      return false;
    }
  }

  /// Get all lessons (for admin overview)
  Stream<List<Map<String, dynamic>>> allLessonsStream() {
    return _db
        .collection('lessons')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }
}
