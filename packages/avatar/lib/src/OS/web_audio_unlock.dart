// web_audio_unlock.dart
// Only compiled for web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Call this once, preferably from `main()` or the first clickable widget.
/// On mobile browsers it resumes the suspended AudioContext so RemoteAudioTracks
/// can actually play.
void registerWebAudioUnlock() {
  if (html.window.navigator.userAgent.contains('Mozilla')) { // crude 'isWeb'
    void _unlock(_) {
      try {
        // A single, empty `Audio()` element is enough to resume every context.
        final audio = html.AudioElement();
        audio.play().catchError((_) {}); // ignore DOMException
      } finally {
        html.window.removeEventListener('touchend', _unlock);
        html.window.removeEventListener('click', _unlock);
      }
    }

    // First real user gesture will trigger it
    html.window.addEventListener('touchend', _unlock);
    html.window.addEventListener('click', _unlock);
  }
}
