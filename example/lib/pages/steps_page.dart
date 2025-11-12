import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../providers/sections_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/section_card.dart';
import '../widgets/adaptive_app_bar.dart';
import '../widgets/adaptive_bottom_nav.dart';
import '../models/section_model.dart';
import '../utils/responsive_helper.dart';
import '../theme/app_colors.dart';
import '../controllers/page_transition_controller.dart';

/// Modern sections page with Duolingo-style card layout
/// Features:
/// - Vertical scrolling list of full-width section cards
/// - Responsive design for mobile and desktop
/// - Modern app bar and bottom navigation
/// - Smooth navigation and animations
class SectionsPage extends StatelessWidget {
  const SectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SectionsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AdaptiveAppBar(
            title: 'Sections',
            onMenuPressed: () => _showDebugMenu(context, provider),
          ),
          body: _buildBody(context, provider),
          bottomNavigationBar: AdaptiveBottomNav(
            currentIndex: 0, // Sections page is index 0
            onTap: (index) => _handleNavTap(context, index),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SectionsProvider provider) {
    return SafeArea(
      child: ListView.builder(
        padding: ResponsiveHelper.getHorizontalPadding(context).copyWith(
          top: 20,
          bottom: 10, // Increased from 80 to 120 to clear bottom nav
        ),
        itemCount: provider.sections.length,
        itemBuilder: (context, index) {
          final section = provider.sections[index];
          return _buildSectionCard(context, section, provider);
        },
      ),
    );
  }

  /// Build individual section card with navigation
  Widget _buildSectionCard(
    BuildContext context, 
    SectionModel section, 
    SectionsProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SectionCard(
        section: section,
        onTap: () => _handleSectionTap(context, section, provider),
        onUnitTap: (unit) => _handleUnitTap(context, section, unit, provider),
      ),
    );
  }

  /// Handle section card tap - navigate to units page for the section
  void _handleSectionTap(
    BuildContext context, 
    SectionModel section, 
    SectionsProvider provider,
  ) {
    if (!section.isUnlocked) return;

    print("Section tapped: ${section.id} - ${section.name}");
    
    // Use GetX transition instead of Navigator
    final transitionController = Get.find<PageTransitionController>();
    print("Found transition controller: $transitionController");
    
    transitionController.navigateToUnits(
      sectionId: section.id,
      sectionTitle: section.name,
    );
    
    print("Called navigateToUnits");
  }

  /// Handle unit tap within a section
  void _handleUnitTap(
    BuildContext context, 
    SectionModel section, 
    UnitModel unit, 
    SectionsProvider provider,
  ) {
    if (!section.isUnlocked) return;

    // Navigate to specific unit content
    Navigator.of(context).pushNamed('/video_call', arguments: {
      'section': section,
      'unit': unit,
      'mode': 'unit_lesson',
    });
  }

  /// Handle bottom navigation tap
  void _handleNavTap(BuildContext context, int index) {
    final transitionController = Get.find<PageTransitionController>();
    
    switch (index) {
      case 0: // Home button
        // Check if we're currently viewing the units page
        if (transitionController.showUnitsPage) {
          // Navigate back to sections with right-to-left transition
          transitionController.navigateBackToSections();
        }
        // If already on sections page, do nothing (already home)
        break;
      case 1:
        // Stats page - show coming soon message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stats page coming soon!'),
            backgroundColor: AppColors.info,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 2:
        // Profile page - show coming soon message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile page coming soon!'),
            backgroundColor: AppColors.info,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  /// Show debug menu with toggle options
  void _showDebugMenu(BuildContext context, SectionsProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Debug Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                provider.showAllUnlocked ? Icons.lock_open : Icons.lock,
                color: AppColors.primary,
              ),
              title: Text(
                provider.showAllUnlocked 
                  ? 'Lock sections' 
                  : 'Unlock all sections',
              ),
              subtitle: const Text('Toggle debug mode'),
              onTap: () {
                provider.toggleShowAllUnlocked();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: AppColors.accent),
              title: const Text('Refresh sections'),
              subtitle: const Text('Reload section data'),
              onTap: () {
                // Force reload sections
                provider.toggleShowAllUnlocked();
                provider.toggleShowAllUnlocked();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
