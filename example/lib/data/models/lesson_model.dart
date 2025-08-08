import 'package:flutter/material.dart';
import 'page_model.dart';

/// Model representing a complete lesson containing multiple pages
/// Each lesson is associated with a specific unit and level
class LessonModel {
  final String id;
  final String unitId;
  final String levelId;
  final String title;
  final String? description;
  final List<PageModel> pages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LessonModel({
    required this.id,
    required this.unitId,
    required this.levelId,
    required this.title,
    this.description,
    required this.pages,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a new lesson with a single blank page
  factory LessonModel.blank({
    required String unitId,
    required String levelId,
    String? title,
    String? description,
  }) {
    final now = DateTime.now();
    return LessonModel(
      id: 'lesson_${unitId}_${levelId}',
      unitId: unitId,
      levelId: levelId,
      title: title ?? 'Unit $unitId - Level $levelId',
      description: description,
      pages: [PageModel.blank()],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates a lesson with multiple sample pages for testing
  factory LessonModel.sample({
    required String unitId,
    required String levelId,
    String? title,
  }) {
    final now = DateTime.now();
    return LessonModel(
      id: 'lesson_${unitId}_${levelId}',
      unitId: unitId,
      levelId: levelId,
      title: title ?? 'Sample Lesson - Unit $unitId Level $levelId',
      description: 'A sample lesson with multiple pages',
      pages: [
        PageModel.blank(
          id: 'page_1',
          backgroundColor: const Color(0xFF58CC02),
          randomPlaceholder: true,
        ),
        PageModel.blank(
          id: 'page_2', 
          backgroundColor: const Color(0xFF1CB0F6),
          randomPlaceholder: true,
        ),
        PageModel.blank(
          id: 'page_3',
          backgroundColor: const Color(0xFF9C27B0),
          randomPlaceholder: false,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Gets the total number of pages in this lesson
  int get pageCount => pages.length;

  /// Checks if the lesson is empty (no pages)
  bool get isEmpty => pages.isEmpty;

  /// Checks if the lesson has only one page
  bool get isSinglePage => pages.length == 1;

  /// Gets a page by index (returns null if index is out of bounds)
  PageModel? getPageAt(int index) {
    if (index < 0 || index >= pages.length) return null;
    return pages[index];
  }

  /// Inserts a page at the specified index
  LessonModel insertPage(int index, PageModel page) {
    final newPages = List<PageModel>.from(pages);
    if (index <= 0) {
      newPages.insert(0, page);
    } else if (index >= newPages.length) {
      newPages.add(page);
    } else {
      newPages.insert(index, page);
    }

    return copyWith(
      pages: newPages,
      updatedAt: DateTime.now(),
    );
  }

  /// Removes a page at the specified index
  LessonModel removePage(int index) {
    if (index < 0 || index >= pages.length || pages.length <= 1) {
      return this; // Don't remove if invalid index or only one page
    }

    final newPages = List<PageModel>.from(pages);
    newPages.removeAt(index);

    return copyWith(
      pages: newPages,
      updatedAt: DateTime.now(),
    );
  }

  /// Updates a page at the specified index
  LessonModel updatePage(int index, PageModel updatedPage) {
    if (index < 0 || index >= pages.length) return this;

    final newPages = List<PageModel>.from(pages);
    newPages[index] = updatedPage;

    return copyWith(
      pages: newPages,
      updatedAt: DateTime.now(),
    );
  }

  /// Copy with new properties
  LessonModel copyWith({
    String? id,
    String? unitId,
    String? levelId,
    String? title,
    String? description,
    List<PageModel>? pages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonModel(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      levelId: levelId ?? this.levelId,
      title: title ?? this.title,
      description: description ?? this.description,
      pages: pages ?? this.pages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitId': unitId,
      'levelId': levelId,
      'title': title,
      'description': description,
      'pages': pages.map((page) => page.toJson()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      unitId: json['unitId'] as String,
      levelId: json['levelId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      pages: (json['pages'] as List<dynamic>)
          .map((pageJson) => PageModel.fromJson(pageJson as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LessonModel &&
        other.id == id &&
        other.unitId == unitId &&
        other.levelId == levelId &&
        other.title == title &&
        other.description == description;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        unitId.hashCode ^
        levelId.hashCode ^
        title.hashCode ^
        description.hashCode;
  }

  @override
  String toString() {
    return 'LessonModel(id: $id, unitId: $unitId, levelId: $levelId, title: $title, pages: ${pages.length})';
  }
}
