import 'package:flutter/foundation.dart';
import '../models/section_model.dart';
import '../mock/mock_sections.dart';
// Future: import '../services/hive_service.dart';

class SectionsProvider extends ChangeNotifier {
  List<SectionModel> _sections = [];
  bool _showAllUnlocked = false;
  
  // Future: HiveService? _hiveService;
  
  SectionsProvider() {
    _loadSections();
  }
  
  List<SectionModel> get sections => _sections;
  bool get showAllUnlocked => _showAllUnlocked;
  
  Future<void> _loadSections() async {
    // Current: Load from mock
    _sections = MockSections.getSections(allUnlocked: _showAllUnlocked);
    
    // Future: Load from Hive
    // if (_hiveService != null) {
    //   _sections = await _hiveService!.getSections();
    // } else {
    //   _sections = MockSections.getSections();
    // }
    
    notifyListeners();
  }
  
  void toggleShowAllUnlocked() {
    _showAllUnlocked = !_showAllUnlocked;
    _loadSections();
  }
  
  Future<void> updateSection(String id, SectionModel updatedSection) async {
    final index = _sections.indexWhere((s) => s.id == id);
    if (index != -1) {
      _sections[index] = updatedSection;
      
      // Future: Save to Hive
      // await _hiveService?.updateSection(updatedSection);
      
      notifyListeners();
    }
  }
  
  Future<void> deleteSection(String id) async {
    _sections.removeWhere((s) => s.id == id);
    
    // Future: Delete from Hive
    // await _hiveService?.deleteSection(id);
    
    notifyListeners();
  }
  
  Future<void> addSection(SectionModel section) async {
    _sections.add(section);
    _sections.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    
    // Future: Save to Hive
    // await _hiveService?.addSection(section);
    
    notifyListeners();
  }
  
  void unlockSection(String id) {
    final section = _sections.firstWhere((s) => s.id == id);
    updateSection(id, section.copyWith(isUnlocked: true, isNewlyUnlocked: true));
  }
  
  void lockSection(String id) {
    final section = _sections.firstWhere((s) => s.id == id);
    updateSection(id, section.copyWith(isUnlocked: false));
  }
}
