library avatar_sts2;

// Main exports
export 'src/tavus_avatar_service.dart' show TavusAvatar;
export 'src/avatar_view.dart' show TavusAvatarView, TavusAvatarViewState;
export 'src/models/avatar_config.dart' show TavusAvatarConfig;
export 'src/models/avatar_state.dart' show AvatarState;

// Web-specific exports
export 'src/OS/web_audio_unlock.dart' show registerWebAudioUnlock;
export 'src/OS/web_audio_manager.dart' show setupWebAudioResumption;