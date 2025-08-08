import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'pages/steps_page.dart';
import 'providers/sections_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/user_stats_provider.dart';
import 'data/providers/units_provider.dart';
import 'data/providers/lessons_provider.dart';
import 'presentation/pages/units_page.dart';
import 'presentation/pages/lesson_page.dart';
import 'theme/app_colors.dart';
import 'controllers/page_transition_controller.dart';

// Test admin configuration - set to true to enable CRUD features in test
const bool testAdminLogin = true;

/// Quick test app to preview the sections page without going through the full flow
/// 
/// To run this instead of main.dart:
/// 1. Temporarily change this file name to main.dart (or rename the original main.dart)
/// 2. Run: flutter run --hot
/// 3. You'll see only the sections page for quick UI testing
/// 
/// OR create a separate entry point by running:
/// flutter run -t lib/test.dart --hot
void main() {
  // Initialize GetX controller for test environment
  Get.put(PageTransitionController());
  
  runApp(const TestSectionsApp());
}

/// Switch between different test modes by changing this:
/// - TestSectionsApp() for sections page
/// - UnitsPageTest() for units page  
/// - MinimalSectionsTest() for minimal sections
/// - LessonPageTest() for lesson page with CRUD
// void main() => runApp(const UnitsPageTest());
// void main() => runApp(const LessonPageTest());

class TestSectionsApp extends StatelessWidget {
  const TestSectionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SectionsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => UserStatsProvider()),
        ChangeNotifierProvider(create: (_) => UnitsProvider()),
        ChangeNotifierProvider(create: (_) => LessonsProvider()),
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
          '/lesson': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return LessonPage(
              unitId: args?['unitId'] ?? '',
              levelId: args?['levelId'] ?? '',
              adminMode: testAdminLogin,
            );
          },
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
          print("Test GetBuilder rebuilding - showUnitsPage: ${transitionController.showUnitsPage}");
          
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
        ChangeNotifierProvider(create: (_) => LessonsProvider()),
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SectionsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => UserStatsProvider()),
        ChangeNotifierProvider(create: (_) => UnitsProvider()),
        ChangeNotifierProvider(create: (_) => LessonsProvider()),
      ],
      child: MaterialApp(
        title: 'Units Test',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const UnitsPage(
          sectionId: 'section_1', // Test with section 1
        ),
        routes: {
          '/lesson': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return LessonPage(
              unitId: args?['unitId'] ?? '',
              levelId: args?['levelId'] ?? '',
              adminMode: testAdminLogin,
            );
          },
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
        ChangeNotifierProvider(create: (_) => LessonsProvider()),
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
