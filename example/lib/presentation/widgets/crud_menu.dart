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
  late TextEditingController _letterController;
  
  // Form state
  String _exerciseType = 'exerciseIntro'; // Default to exerciseIntro instead of legacy
  String _videoTrigger = 'onStart';
  String? _videoAfterMessageId; // Track which message ID the video should follow
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
    _letterController = TextEditingController();
    
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
    _letterController.text = exerciseData['letter'] as String? ?? '';
    
    _videoTrigger = exerciseData['videoTrigger'] as String? ?? 'onStart';
    _videoAfterMessageId = exerciseData['videoAfterMessageId'] as String?;
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
    _letterController.dispose();
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

    // Validate that essential fields are filled for exerciseTrace
    if (_exerciseType == 'exerciseTrace') {
      final hasLetter = _letterController.text.trim().isNotEmpty;
      
      if (!hasLetter) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide a letter for the tracing exercise'),
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
        'videoAfterMessageId': _videoAfterMessageId,
        'allowUserVideoControl': _allowUserVideoControl,
        'autoPlay': _autoPlay,
        'showMicrophone': _showMicrophone,
        'microphonePrompt': _microphonePromptController.text.isEmpty ? null : _microphonePromptController.text,
        'showContinueButton': _showContinueButton,
        'showRightArrow': _showRightArrow,
        'sendMessages': _sendMessages,
      };
    } else if (_exerciseType == 'exerciseTrace') {
      exerciseData = {
        'header1': _header1Controller.text.isEmpty ? null : _header1Controller.text,
        'header2': _header2Controller.text.isEmpty ? null : _header2Controller.text,
        'transliteration': _transliterationController.text.isEmpty ? null : _transliterationController.text,
        'letter': _letterController.text,
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
            if (_exerciseType == 'exerciseTrace') ...[
              _buildHeadersSection(),
              const SizedBox(height: 24),
              _buildTraceAssetsSection(),
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
                DropdownMenuItem(value: 'exerciseTrace', child: Text('Tracing Exercise')),
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

  Widget _buildTraceAssetsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tracing Letter',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _letterController,
              decoration: const InputDecoration(
                labelText: 'Arabic Letter',
                hintText: 'e.g., ب',
                border: OutlineInputBorder(),
                helperText: 'The Arabic letter to trace (single character)',
              ),
              validator: (value) {
                if (_exerciseType == 'exerciseTrace' && (value == null || value.trim().isEmpty)) {
                  return 'Letter is required for tracing exercises';
                }
                return null;
              },
              maxLength: 3, // Allow for combined letters like لا
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontFamily: 'Tufuli Arabic',
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
                DropdownMenuItem(value: 'onStart', child: Text('On Start - Plays immediately when page loads')),
                DropdownMenuItem(value: 'afterAvatarX', child: Text('After Avatar Message - Plays after specific message finishes')),
                DropdownMenuItem(value: 'afterVideoX', child: Text('After Video - Plays after another video finishes')),
                DropdownMenuItem(value: 'normal', child: Text('Manual - User triggered only')),
              ],
              onChanged: (value) {
                setState(() {
                  _videoTrigger = value!;
                });
              },
            ),
            const SizedBox(height: 12),

            // Show message selection when "After Avatar Message" is selected
            if (_videoTrigger == 'afterAvatarX') ...[
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Play after which avatar message:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        // This will refresh the available messages
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message list refreshed'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildVideoMessageSelectionDropdown(),
              const SizedBox(height: 12),
            ],

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

  Widget _buildVideoMessageSelectionDropdown() {
    final availableMessages = _sendMessages
        .where((msg) => msg['type'] == 'avatarMessage' && msg['id'] != null)
        .toList();

    if (availableMessages.isEmpty) {
      // Reset the selection if no messages are available
      if (_videoAfterMessageId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _videoAfterMessageId = null;
          });
        });
      }
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No avatar messages found',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
            ),
            SizedBox(height: 4),
            Text(
              'Create avatar messages in the "Send Messages" section below first.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
      );
    }

    // Validate that the current selection still exists in available messages
    final availableMessageIds = availableMessages.map((msg) => msg['id'] as String).toSet();
    final validatedSelection = availableMessageIds.contains(_videoAfterMessageId) 
        ? _videoAfterMessageId 
        : null;
    
    // Update the selection if it's invalid
    if (validatedSelection != _videoAfterMessageId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _videoAfterMessageId = validatedSelection;
        });
      });
    }

    return DropdownButtonFormField<String>(
      value: validatedSelection,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Select Message',
        hintText: 'Choose which message must finish first',
      ),
      items: availableMessages
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key;
            final msg = entry.value;
            final content = msg['content'] as String? ?? '';
            return DropdownMenuItem(
              value: msg['id'] as String,
              child: Text(
                'Message ${index + 1}: ${content.length > 30 ? content.substring(0, 30) + '...' : content}',
                style: const TextStyle(fontSize: 14),
              ),
            );
          })
          .toList(),
      onChanged: (value) {
        setState(() {
          _videoAfterMessageId = value;
        });
      },
      validator: (value) {
        if (_videoTrigger == 'afterAvatarX' && value == null) {
          return 'Please select which message the video should follow';
        }
        return null;
      },
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
    final trigger = message['trigger'] as String? ?? 'onStart';
    final afterId = message['afterId'] as String?;
    final content = message['content'] as String? ?? '';
    final messageId = message['id'] as String? ?? 'no-id';
    
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
                Expanded(
                  child: Text(
                    'Message ${index + 1} (ID: ${messageId.length > 15 ? messageId.substring(0, 15) + '...' : messageId})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _removeMessage(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isAvatarMessage ? Icons.chat : Icons.video_library,
                  size: 16,
                  color: isAvatarMessage ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Text('Type: $messageType'),
              ],
            ),
            const SizedBox(height: 4),
            if (content.isNotEmpty)
              Text(
                'Content: ${content.length > 50 ? content.substring(0, 50) + '...' : content}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getTriggerIcon(trigger),
                  size: 14,
                  color: _getTriggerColor(trigger),
                ),
                const SizedBox(width: 4),
                Text(
                  'Trigger: ${_getTriggerDisplayName(trigger)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getTriggerColor(trigger),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (afterId != null) ...[
              const SizedBox(height: 4),
              Text(
                'Plays after: ${afterId.length > 20 ? afterId.substring(0, 20) + '...' : afterId}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getTriggerIcon(String trigger) {
    switch (trigger) {
      case 'onStart':
        return Icons.play_arrow;
      case 'afterVideo':
        return Icons.video_library;
      case 'afterMessage':
        return Icons.chat;
      case 'normal':
        return Icons.touch_app;
      default:
        return Icons.help;
    }
  }

  Color _getTriggerColor(String trigger) {
    switch (trigger) {
      case 'onStart':
        return Colors.green;
      case 'afterVideo':
        return Colors.blue;
      case 'afterMessage':
        return Colors.orange;
      case 'normal':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getTriggerDisplayName(String trigger) {
    switch (trigger) {
      case 'onStart':
        return 'On Start';
      case 'afterVideo':
        return 'After Video';
      case 'afterMessage':
        return 'After Message';
      case 'normal':
        return 'Manual';
      default:
        return trigger;
    }
  }

  void _addMessage() {
    // Get existing messages for afterId selection
    final existingMessages = _sendMessages.where((msg) => msg['id'] != null).toList();
    
    showDialog(
      context: context,
      builder: (context) => _AddMessageDialog(
        existingMessages: existingMessages,
        page: widget.page,
        onMessageAdded: (newMessage) {
          setState(() {
            _sendMessages.add(newMessage);
          });
        },
      ),
    );
  }

  void _removeMessage(int index) {
    setState(() {
      final removedMessage = _sendMessages[index];
      final removedMessageId = removedMessage['id'] as String?;
      
      _sendMessages.removeAt(index);
      
      // If the removed message was selected for video trigger, clear the selection
      if (_videoAfterMessageId == removedMessageId) {
        _videoAfterMessageId = null;
      }
    });
  }
}

/// Dialog for adding new messages with advanced trigger options
class _AddMessageDialog extends StatefulWidget {
  final List<Map<String, dynamic>> existingMessages;
  final PageModel page;
  final Function(Map<String, dynamic>) onMessageAdded;

  const _AddMessageDialog({
    required this.existingMessages,
    required this.page,
    required this.onMessageAdded,
  });

  @override
  State<_AddMessageDialog> createState() => _AddMessageDialogState();
}

class _AddMessageDialogState extends State<_AddMessageDialog> {
  String _selectedType = 'avatarMessage';
  String _selectedTrigger = 'onStart';
  String? _selectedAfterId;
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  String _generateUniqueId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${_contentController.text.hashCode.abs()}';
  }

  Widget _buildMessageSelectionWidget() {
    final availableMessages = widget.existingMessages
        .where((msg) => msg['type'] == 'avatarMessage')
        .toList();

    if (availableMessages.isEmpty) {
      return const Text(
        'No existing avatar messages to chain to. Create an "On Start" avatar message first.',
        style: TextStyle(color: Colors.orange),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedAfterId,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'After Message',
      ),
      items: availableMessages
          .map((msg) => DropdownMenuItem(
                value: msg['id'] as String,
                child: Text(
                  'Message: ${(msg['content'] as String).length > 30 ? (msg['content'] as String).substring(0, 30) + '...' : msg['content']}',
                ),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedAfterId = value;
        });
      },
      validator: (value) {
        if (_selectedTrigger == 'afterMessage' && value == null) {
          return 'Please select which message to follow';
        }
        return null;
      },
    );
  }

  Widget _buildVideoSelectionWidget() {
    // Get videos from the current page's exercise data
    final currentPage = widget.page;
    final exerciseData = currentPage.exerciseData ?? {};
    
    List<String> availableVideos = [];
    
    // Check for main video in exercise data
    final videoName = exerciseData['videoName'] as String?;
    if (videoName != null && videoName.isNotEmpty) {
      availableVideos.add(videoName);
    }
    
    // TODO: In the future, when multiple videos per page are supported,
    // we could scan for additional video sources here
    
    if (availableVideos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No videos found on this page',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
            ),
            SizedBox(height: 4),
            Text(
              'Add a video to this page first using the Video Settings section in the page editor.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedAfterId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'After Video',
            hintText: 'Select which video must finish first',
          ),
          items: availableVideos
              .map((video) => DropdownMenuItem(
                    value: 'video_$video',
                    child: Text('Video: $video'),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedAfterId = value;
            });
          },
          validator: (value) {
            if (_selectedTrigger == 'afterVideo' && value == null) {
              return 'Please select which video to follow';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'This message will play automatically when the selected video finishes.',
                  style: TextStyle(fontSize: 11, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Message'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message Type Selection
            const Text('Message Type:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Type',
              ),
              items: const [
                DropdownMenuItem(value: 'avatarMessage', child: Text('Avatar Message')),
                // Removed 'video' option - use Video Settings section instead
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Content Field (always show for avatar messages)
            const Text('Message Content:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Avatar speech content',
                hintText: 'What should the avatar say?',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter message content';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Trigger Selection
            const Text('When to Play:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedTrigger,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Trigger',
              ),
              items: const [
                DropdownMenuItem(value: 'onStart', child: Text('On Start - Plays immediately when page loads')),
                DropdownMenuItem(value: 'afterMessage', child: Text('After Message - Plays after specific message finishes')),
                DropdownMenuItem(value: 'afterVideo', child: Text('After Video - Plays after specific video finishes')),
                DropdownMenuItem(value: 'normal', child: Text('Normal - Manual trigger only')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTrigger = value!;
                  _selectedAfterId = null; // Reset selection
                });
              },
            ),
            const SizedBox(height: 16),

            // After ID Selection (for chained messages)
            if (_selectedTrigger == 'afterMessage') ...[
              const Text(
                'Play After Which Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildMessageSelectionWidget(),
              const SizedBox(height: 16),
            ],

            // After Video Selection (for video-triggered messages)
            if (_selectedTrigger == 'afterVideo') ...[
              const Text(
                'Play After Which Video:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildVideoSelectionWidget(),
              const SizedBox(height: 16),
            ],

            // Help Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('• On Start: Plays immediately when page loads', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  Text('• After Message: Creates a sequence chain after specific message finishes', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  Text('• After Video: Plays automatically when specific video completes', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  Text('• Normal: Won\'t auto-play, for user-triggered content only', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedType == 'avatarMessage' && _contentController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter message content')),
              );
              return;
            }

            if ((_selectedTrigger == 'afterMessage' || _selectedTrigger == 'afterVideo') && _selectedAfterId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select which message/video to follow')),
              );
              return;
            }

            final newMessage = <String, dynamic>{
              'id': _generateUniqueId(),
              'type': _selectedType,
              'content': _selectedType == 'avatarMessage' ? _contentController.text.trim() : '',
              'trigger': _selectedTrigger,
            };

            if (_selectedAfterId != null) {
              newMessage['afterId'] = _selectedAfterId;
            }

            widget.onMessageAdded(newMessage);
            Navigator.of(context).pop();
          },
          child: const Text('Add Message'),
        ),
      ],
    );
  }
}
