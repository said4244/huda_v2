import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'pages/steps_page.dart';
import 'providers/sections_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/user_stats_provider.dart';
import 'data/providers/units_provider.dart';
import 'data/providers/lessons_provider.dart';
import 'data/services/lessons_service.dart';
import 'presentation/pages/units_page.dart';
import 'presentation/pages/lesson_page.dart';
import 'theme/app_colors.dart';
import 'controllers/page_transition_controller.dart';

// Test admin configuration - set to true to enable CRUD features in test
const bool testAdminLogin = true;

// Global test references for sharing across test widgets
late Box _globalTestLessonsBox;
late LessonsService _globalTestLessonsService;

/// Quick test app to preview the sections page without going through the full flow
/// 
/// To run this instead of main.dart:
/// 1. Temporarily change this file name to main.dart (or rename the original main.dart)
/// 2. Run: flutter run --hot
/// 3. You'll see only the sections page for quick UI testing
/// 
/// OR create a separate entry point by running:
/// flutter run -t lib/test.dart --hot
void main() async {
  // Initialize GetX controller, Firebase, and Hive for test environment
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (same as main.dart)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive for local caching (same as main.dart)
  await Hive.initFlutter();
  final testLessonsBox = await Hive.openBox('test_lessons_cache'); // Separate cache for testing
  _globalTestLessonsBox = testLessonsBox;
  
  // Initialize Firebase services
  final testLessonsService = LessonsService();
  _globalTestLessonsService = testLessonsService;
  
  Get.put(PageTransitionController());
  
  runApp(TestSectionsApp(
    lessonsBox: testLessonsBox,
    lessonsService: testLessonsService,
  ));
}

/// Switch between different test modes by changing this:
/// - TestSectionsApp() for sections page
/// - UnitsPageTest() for units page  
/// - MinimalSectionsTest() for minimal sections
/// - LessonPageTest() for lesson page with CRUD
// void main() => runApp(const UnitsPageTest());
// void main() => runApp(const LessonPageTest());

class TestSectionsApp extends StatelessWidget {
  final Box lessonsBox;
  final LessonsService lessonsService;
  
  const TestSectionsApp({
    super.key, 
    required this.lessonsBox,
    required this.lessonsService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SectionsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => UserStatsProvider()),
        ChangeNotifierProvider(create: (_) => UnitsProvider()),
        ChangeNotifierProvider(create: (_) => LessonsProvider(lessonsService, lessonsBox)),
      ],
      child: GetMaterialApp(
        title: 'Sections Test',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const TestAppStack(),
        routes: {
          '/units': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return UnitsPage(
              sectionId: args?['sectionId'],
              unitId: args?['unitId'],
            );
          },
          // Remove lesson route as it will be handled within TestAppStack
        },
      ),
    );
  }
}

/// Test version of AppStack to match main.dart behavior
/// This ensures that test.dart behaves the same way as main.dart with proper stack navigation
class TestAppStack extends StatelessWidget {
  const TestAppStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<PageTransitionController>(
        builder: (transitionController) {
          print("Test GetBuilder rebuilding - showUnitsPage: ${transitionController.showUnitsPage}, showLessonPage: ${transitionController.showLessonPage}");
          
          return Stack(
            children: [
              // Always mounted - Sections page underneath
              const SectionsPage(),
              
              // Units page - shown when transitioning
              if (transitionController.showUnitsPage)
                SlideTransition(
                  position: transitionController.slideAnimation,
                  child: UnitsPage(
                    sectionId: transitionController.currentSectionId,
                  ),
                ),
              
              // Lesson page - shown on top of units when active
              if (transitionController.showLessonPage)
                LessonPage(
                  unitId: transitionController.currentUnitId,
                  levelId: transitionController.currentLevelId,
                  adminMode: testAdminLogin,
                ),
              
              // Note: No video call page in test environment
              // No intro page in test environment - start directly with sections
            ],
          );
        },
      ),
    );
  }
}

class TestSectionsWrapper extends StatelessWidget {
  const TestSectionsWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionsPage();
  }
}

/// Alternative minimal version - just the sections page with no extras
class MinimalSectionsTest extends StatelessWidget {
  const MinimalSectionsTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SectionsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => UserStatsProvider()),
        ChangeNotifierProvider(create: (_) => UnitsProvider()),
        ChangeNotifierProvider(create: (_) => LessonsProvider(_globalTestLessonsService, _globalTestLessonsBox)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const SectionsPage(), // Direct sections page, no wrapper
      ),
    );
  }
}

/// Quick switch - uncomment this line and comment the main() above 
/// if you want the absolute minimal version:
// void main() => runApp(const MinimalSectionsTest());

/// Test app specifically for Units Page
class UnitsPageTest extends StatelessWidget {
  const UnitsPageTest({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize GetX controller for test
    Get.put(PageTransitionController());
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SectionsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => UserStatsProvider()),
        ChangeNotifierProvider(create: (_) => UnitsProvider()),
        ChangeNotifierProvider(create: (_) => LessonsProvider(_globalTestLessonsService, _globalTestLessonsBox)),
      ],
      child: GetMaterialApp(
        title: 'Units Test',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const UnitsTestStack(),
        // Remove lesson route as UnitsPage will use PageTransitionController navigation
      ),
    );
  }
}

/// Simple test stack for UnitsPageTest
class UnitsTestStack extends StatelessWidget {
  const UnitsTestStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<PageTransitionController>(
        builder: (transitionController) {
          return Stack(
            children: [
              // Units page as base
              const UnitsPage(
                sectionId: 'section_1', // Test with section 1
              ),
              
              // Lesson page - shown on top when active
              if (transitionController.showLessonPage)
                LessonPage(
                  unitId: transitionController.currentUnitId,
                  levelId: transitionController.currentLevelId,
                  adminMode: testAdminLogin,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Test app specifically for Lesson Page
class LessonPageTest extends StatelessWidget {
  const LessonPageTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LessonsProvider(_globalTestLessonsService, _globalTestLessonsBox)),
      ],
      child: MaterialApp(
        title: 'Lesson Test',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LessonPage(
          unitId: 'unit_1',
          levelId: 'level_1_1',
          adminMode: testAdminLogin, // Enable CRUD for testing
        ),
      ),
    );
  }
}
