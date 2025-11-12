import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:avatar_sts2/avatar_sts2.dart';
import 'pages/intro_page.dart';
import 'pages/video_call_page.dart';
import 'pages/steps_page.dart'; // Now contains SectionsPage
import 'providers/sections_provider.dart';
import 'providers/navigation_provider.dart';
import 'services/language_provider.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize web audio unlock for mobile browsers
  if (kIsWeb) {
    registerWebAudioUnlock();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => VideoCallVisibilityProvider()),
        ChangeNotifierProvider(create: (_) => IntroPageVisibilityProvider()),
        ChangeNotifierProvider(create: (_) => SectionsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        title: 'Huda Avatar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppStack(),
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
// DEPRECATED: Avatar lifecycle now fully managed in video_call_page.dart
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
          return Stack(
            children: [
              // Always mounted - Sections page underneath
              const SectionsPage(),
              
              // Video call page - ALWAYS MOUNTED but visibility controlled
              VideoCallPage(isVisible: videoCallProvider.isVisible),
              
              // Intro page - controlled by IntroPageVisibilityProvider, on top when visible
              if (introProvider.isVisible)
                const IntroPage(),
            ],
          );
        },
      ),
    );
  }
}
