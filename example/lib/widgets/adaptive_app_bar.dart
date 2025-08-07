import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_stats_provider.dart';
import '../providers/sections_provider.dart';

/// Duolingo-style app bar with flag, streak, diamonds, and options
/// Features:
/// - Arabic flag on the left
/// - Streak fire counter (grayscale when 0)
/// - Diamond counter (grayscale when 0)
/// - Options menu on the right
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final VoidCallback? onMenuPressed;
  final String title;
  final Color backgroundColor;
  final Color foregroundColor;

  const AdaptiveAppBar({
    super.key,
    this.showBackButton = false,
    this.onMenuPressed,
    this.title = 'Huda',
    this.backgroundColor = Colors.white,
    this.foregroundColor = const Color(0xFF374151),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Consumer<UserStatsProvider>(
          builder: (context, userStats, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Left: Arabic flag
                  _buildFlag(),
                  
                  const SizedBox(width: 16),
                  
                  // Center: Streak and Diamonds
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStreakCounter(userStats),
                        const SizedBox(width: 20),
                        _buildDiamondCounter(userStats),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Right: Options menu
                  _buildOptionsButton(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFlag() {
    return Container(
      width: 32,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.asset(
          'assets/images/flags/ar.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.flag, size: 16, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStreakCounter(UserStatsProvider userStats) {
    final hasStreak = userStats.hasStreak;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fire icon
          SizedBox(
            width: 20,
            height: 20,
            child: hasStreak 
              ? Image.asset(
                  'assets/images/fire.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.local_fire_department, 
                      size: 20, color: Colors.orange);
                  },
                )
              : ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0,      0,      0,      1, 0,
                  ]),
                  child: Image.asset(
                    'assets/images/fire.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.local_fire_department, 
                        size: 20, color: Colors.grey);
                    },
                  ),
                ),
          ),
          const SizedBox(width: 4),
          Text(
            '${userStats.streakCount}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hasStreak ? Colors.orange[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiamondCounter(UserStatsProvider userStats) {
    final hasDiamonds = userStats.hasDiamonds;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Diamond icon
          SizedBox(
            width: 20,
            height: 20,
            child: hasDiamonds 
              ? Image.asset(
                  'assets/images/diamond.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.diamond, 
                      size: 20, color: Colors.blue);
                  },
                )
              : ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0,      0,      0,      1, 0,
                  ]),
                  child: Image.asset(
                    'assets/images/diamond.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.diamond, 
                        size: 20, color: Colors.grey);
                    },
                  ),
                ),
          ),
          const SizedBox(width: 4),
          Text(
            '${userStats.diamondCount}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hasDiamonds ? Colors.blue[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.more_horiz, color: Colors.grey),
      onPressed: () => _showOptionsMenu(context),
      tooltip: 'Options',
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final sectionsProvider = Provider.of<SectionsProvider>(context, listen: false);
    final userStatsProvider = Provider.of<UserStatsProvider>(context, listen: false);
    
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
              'Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Unlock all sections toggle
            ListTile(
              leading: Icon(
                sectionsProvider.showAllUnlocked ? Icons.lock_open : Icons.lock,
                color: Colors.blue,
              ),
              title: Text(
                sectionsProvider.showAllUnlocked 
                  ? 'Lock sections' 
                  : 'Unlock all sections',
              ),
              subtitle: const Text('Toggle debug mode'),
              onTap: () {
                sectionsProvider.toggleShowAllUnlocked();
                Navigator.of(context).pop();
              },
            ),
            
            // Test stats values
            ListTile(
              leading: const Icon(Icons.science, color: Colors.green),
              title: const Text('Test stats'),
              subtitle: const Text('Set test values for streak and diamonds'),
              onTap: () {
                userStatsProvider.setTestValues(streak: 5, diamonds: 100);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test values set: 5 streak, 100 diamonds')),
                );
              },
            ),
            
            // Reset stats
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.orange),
              title: const Text('Reset stats'),
              subtitle: const Text('Reset streak and diamonds to 0'),
              onTap: () {
                userStatsProvider.setTestValues(streak: 0, diamonds: 0);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stats reset to 0')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
