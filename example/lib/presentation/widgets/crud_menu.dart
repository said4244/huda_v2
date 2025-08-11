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
          
          // Edit page button
          _buildActionButton(
            context: context,
            icon: Icons.edit_outlined,
            label: 'Edit Page',
            subtitle: 'Configure exercise type and properties',
            color: Colors.blue,
            onPressed: () => _editPage(context),
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
    
    // Create new page with fixed background color
    final newPage = PageModel.blank(randomPlaceholder: false);
    
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
    
    _showExerciseEditor(context);
  }

  void _showExerciseEditor(BuildContext context) {
    final currentPage = lesson.pages[currentPageIndex];
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseEditorPage(
          unitId: unitId,
          levelId: levelId,
          pageIndex: currentPageIndex,
          page: currentPage,
          onPageUpdated: onPageUpdated,
        ),
      ),
    );
  }
}

/// Page for editing exercise properties
class ExerciseEditorPage extends StatefulWidget {
  final String unitId;
  final String levelId;
  final int pageIndex;
  final PageModel page;
  final VoidCallback onPageUpdated;

  const ExerciseEditorPage({
    super.key,
    required this.unitId,
    required this.levelId,
    required this.pageIndex,
    required this.page,
    required this.onPageUpdated,
  });

  @override
  State<ExerciseEditorPage> createState() => _ExerciseEditorPageState();
}

