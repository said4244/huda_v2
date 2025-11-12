// web_audio_manager.dart
// Web-specific audio management for iOS Safari
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'web_audio_unlock.dart';
import '../utils/logger.dart';

/// Set up web audio resumption for iOS Safari
void setupWebAudioResumption() {
  if (html.window.navigator.userAgent.contains('Mozilla')) { // crude 'isWeb'
    TavusLogger.info('Setting up web audio resumption for iOS Safari');
    
    // Listen for visibility changes
    html.document.onVisibilityChange.listen((_) async {
      if (html.document.hidden == false) {
        TavusLogger.info('Tab became visible - attempting audio resume');
        try {
          // Try to resume audio context by replaying silent audio
          registerWebAudioUnlock();
          TavusLogger.info('Audio context resumed successfully');
        } catch (e) {
          TavusLogger.warning('Failed to resume audio context: $e');
        }
      }
    });
  }
}
