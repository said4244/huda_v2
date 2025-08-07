import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  late final VideoPlayerController _controller;
  bool _videoReady = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize intro video with mobile Safari compatibility
    _controller = VideoPlayerController.asset('assets/videos/intro_final.mp4')
      ..setLooping(true) // Loop the intro video
      ..initialize().then((_) {
        // Mobile Safari compatibility - mute and enable playsinline
        if (kIsWeb) {
          _controller.setVolume(0); // Muted for autoplay
        }
        setState(() => _videoReady = true);
        _controller.play();
        
        // Start avatar initialization in video_call_page after a delay
        _startAvatarInitialization();
      });
  }

  void _startAvatarInitialization() {
    // Avatar initialization is now handled automatically in video_call_page.dart
    // Just wait for the intro video to play for a moment
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_navigated) {
        print("Intro video finished, avatar should be initializing in background");
      }
    });
  }

  void transitionToVideoCall() {
    if (_navigated) return;
    _navigated = true;
    
    // Stop intro video
    _controller.pause();
    
    if (mounted) {
      // The transition will be handled by video_call_page.dart when ready
      print("Intro page ready for transition");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final videoHeight = width * (16 / 9) * 0.4;
          final fontSize = width * 0.12;
          
          return Container(
            alignment: Alignment.center,
            color: const Color(0xFFFFF6E9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Video player with mobile Safari compatibility
                SizedBox(
                  height: videoHeight,
                  child: _videoReady 
                    ? AspectRatio(
                        aspectRatio: 16 / 9,
                        child: VideoPlayer(_controller),
                      )
                    : const CircularProgressIndicator(),
                ),
                const SizedBox(height: 32),
                Text(
                  'Huda',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6C3428),
                  ),
                ),
                const SizedBox(height: 16),
                // Loading indicator for avatar initialization
                if (!_navigated) ...[
                  const SizedBox(height: 16),
                  Text(
                    'جاري الاتصال...',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF6C3428).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C3428)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
