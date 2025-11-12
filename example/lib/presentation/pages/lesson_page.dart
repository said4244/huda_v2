import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../data/providers/lessons_provider.dart';
import '../../data/models/lesson_model.dart';
import '../../data/models/page_model.dart';
import '../widgets/crud_menu.dart';

/// Main lesson page displaying a series of pages with navigation controls
/// Features:
/// - PageView with smooth transitions between pages
/// - Navigation controls (Back, Next, X)
/// - Random letter placeholders on pages
/// - Admin CRUD functionality for page management
/// - Custom background colors per page
class LessonPage extends StatefulWidget {
  final String unitId;
  final String levelId;
  final LessonModel? lesson; // Optional: pass lesson directly
  final bool adminMode;

  const LessonPage({
    super.key,
    required this.unitId,
    required this.levelId,
    this.lesson,
    this.adminMode = false,
  });

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPageIndex = 0;
  int _currentPageCount = 0; // Track current page count from stream
  LessonModel? _currentLesson;
  bool _isLoading = true;

  // Animation controllers for page transitions (for future use)
  late AnimationController _slideAnimationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Initialize animation controller for future use
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _loadLesson();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadLesson() async {
    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    
    setState(() => _isLoading = true);
    
    try {
      // Use provided lesson or get from provider (now async)
      _currentLesson = widget.lesson ?? 
          await lessonsProvider.getLesson(widget.unitId, widget.levelId, adminLogin: widget.adminMode);
      
      if (_currentLesson == null) {
        throw Exception('No lesson found for Unit ${widget.unitId}, Level ${widget.levelId}');
      }
      
      print('Loaded lesson: ${_currentLesson!.title} with ${_currentLesson!.pageCount} pages');
    } catch (error) {
      print('Error loading lesson: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load lesson: $error'),
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

  void _navigateToPage(int pageIndex, {bool animate = true}) {
    if (pageIndex < 0 || pageIndex >= _currentPageCount) return;
    
    if (animate) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.jumpToPage(pageIndex);
    }
    
    setState(() {
      _currentPageIndex = pageIndex;
    });
  }

  void _goToNextPage() {
    if (_currentPageCount == 0) return;
    
    if (_currentPageIndex >= _currentPageCount - 1) {
      // Show snackbar when at last page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is the last page.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    _navigateToPage(_currentPageIndex + 1);
  }

  void _goToPreviousPage() {
    if (_currentPageIndex <= 0) {
      // Show snackbar when at first page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You\'re at the first page; click X to leave.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    _navigateToPage(_currentPageIndex - 1);
  }

  void _exitLesson() {
    Navigator.of(context).pop();
  }

  void _showCrudMenu() {
    if (_currentLesson == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CrudMenu(
        unitId: widget.unitId,
        levelId: widget.levelId,
        currentPageIndex: _currentPageIndex,
        lesson: _currentLesson!,
        onPageAdded: _onPageAdded,
        onPageDeleted: _onPageDeleted,
        onPageUpdated: _onPageUpdated,
      ),
    );
  }

  void _onPageAdded(int index) async {
    // Refresh lesson from provider (now async)
    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    _currentLesson = await lessonsProvider.getLesson(widget.unitId, widget.levelId);
    
    setState(() {});
    
    // Navigate to the new page
    _navigateToPage(index);
  }

  void _onPageDeleted(int deletedIndex) async {
    // Refresh lesson from provider (now async)
    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    _currentLesson = await lessonsProvider.getLesson(widget.unitId, widget.levelId);
    
    // Adjust current page index if necessary
    if (_currentPageIndex >= deletedIndex && _currentPageIndex > 0) {
      _currentPageIndex = _currentPageIndex - 1;
    }
    
    setState(() {});
    
    // Navigate to adjusted page
    _navigateToPage(_currentPageIndex, animate: false);
  }

  void _onPageUpdated() async {
    // Refresh lesson from provider (now async)
    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    _currentLesson = await lessonsProvider.getLesson(widget.unitId, widget.levelId);
    
    setState(() {});
  }

  String _generateRandomLetter() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random();
    return letters[random.nextInt(letters.length)];
  }

  Widget _buildPage(PageModel page) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: page.backgroundColor,
      child: Center(
        child: page.randomPlaceholder
            ? Text(
                _generateRandomLetter(),
                style: const TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black26,
                    ),
                  ],
                ),
              )
            : Container(), // Empty container if no placeholder
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          IconButton(
            onPressed: _goToPreviousPage,
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 30,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
          ),
          
          // X button (exit)
          IconButton(
            onPressed: _exitLesson,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 30,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
          ),
          
          // Next button
          IconButton(
            onPressed: _goToNextPage,
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 30,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    if (_currentPageCount <= 1) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_currentPageCount, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == _currentPageIndex
                  ? Colors.white
                  : Colors.white54,
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentLesson == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lesson Error'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Lesson not found',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Page view with real-time streaming from Firebase
          Consumer<LessonsProvider>(
            builder: (context, lessonsProvider, child) {
              return StreamBuilder<List<PageModel>>(
                stream: lessonsProvider.getPagesStream(widget.unitId, widget.levelId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Error loading pages: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }
                  
                  final pages = snapshot.data ?? [];
                  if (pages.isEmpty) {
                    return const Center(
                      child: Text('No pages found'),
                    );
                  }
                  
                  // Update current page count
                  _currentPageCount = pages.length;
                  
                  // Ensure current page index is within bounds
                  if (_currentPageIndex >= pages.length) {
                    _currentPageIndex = pages.length - 1;
                  }
                  
                  return PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                    },
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(pages[index]);
                    },
                  );
                },
              );
            },
          ),
          
          // Navigation controls
          _buildNavigationControls(),
          
          // Page indicator
          _buildPageIndicator(),
        ],
      ),
      
      // Admin CRUD button
      floatingActionButton: widget.adminMode
          ? FloatingActionButton.extended(
              onPressed: _showCrudMenu,
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              label: const Text('CRUD'),
              icon: const Icon(Icons.edit),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
