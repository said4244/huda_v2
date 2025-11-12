import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/lessons_provider.dart';
import '../../data/models/lesson_model.dart';
import '../../data/models/page_model.dart';

/// CRUD menu for admin operations on lesson pages
/// Provides options to add, delete, and modify pages within a lesson
class CrudMenu extends StatelessWidget {
  final String unitId;
  final String levelId;
  final int currentPageIndex;
  final LessonModel lesson;
  final Function(int) onPageAdded;
  final Function(int) onPageDeleted;
  final Function() onPageUpdated;

  const CrudMenu({
    super.key,
    required this.unitId,
    required this.levelId,
    required this.currentPageIndex,
    required this.lesson,
    required this.onPageAdded,
    required this.onPageDeleted,
    required this.onPageUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Text(
            'Lesson CRUD Operations',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          Text(
            'Page ${currentPageIndex + 1} of ${lesson.pageCount}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Add page button
          _buildActionButton(
            context: context,
            icon: Icons.add_circle_outline,
            label: 'Add Page',
            subtitle: 'Insert a new page after current page',
            color: Colors.green,
            onPressed: () => _addPage(context),
          ),
          const SizedBox(height: 12),
          
          // Delete page button
          _buildActionButton(
            context: context,
            icon: Icons.delete_outline,
            label: 'Delete Page',
            subtitle: lesson.isSinglePage 
                ? 'Cannot delete (only one page remaining)'
                : 'Remove the current page',
            color: lesson.isSinglePage ? Colors.grey : Colors.red,
            onPressed: lesson.isSinglePage ? null : () => _deletePage(context),
          ),
          const SizedBox(height: 12),
          
          // Edit page properties
          _buildActionButton(
            context: context,
            icon: Icons.palette_outlined,
            label: 'Edit Page',
            subtitle: 'Change background color and settings',
            color: Colors.blue,
            onPressed: () => _editPage(context),
          ),
          const SizedBox(height: 12),
          
          // Toggle random placeholder
          _buildActionButton(
            context: context,
            icon: lesson.pages[currentPageIndex].randomPlaceholder 
                ? Icons.visibility_off_outlined 
                : Icons.visibility_outlined,
            label: lesson.pages[currentPageIndex].randomPlaceholder 
                ? 'Hide Random Letter' 
                : 'Show Random Letter',
            subtitle: lesson.pages[currentPageIndex].randomPlaceholder 
                ? 'Remove the random letter placeholder'
                : 'Add a random letter placeholder',
            color: Colors.orange,
            onPressed: () => _toggleRandomPlaceholder(context),
          ),
          
          const SizedBox(height: 20),
          
          // Close button
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Close'),
          ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEnabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? color : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isEnabled ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isEnabled ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isEnabled ? Colors.grey[400] : Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addPage(BuildContext context) async {
    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    
    // Create new page with random color and placeholder
    final newPage = PageModel.withRandomColor(randomPlaceholder: true);
    
    // Insert after current page
    final insertIndex = currentPageIndex + 1;
    
    try {
      await lessonsProvider.insertPage(unitId, levelId, insertIndex, newPage);
      
      // Close menu and notify parent
      Navigator.of(context).pop();
      onPageAdded(insertIndex);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Page added at position ${insertIndex + 1}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding page: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _deletePage(BuildContext context) {
    if (lesson.isSinglePage) return;
    
    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Page'),
        content: Text(
          'Are you sure you want to delete page ${currentPageIndex + 1}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Delete the page
              try {
                await lessonsProvider.removePage(unitId, levelId, currentPageIndex);
                
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close menu
                
                onPageDeleted(currentPageIndex);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Page deleted successfully'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (error) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close menu
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting page: $error'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editPage(BuildContext context) {
    Navigator.of(context).pop(); // Close menu first
    
    _showColorPicker(context);
  }

  void _showColorPicker(BuildContext context) {
    final currentPage = lesson.pages[currentPageIndex];
    
    final colors = [
      const Color(0xFF58CC02), // Green
      const Color(0xFF1CB0F6), // Blue  
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF9800), // Orange
      const Color(0xFFF44336), // Red
      const Color(0xFF4CAF50), // Light green
      const Color(0xFF2196F3), // Light blue
      const Color(0xFFE91E63), // Pink
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue grey
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Background Color'),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              final isSelected = color.value == currentPage.backgroundColor.value;
              
              return GestureDetector(
                onTap: () {
                  final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
                  lessonsProvider.updatePageBackgroundColor(unitId, levelId, currentPageIndex, color);
                  
                  Navigator.of(context).pop();
                  onPageUpdated();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Background color updated'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected 
                        ? Border.all(color: Colors.black, width: 3)
                        : Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _toggleRandomPlaceholder(BuildContext context) {
    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    
    lessonsProvider.togglePageRandomPlaceholder(unitId, levelId, currentPageIndex);
    
    Navigator.of(context).pop();
    onPageUpdated();
    
    final currentPage = lesson.pages[currentPageIndex];
    final message = currentPage.randomPlaceholder 
        ? 'Random letter placeholder enabled'
        : 'Random letter placeholder disabled';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