class _ExerciseEditorPageState extends State<ExerciseEditorPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  late TextEditingController _header1Controller;
  late TextEditingController _header2Controller;
  late TextEditingController _transliterationController;
  late TextEditingController _videoNameController;
  late TextEditingController _microphonePromptController;
  
  // Form state
  String _exerciseType = 'exerciseIntro'; // Default to exerciseIntro instead of legacy
  String _videoTrigger = 'onStart';
  bool _allowUserVideoControl = false;
  bool _autoPlay = false;
  bool _showMicrophone = false;
  bool _showContinueButton = true;
  bool _showRightArrow = false;
  
  List<Map<String, dynamic>> _sendMessages = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _header1Controller = TextEditingController();
    _header2Controller = TextEditingController();
    _transliterationController = TextEditingController();
    _videoNameController = TextEditingController();
    _microphonePromptController = TextEditingController();
    
    // Load existing data
    _loadExistingData();
  }

  void _loadExistingData() {
    final exerciseData = widget.page.exerciseData ?? {};
    
    // Default to 'exerciseIntro' instead of 'legacy' for better UX
    _exerciseType = widget.page.exerciseType ?? 'exerciseIntro';
    _header1Controller.text = exerciseData['header1'] as String? ?? '';
    _header2Controller.text = exerciseData['header2'] as String? ?? '';
    _transliterationController.text = exerciseData['transliteration'] as String? ?? '';
    _videoNameController.text = exerciseData['videoName'] as String? ?? '';
    _microphonePromptController.text = exerciseData['microphonePrompt'] as String? ?? '';
    
    _videoTrigger = exerciseData['videoTrigger'] as String? ?? 'onStart';
    _allowUserVideoControl = exerciseData['allowUserVideoControl'] as bool? ?? false;
    _autoPlay = exerciseData['autoPlay'] as bool? ?? false;
    _showMicrophone = exerciseData['showMicrophone'] as bool? ?? false;
    _showContinueButton = exerciseData['showContinueButton'] as bool? ?? true;
    _showRightArrow = exerciseData['showRightArrow'] as bool? ?? false;
    
    _sendMessages = List<Map<String, dynamic>>.from(
      exerciseData['sendMessages'] as List<dynamic>? ?? []
    );
  }

  @override
  void dispose() {
    _header1Controller.dispose();
    _header2Controller.dispose();
    _transliterationController.dispose();
    _videoNameController.dispose();
    _microphonePromptController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate that at least one essential field is filled for exerciseIntro
    if (_exerciseType == 'exerciseIntro') {
      final hasHeader1 = _header1Controller.text.trim().isNotEmpty;
      final hasVideoName = _videoNameController.text.trim().isNotEmpty;
      final hasMicPrompt = _microphonePromptController.text.trim().isNotEmpty;
      
      if (!hasHeader1 && !hasVideoName && !hasMicPrompt) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill at least one of: Header 1, Video Name, or Microphone Prompt'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    
    Map<String, dynamic>? exerciseData;
    
    if (_exerciseType == 'exerciseIntro') {
      exerciseData = {
        'header1': _header1Controller.text.isEmpty ? null : _header1Controller.text,
        'header2': _header2Controller.text.isEmpty ? null : _header2Controller.text,
        'transliteration': _transliterationController.text.isEmpty ? null : _transliterationController.text,
        'videoName': _videoNameController.text.isEmpty ? null : _videoNameController.text,
        'videoTrigger': _videoTrigger,
        'allowUserVideoControl': _allowUserVideoControl,
        'autoPlay': _autoPlay,
        'showMicrophone': _showMicrophone,
        'microphonePrompt': _microphonePromptController.text.isEmpty ? null : _microphonePromptController.text,
        'showContinueButton': _showContinueButton,
        'showRightArrow': _showRightArrow,
        'sendMessages': _sendMessages,
      };
    }

    final updatedPage = widget.page.copyWith(
      exerciseType: _exerciseType == 'legacy' ? null : _exerciseType,
      exerciseData: exerciseData,
    );

    try {
      await lessonsProvider.updatePage(widget.unitId, widget.levelId, widget.pageIndex, updatedPage);
      
      widget.onPageUpdated();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Page updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating page: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EFEB),
      appBar: AppBar(
        title: const Text('Edit Exercise'),
        backgroundColor: const Color(0xFFF2EFEB),
        foregroundColor: const Color(0xFF4D382D),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF4D382D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildExerciseTypeSection(),
            const SizedBox(height: 24),
            if (_exerciseType == 'exerciseIntro') ...[
              _buildHeadersSection(),
              const SizedBox(height: 24),
              _buildVideoSection(),
              const SizedBox(height: 24),
              _buildMicrophoneSection(),
              const SizedBox(height: 24),
              _buildUIOptionsSection(),
              const SizedBox(height: 24),
              _buildSendMessagesSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exercise Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4D382D),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _exerciseType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'legacy', child: Text('Legacy Page')),
                DropdownMenuItem(value: 'exerciseIntro', child: Text('Exercise Intro')),
              ],
              onChanged: (value) {
                setState(() {
                  _exerciseType = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Headers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4D382D),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _header1Controller,
              decoration: const InputDecoration(
                labelText: 'Header 1',
                border: OutlineInputBorder(),
                hintText: 'Main header text',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _transliterationController,
              decoration: const InputDecoration(
                labelText: 'Transliteration',
                border: OutlineInputBorder(),
                hintText: 'Phonetic pronunciation',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _header2Controller,
              decoration: const InputDecoration(
                labelText: 'Header 2',
                border: OutlineInputBorder(),
                hintText: 'Secondary header (appears below video)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Video Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4D382D),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _videoNameController,
              decoration: const InputDecoration(
                labelText: 'Video File Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., intro_video.mp4',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _videoTrigger,
              decoration: const InputDecoration(
                labelText: 'Video Trigger',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'onStart', child: Text('On Start')),
                DropdownMenuItem(value: 'afterAvatarX', child: Text('After Avatar Message')),
                DropdownMenuItem(value: 'afterVideoX', child: Text('After Video')),
              ],
              onChanged: (value) {
                setState(() {
                  _videoTrigger = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Allow User Video Control'),
              subtitle: const Text('Show play/pause controls'),
              value: _allowUserVideoControl,
              onChanged: (value) {
                setState(() {
                  _allowUserVideoControl = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Auto Play'),
              subtitle: const Text('Start video automatically'),
              value: _autoPlay,
              onChanged: (value) {
                setState(() {
                  _autoPlay = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicrophoneSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Microphone Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4D382D),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Show Microphone'),
              subtitle: const Text('Enable hold-to-talk microphone'),
              value: _showMicrophone,
              onChanged: (value) {
                setState(() {
                  _showMicrophone = value;
                });
              },
            ),
            if (_showMicrophone) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _microphonePromptController,
                decoration: const InputDecoration(
                  labelText: 'Microphone Prompt',
                  border: OutlineInputBorder(),
                  hintText: 'Text for pronunciation practice',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUIOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UI Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4D382D),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Show Continue Button'),
              subtitle: const Text('Button to proceed to next exercise'),
              value: _showContinueButton,
              onChanged: (value) {
                setState(() {
                  _showContinueButton = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show Right Arrow'),
              subtitle: const Text('Arrow in app bar for testing'),
              value: _showRightArrow,
              onChanged: (value) {
                setState(() {
                  _showRightArrow = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendMessagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Message Sequence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4D382D),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addMessage,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_sendMessages.isEmpty)
              const Text(
                'No messages configured',
                style: TextStyle(color: Colors.grey),
              )
            else
              ..._sendMessages.asMap().entries.map((entry) {
                final index = entry.key;
                final message = entry.value;
                return _buildMessageItem(index, message);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(int index, Map<String, dynamic> message) {
    final messageType = message['type'] as String;
    final isAvatarMessage = messageType == 'avatarMessage';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Message ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _removeMessage(index),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  isAvatarMessage ? Icons.chat : Icons.video_library,
                  size: 16,
                  color: isAvatarMessage ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Text('Type: ${message['type']}'),
              ],
            ),
            Text('Content: ${message['content']}'),
            if (isAvatarMessage)
              const Text(
                'Timing: Waits for avatar speech to complete',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (message['delaySeconds'] != null)
              Text('Delay: ${message['delaySeconds']}s'),
          ],
        ),
      ),
    );
  }

  void _addMessage() {
    // Enhanced implementation with better defaults for speech-end detection
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose message type:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Avatar Message'),
              subtitle: const Text('Uses speech-end detection for timing'),
              onTap: () {
                setState(() {
                  _sendMessages.add({
                    'type': 'avatarMessage',
                    'content': 'Hello! Welcome to this lesson.',
                    'delaySeconds': 0.0, // No longer needed with speech-end detection
                  });
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Video'),
              subtitle: const Text('Plays after previous message completes'),
              onTap: () {
                setState(() {
                  _sendMessages.add({
                    'type': 'video',
                    'content': '', // Video trigger, no content needed
                    'delaySeconds': 0.0,
                  });
                });
                Navigator.of(context).pop();
              },
            ),
          ],
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

  void _removeMessage(int index) {
    setState(() {
      _sendMessages.removeAt(index);
    });
  }
}
