import 'package:flutter/material.dart';
import '../models/section_model.dart';

class MockSections {
  static List<SectionModel> getSections({bool allUnlocked = false}) {
    return [
      SectionModel(
        id: 'section-rookie',
        orderIndex: 1,
        name: 'Rookie',
        description: 'Start your Arabic journey',
        backgroundColor: Colors.white,
        borderColor: const Color(0xFF1B7F79),
        iconPath: 'assets/images/camelwaving.png', // Friendly waving camel for beginners
        isUnlocked: true,
        units: List.generate(8, (index) => UnitModel(
          id: 'rookie-unit-${index + 1}',
          number: index + 1,
          title: 'Unit ${index + 1}',
          status: allUnlocked 
            ? (index < 3 ? UnitStatus.completed : UnitStatus.unlocked)
            : index == 0 ? UnitStatus.current 
            : index < 3 ? UnitStatus.completed 
            : UnitStatus.locked,
        )),
      ),
      SectionModel(
        id: 'section-explorer',
        orderIndex: 2,
        name: 'Explorer',
        description: 'Expand your knowledge',
        backgroundColor: Colors.white,
        borderColor: const Color(0xFF808080),
        iconPath: 'assets/images/camelwalking.png', // Walking camel for exploration
        isUnlocked: allUnlocked,
        isNewlyUnlocked: allUnlocked, // Set as newly unlocked when debug mode is on
        units: List.generate(10, (index) => UnitModel(
          id: 'explorer-unit-${index + 1}',
          number: index + 1,
          title: 'Unit ${index + 1}',
          status: allUnlocked ? UnitStatus.unlocked : UnitStatus.locked,
        )),
      ),
      SectionModel(
        id: 'section-champion',
        orderIndex: 3,
        name: 'Champion',
        description: 'Master the language',
        backgroundColor: Colors.white,
        borderColor: const Color(0xFF808080),
        iconPath: 'assets/images/camelrunning.png', // Running camel for championship
        isUnlocked: allUnlocked,
        units: List.generate(12, (index) => UnitModel(
          id: 'champion-unit-${index + 1}',
          number: index + 1,
          title: 'Unit ${index + 1}',
          status: allUnlocked ? UnitStatus.unlocked : UnitStatus.locked,
        )),
      ),
    ];
  }
}
