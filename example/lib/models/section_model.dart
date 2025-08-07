import 'package:flutter/material.dart';

enum SectionStatus { locked, newlyUnlocked, inProgress, completed }

class SectionModel {
  final String id;
  final int orderIndex;
  final String name;
  final String description;
  final Color backgroundColor;
  final Color borderColor;
  final String? iconPath;
  final bool isUnlocked;
  final bool isNewlyUnlocked; // New field to track newly unlocked status
  final List<UnitModel> units;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  SectionModel({
    required this.id,
    required this.orderIndex,
    required this.name,
    this.description = '',
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE0E0E0),
    this.iconPath,
    this.isUnlocked = false,
    this.isNewlyUnlocked = false,
    required this.units,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Get the current status based on unit completion
  SectionStatus get status {
    if (!isUnlocked) return SectionStatus.locked;
    if (isNewlyUnlocked) return SectionStatus.newlyUnlocked;
    
    final completedUnits = units.where((u) => u.status == UnitStatus.completed).length;
    final totalUnits = units.length;
    
    if (completedUnits == totalUnits) return SectionStatus.completed;
    if (completedUnits > 0 || units.any((u) => u.status == UnitStatus.current)) {
      return SectionStatus.inProgress;
    }
    return SectionStatus.newlyUnlocked; // Default to newly unlocked when first unlocked
  }

  /// Get status display text
  String get statusText {
    switch (status) {
      case SectionStatus.locked:
        return 'LOCKED';
      case SectionStatus.newlyUnlocked:
        return 'NEWLY UNLOCKED!';
      case SectionStatus.inProgress:
        return 'IN PROGRESS!';
      case SectionStatus.completed:
        return 'COMPLETED!';
    }
  }

  /// Get card background color based on status
  Color get cardBackgroundColor {
    switch (status) {
      case SectionStatus.locked:
        return const Color(0xFFB0B0B0); // Gray for locked
      case SectionStatus.newlyUnlocked:
        return const Color(0xFF8B5CF6); // Purple for newly unlocked
      case SectionStatus.inProgress:
        return const Color(0xFF58CC82); // Green for in progress  
      case SectionStatus.completed:
        return const Color(0xFF1B7F79); // Teal for completed
    }
  }

  // For Hive compatibility later
  Map<String, dynamic> toJson() => {
    'id': id,
    'orderIndex': orderIndex,
    'name': name,
    'description': description,
    'backgroundColor': backgroundColor.value,
    'borderColor': borderColor.value,
    'iconPath': iconPath,
    'isUnlocked': isUnlocked,
    'isNewlyUnlocked': isNewlyUnlocked,
    'units': units.map((u) => u.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
  
  factory SectionModel.fromJson(Map<String, dynamic> json) => SectionModel(
    id: json['id'],
    orderIndex: json['orderIndex'],
    name: json['name'],
    description: json['description'] ?? '',
    backgroundColor: Color(json['backgroundColor']),
    borderColor: Color(json['borderColor']),
    iconPath: json['iconPath'],
    isUnlocked: json['isUnlocked'],
    isNewlyUnlocked: json['isNewlyUnlocked'] ?? false,
    units: (json['units'] as List).map((u) => UnitModel.fromJson(u)).toList(),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
  );

  SectionModel copyWith({
    String? name,
    String? description,
    Color? backgroundColor,
    Color? borderColor,
    String? iconPath,
    bool? isUnlocked,
    bool? isNewlyUnlocked,
    List<UnitModel>? units,
  }) => SectionModel(
    id: id,
    orderIndex: orderIndex,
    name: name ?? this.name,
    description: description ?? this.description,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    iconPath: iconPath ?? this.iconPath,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    isNewlyUnlocked: isNewlyUnlocked ?? this.isNewlyUnlocked,
    units: units ?? this.units,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}

enum UnitStatus { locked, unlocked, current, completed }

class UnitModel {
  final String id;
  final int number;
  final String title;
  final UnitStatus status;
  final double progress;
  
  UnitModel({
    required this.id,
    required this.number,
    required this.title,
    required this.status,
    this.progress = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'title': title,
    'status': status.toString(),
    'progress': progress,
  };
  
  factory UnitModel.fromJson(Map<String, dynamic> json) => UnitModel(
    id: json['id'],
    number: json['number'],
    title: json['title'],
    status: UnitStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
      orElse: () => UnitStatus.locked,
    ),
    progress: json['progress'] ?? 0.0,
  );
}
