import 'package:flutter/foundation.dart';

/// Provider for managing navigation state across the app
/// Features:
/// - Track current navigation index
/// - Handle sidebar/drawer state
/// - Manage page transitions
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _sidebarOpen = false;
  
  int get currentIndex => _currentIndex;
  bool get sidebarOpen => _sidebarOpen;
  
  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
  
  void toggleSidebar() {
    _sidebarOpen = !_sidebarOpen;
    notifyListeners();
  }

  void closeSidebar() {
    if (_sidebarOpen) {
      _sidebarOpen = false;
      notifyListeners();
    }
  }

  void openSidebar() {
    if (!_sidebarOpen) {
      _sidebarOpen = true;
      notifyListeners();
    }
  }

  // Navigation page titles
  String get currentPageTitle {
    switch (_currentIndex) {
      case 0:
        return 'Sections';
      case 1:
        return 'Stats';
      case 2:
        return 'Profile';
      default:
        return 'Huda';
    }
  }
}
