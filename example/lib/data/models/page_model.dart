import 'package:flutter/material.dart';

/// Model representing a single page within a lesson
/// Each page can contain different types of exercises and visual elements
class PageModel {
  final String id;
  final Color backgroundColor;
  final bool randomPlaceholder; // Whether to show a random letter placeholder
  final String? exerciseType; // Future: 'multiple_choice', 'fill_blank', etc.
  final Map<String, dynamic>? exerciseData; // Future: exercise-specific data
  final String? title; // Optional page title
  final String? content; // Optional page content

  const PageModel({
    required this.id,
    required this.backgroundColor,
    this.randomPlaceholder = false,
    this.exerciseType,
    this.exerciseData,
    this.title,
    this.content,
  });

  /// Creates a blank page with default settings
  factory PageModel.blank({
    String? id,
    Color? backgroundColor,
    bool randomPlaceholder = false,
  }) {
    return PageModel(
      id: id ?? 'page_${DateTime.now().millisecondsSinceEpoch}',
      backgroundColor: backgroundColor ?? const Color(0xFFF2EFEB), // Fixed background color
      randomPlaceholder: randomPlaceholder,
    );
  }

  /// Creates a page with fixed background color (no more random colors)
  factory PageModel.withRandomColor({
    String? id,
    bool randomPlaceholder = false,
  }) {
    return PageModel(
      id: id ?? 'page_${DateTime.now().millisecondsSinceEpoch}',
      backgroundColor: const Color(0xFFF2EFEB), // Fixed background color
      randomPlaceholder: randomPlaceholder,
    );
  }

  /// Copy with new properties
  PageModel copyWith({
    String? id,
    Color? backgroundColor,
    bool? randomPlaceholder,
    String? exerciseType,
    Map<String, dynamic>? exerciseData,
    String? title,
    String? content,
  }) {
    return PageModel(
      id: id ?? this.id,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      randomPlaceholder: randomPlaceholder ?? this.randomPlaceholder,
      exerciseType: exerciseType ?? this.exerciseType,
      exerciseData: exerciseData ?? this.exerciseData,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'backgroundColor': backgroundColor.value.toInt(),
      'randomPlaceholder': randomPlaceholder,
      'exerciseType': exerciseType,
      'exerciseData': exerciseData,
      'title': title,
      'content': content,
    };
  }

  /// Create from JSON
  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id: json['id'] as String,
      backgroundColor: Color(json['backgroundColor'] as int),
      randomPlaceholder: json['randomPlaceholder'] as bool? ?? false,
      exerciseType: json['exerciseType'] as String?,
      exerciseData: json['exerciseData'] as Map<String, dynamic>?,
      title: json['title'] as String?,
      content: json['content'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageModel &&
        other.id == id &&
        other.backgroundColor == backgroundColor &&
        other.randomPlaceholder == randomPlaceholder &&
        other.exerciseType == exerciseType &&
        other.title == title &&
        other.content == content;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        backgroundColor.hashCode ^
        randomPlaceholder.hashCode ^
        exerciseType.hashCode ^
        title.hashCode ^
        content.hashCode;
  }

  @override
  String toString() {
    return 'PageModel(id: $id, backgroundColor: $backgroundColor, randomPlaceholder: $randomPlaceholder)';
  }
}
