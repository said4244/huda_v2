import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../data/providers/units_provider.dart';
import '../../data/providers/lessons_provider.dart';
import '../../data/models/unit_model.dart';
import '../../data/models/level_model.dart';
import '../widgets/unit_section.dart';
import '../../widgets/adaptive_app_bar.dart';
import '../../widgets/adaptive_bottom_nav.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/user_stats_provider.dart';
import '../../utils/responsive_helper.dart';
import '../../controllers/page_transition_controller.dart';
import '../../main.dart'; // For adminLogin

/// Main Units Page implementing Duolingo-style learning path
/// Features:
/// - Pixel-perfect wave pattern for level positioning
/// - Responsive design for mobile/tablet/desktop
/// - Stack-based absolute positioning for exact control
/// - Smooth scrolling with no overscroll glow
/// - Future-ready for CRUD operations with Hive
/// - Navigation integration with sections page
class UnitsPage extends StatefulWidget {
  final String? sectionId;
  final String? unitId; // Optional: scroll to specific unit

  const UnitsPage({
    super.key,
    this.sectionId,
    this.unitId,
  });

  @override
  State<UnitsPage> createState() => _UnitsPageState();
}

class _UnitsPageState extends State<UnitsPage> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeUnits();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeUnits() async {
    final unitsProvider = Provider.of<UnitsProvider>(context, listen: false);
    
    try {
      await unitsProvider.loadUnits();
      
      // Scroll to specific unit if provided
      if (widget.unitId != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToUnit(widget.unitId!);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load units: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToUnit(String unitId) {
    // Calculate position based on units before the target
    // This is a simplified version - you might want more precise calculation
    final unitsProvider = Provider.of<UnitsProvider>(context, listen: false);
    final units = unitsProvider.units;
    
    final targetIndex = units.indexWhere((unit) => unit.id == unitId);
    if (targetIndex != -1) {
      final scrollPosition = targetIndex * 400.0; // Approximate unit height
      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Scaffold(
      // App bar should always show on units page for navigation back
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Consumer2<NavigationProvider, UserStatsProvider>(
          builder: (context, navProvider, statsProvider, child) {
            return AdaptiveAppBar(
              title: 'Units',
              showBackButton: true,
              onMenuPressed: () {
                final transitionController = Get.find<PageTransitionController>();
                transitionController.navigateBackToSections();
              },
            );
          },
        ),
      ),
      
      body: _buildBody(),
      
      // Bottom navigation for mobile only
      bottomNavigationBar: !isDesktop
          ? Consumer<NavigationProvider>(
              builder: (context, navProvider, child) {
                return AdaptiveBottomNav(
                  currentIndex: navProvider.currentIndex,
                  onTap: (index) => _handleNavTap(context, index),
                );
              },
            )
          : null,
    );
  }

  Widget _buildBody() {
    return Consumer<UnitsProvider>(
      builder: (context, unitsProvider, child) {
        if (_isLoading || unitsProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (unitsProvider.error != null) {
          return _buildErrorState(unitsProvider.error!);
        }

        final units = widget.sectionId != null
            ? unitsProvider.getUnitsForSection(widget.sectionId!)
            : unitsProvider.units;

        if (units.isEmpty) {
          return _buildEmptyState();
        }

        return _buildUnitsContent(units);
      },
    );
  }

  Widget _buildUnitsContent(List<UnitModel> units) {
    return ScrollConfiguration(
      behavior: _NoGlowScrollBehavior(),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 32,
        ),
        child: Column(
          children: [
            // Units list
            ...units.map((unit) => ResponsiveUnitSection(
              unit: unit,
              onLevelTap: (level) => _handleLevelTap(unit, level),
              onJumpTap: () => _handleJumpTap(unit),
            )),
            
            // Bottom spacing for scroll
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeUnits,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No units available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Units will appear here when available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle level tap - start level or navigate to lesson
  void _handleLevelTap(UnitModel unit, LevelModel level) async {
    final unitsProvider = Provider.of<UnitsProvider>(context, listen: false);
    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    
    // Check if level is accessible
    if (level.status == LevelStatus.locked && level.type != LevelType.fastForward) {
      _showLockedLevelMessage();
      return;
    }
    
    if (level.type == LevelType.fastForward) {
      _handleJumpTap(unit);
      return;
    }
    
    try {
      // Start the level
      await unitsProvider.startLevel(unit.id, level.id);
      
      // Get or create lesson for this unit/level (ensures lesson exists)
      lessonsProvider.getLesson(unit.id, level.id, adminMode: adminLogin);
      
      // Navigate to lesson page
      if (mounted) {
        Navigator.of(context).pushNamed(
          '/lesson',
          arguments: {
            'unitId': unit.id,
            'levelId': level.id,
            'sectionId': widget.sectionId,
          },
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start level: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle jump button tap - fast forward through unit
  void _handleJumpTap(UnitModel unit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump ahead?'),
        content: Text(
          'Skip to the end of "${unit.title}" and unlock all levels?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performJump(unit);
            },
            child: const Text('Jump'),
          ),
        ],
      ),
    );
  }

  /// Perform the actual unit jump
  Future<void> _performJump(UnitModel unit) async {
    final unitsProvider = Provider.of<UnitsProvider>(context, listen: false);
    
    try {
      await unitsProvider.unlockAllLevelsInUnit(unit.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jumped ahead in ${unit.title}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to jump: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLockedLevelMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complete previous levels to unlock this one'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Handle navigation tap
  void _handleNavTap(BuildContext context, int index) {
    final transitionController = Get.find<PageTransitionController>();
    
    switch (index) {
      case 0: // Home button - navigate back to sections
        transitionController.navigateBackToSections();
        break;
      case 1:
        // Stats page - show coming soon message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stats page coming soon!'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
      case 2:
        // Profile page - show coming soon message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile page coming soon!'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
    }
  }
}

/// Custom scroll behavior to remove overscroll glow
class _NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
