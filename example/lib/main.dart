import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:avatar_sts2/avatar_sts2.dart';
import 'firebase_options.dart';
import 'pages/intro_page.dart';
import 'pages/video_call_page.dart';
import 'pages/steps_page.dart'; // Now contains SectionsPage
import 'providers/sections_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/user_stats_provider.dart';
import 'providers/lesson_progress_provider.dart';
import 'data/providers/units_provider.dart';
import 'data/providers/lessons_provider.dart';
import 'data/services/lessons_service.dart';
import 'services/language_provider.dart';
import 'theme/app_colors.dart';
import 'presentation/pages/units_page.dart';
import 'presentation/pages/lesson_page.dart';
import 'controllers/page_transition_controller.dart';

// Admin configuration - set to true to enable CRUD features
const bool adminLogin = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive for optional local caching
  await Hive.initFlutter();
  final lessonsBox = await Hive.openBox('lessons_cache');
  
  // Initialize Firebase services
  final lessonsService = LessonsService();
  
  // Initialize web audio unlock for mobile browsers
  if (kIsWeb) {
    registerWebAudioUnlock();
  }
  
  // Initialize GetX controller
  Get.put(PageTransitionController());
  
  runApp(MyApp(
    lessonsBox: lessonsBox,
    lessonsService: lessonsService,
  ));
}

class MyApp extends StatelessWidget {
  final Box lessonsBox;
  final LessonsService lessonsService;
  
  const MyApp({
    super.key, 
    required this.lessonsBox,
    required this.lessonsService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => VideoCallVisibilityProvider()),
        ChangeNotifierProvider(create: (_) => IntroPageVisibilityProvider()),
        ChangeNotifierProvider(create: (_) => AvatarProvider()),
        ChangeNotifierProvider(create: (_) => SectionsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => UserStatsProvider()),
        ChangeNotifierProvider(create: (_) => LessonProgressProvider()),
        ChangeNotifierProvider(create: (_) => UnitsProvider()),
        ChangeNotifierProvider(create: (_) => LessonsProvider(lessonsService, lessonsBox)),
      ],
      child: GetMaterialApp(
        title: 'Huda Avatar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppStack(),
        // Remove lesson route as it will be handled within AppStack
        routes: {
          '/units': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return UnitsPage(
              sectionId: args?['sectionId'],
              unitId: args?['unitId'],
            );
          },
        },
      ),
    );
  }
}

// Provider for managing video call visibility
class VideoCallVisibilityProvider extends ChangeNotifier {
  bool _isVisible = false;
  
  bool get isVisible => _isVisible;
  
  void show() {
    _isVisible = true;
    notifyListeners();
  }
  
  void hide() {
    _isVisible = false;
    notifyListeners();
  }
}

// Provider for managing intro page visibility
class IntroPageVisibilityProvider extends ChangeNotifier {
  bool _isVisible = true; // Start visible
  
  bool get isVisible => _isVisible;
  
  void show() {
    _isVisible = true;
    notifyListeners();
  }
  
  void hide() {
    _isVisible = false;
    notifyListeners();
  }
}

// Provider for sharing avatar instance between pages
class AvatarProvider extends ChangeNotifier {
  TavusAvatar? _avatar;
  
  TavusAvatar? get avatar => _avatar;
  
  void setAvatar(TavusAvatar avatar) {
    _avatar = avatar;
    notifyListeners();
  }
  
  void clearAvatar() {
    _avatar?.dispose();
    _avatar = null;
    notifyListeners();
  }
}

class AppStack extends StatelessWidget {
  const AppStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<VideoCallVisibilityProvider, IntroPageVisibilityProvider>(
        builder: (context, videoCallProvider, introProvider, child) {
          return GetBuilder<PageTransitionController>(
            builder: (transitionController) {
              print("GetBuilder rebuilding - showUnitsPage: ${transitionController.showUnitsPage}, showLessonPage: ${transitionController.showLessonPage}");
              
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
                      adminMode: adminLogin,
                    ),
                  
                  // Video call page - ALWAYS MOUNTED but visibility controlled
                  VideoCallPage(isVisible: videoCallProvider.isVisible),
                  
                  // Intro page - controlled by IntroPageVisibilityProvider, on top when visible
                  if (introProvider.isVisible)
                    const IntroPage(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
