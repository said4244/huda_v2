import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for managing page transitions between Sections and Units pages
/// Uses right-to-left slide animation for smooth transitions
class PageTransitionController extends GetxController with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<Offset> slideAnimation;
  
  // Page states
  final RxBool _showUnitsPage = false.obs;
  final RxString _currentSectionId = ''.obs;
  final RxString _currentSectionTitle = ''.obs;
  
  // Getters
  bool get showUnitsPage => _showUnitsPage.value;
  String get currentSectionId => _currentSectionId.value;
  String get currentSectionTitle => _currentSectionTitle.value;
  
  @override
  void onInit() {
    super.onInit();
    
    // Initialize animation controller
    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Create slide animation (right to left)
    slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right
      end: Offset.zero, // End at center
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  /// Navigate to units page for a specific section
  void navigateToUnits({
    required String sectionId,
    required String sectionTitle,
  }) {
    print("navigateToUnits called with sectionId: $sectionId, title: $sectionTitle");
    
    _currentSectionId.value = sectionId;
    _currentSectionTitle.value = sectionTitle;
    _showUnitsPage.value = true;
    
    print("showUnitsPage is now: ${_showUnitsPage.value}");
    
    // Trigger GetBuilder update
    update();
    
    // Start slide animation
    animationController.forward();
    
    print("Animation started");
  }
  
  /// Navigate back to sections page
  void navigateBackToSections() {
    // Start reverse animation
    animationController.reverse().then((_) {
      // Hide units page after animation completes
      _showUnitsPage.value = false;
      _currentSectionId.value = '';
      _currentSectionTitle.value = '';
      
      // Trigger GetBuilder update
      update();
    });
  }
  
  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
