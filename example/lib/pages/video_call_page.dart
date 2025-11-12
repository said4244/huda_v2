import 'package:flutter/material.dart';
import 'package:avatar_sts2/avatar_sts2.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class VideoCallPage extends StatefulWidget {
  final bool isVisible;
  
  const VideoCallPage({
    super.key, 
    required this.isVisible,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

/*
 * MICROPHONE CONTROL IMPLEMENTATION FOR PIP MODE
 * 
 * Architecture Overview:
 * This implementation provides automatic microphone control based on PiP state
 * to prevent user speech from interrupting avatar explanations in PiP mode.
 * 
 * Key Design Decisions:
 * 
 * 1. FRONTEND-ONLY SOLUTION:
 *    - Uses existing TavusAvatar.startTalking()/stopTalking() methods
 *    - No backend/server changes required
 *    - Leverages built-in LiveKit microphone controls
 * 
 * 2. AUTOMATIC STATE MANAGEMENT:
 *    - Fullscreen Mode: Passive microphone listening ENABLED
 *    - PiP Mode: Passive microphone listening DISABLED
 *    - Manual controls (exercise buttons) remain unaffected
 * 
 * 3. LIFECYCLE INTEGRATION:
 *    - Initial state: Microphone enabled when avatar becomes visible
 *    - PiP toggle: Automatic mic disable/enable
 *    - Call end: Clean mic disable
 * 
 * 4. SAFE & ROBUST:
 *    - Error handling for all mic operations
 *    - State tracking to prevent conflicts
 *    - Visual indicators for user feedback
 * 
 * 5. FUTURE-PROOF:
 *    - Manual control tracking for exercise integration
 *    - Extensible for pause/resume speaking states
 *    - Clean abstraction for reusability
 * 
 * Methods:
 * - _enablePassiveMicrophoneListening(): Enable mic for fullscreen
 * - _disablePassiveMicrophoneListening(): Disable mic for PiP
 * - setMicrophoneEnabled(): Manual control for exercises
 * 
 * Integration Points:
 * - _toggleCustomPiP(): Automatic mic state switching
 * - _transitionFromIntroToVideoCall(): Initial mic enable
 * - _endCall(): Final mic cleanup
 */

class _VideoCallPageState extends State<VideoCallPage> with TickerProviderStateMixin {
  TavusAvatar? _avatar;
  bool _isPiP = false;  // Custom in-app PiP state
  bool _callEnded = false;
  bool _greetingSent = false;
  bool _avatarInitialized = false;
  bool _avatarConnected = false;
  bool _videoTrackReceived = false;
  bool _isFullyVisible = false;  // When video should be shown
  final _messageController = TextEditingController();
  
  // PiP position tracking
  Offset _pipPosition = Offset.zero;  // Will be initialized properly
  
  // Microphone state tracking for PiP behavior
  /// Tracks if microphone was manually controlled (vs automatic PiP control)
  /// This ensures manual exercise controls don't conflict with PiP automation
  bool _isMicrophoneManuallyControlled = false;
  
  // Animation controllers for smooth transitions
  late AnimationController _pipAnimationController;
  late Animation<double> _pipOpacity;

  @override
  void initState() {
    super.initState();
    print("VideoCallPage initState - Page always mounted and ready");
    
    // Initialize animation controllers
    _pipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pipOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pipAnimationController, curve: Curves.easeInOut),
    );
    
    // Start avatar initialization immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAvatar();
    });
  }

  void _initializeAvatar() async {
    if (_avatarInitialized) return;
    _avatarInitialized = true;
    
    print("Initializing TavusAvatar in VideoCallPage from start");
    
    // Create TavusAvatar instance
    _avatar = TavusAvatar(
      config: const TavusAvatarConfig(
        tokenUrl: 'https://safeguard-real.ngrok.pro/token',
        roomName: '',
        enableLogging: true,
      ),
    );
    
    // Listen to avatar state changes
    _avatar!.stateStream.listen((state) {
      print("Avatar state changed: $state");
      if (state == AvatarState.connected && !_avatarConnected) {
        setState(() => _avatarConnected = true);
        _checkReadyToShow();
      }
    });
    
    // Listen to video track changes
    _avatar!.videoTrackStream.listen((track) {
      print("Video track received: ${track?.sid}");
      if (track != null) {
        print("Video track mediaStream: ${track.mediaStream}");
        if (!_videoTrackReceived) {
          setState(() => _videoTrackReceived = true);
          _checkReadyToShow();
        }
      }
    });
    
    // Start avatar connection
    try {
      print("Starting avatar connection...");
      await _avatar!.start();
      print("Avatar connection started successfully");
    } catch (e) {
      print("Error starting avatar connection: $e");
    }
  }

  void _checkReadyToShow() {
    // Show video call as soon as we have both connection and video track
    if (_avatarConnected && _videoTrackReceived && !_isFullyVisible) {
      print("Avatar ready! Making video call visible");
      setState(() => _isFullyVisible = true);
      _transitionFromIntroToVideoCall();
    }
  }

  void _transitionFromIntroToVideoCall() {
    // Trigger transition from intro to video call
    print("Triggering transition from intro to video call");
    context.read<VideoCallVisibilityProvider>().show();
    context.read<IntroPageVisibilityProvider>().hide();
    
    // Initialize microphone for fullscreen mode (passive listening enabled)
    _enablePassiveMicrophoneListening();
    
    // Send initial greeting
    _sendInitialGreeting();
  }

  void _sendInitialGreeting() async {
    if (_avatar != null && !_greetingSent) {
      _greetingSent = true;
      print("Sending initial greeting message");
      try {
        await _avatar!.sendTextMessage('مرحبا! أهلاً وسهلاً بك في تطبيق هُدى لتعلم اللغة العربية');
        print("Initial greeting sent successfully");
      } catch (e) {
        print("Error sending initial greeting: $e");
      }
    }
  }

  void _toggleCustomPiP() {
    setState(() {
      _isPiP = !_isPiP;
      
      // Initialize position at top-right when entering PiP mode
      if (_isPiP) {
        final screenSize = MediaQuery.of(context).size;
        final pipSize = _getPiPSize(context);
        _pipPosition = Offset(
          screenSize.width - pipSize.width - 20, // 20px margin from right
          50, // 50px from top
        );
      }
    });
    
    // Handle microphone state based on PiP mode
    if (_isPiP) {
      _pipAnimationController.forward();
      // Disable passive microphone listening in PiP mode
      _disablePassiveMicrophoneListening();
    } else {
      _pipAnimationController.reverse();
      // Re-enable passive microphone listening in fullscreen mode
      _enablePassiveMicrophoneListening();
    }
    
    print("Custom PiP toggled: ${_isPiP ? 'ON' : 'OFF'} - Mic listening: ${!_isPiP ? 'ENABLED' : 'DISABLED'}");
  }

  void _endCall() {
    setState(() {
      _callEnded = true;
    });
    
    // Clean up microphone state
    if (_avatar != null) {
      _avatar!.stopTalking();
    }
    
    // Hide video call page completely
    context.read<VideoCallVisibilityProvider>().hide();
    
    // Dispose avatar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _avatar?.dispose();
      _avatar = null;
    });
    
    print("Call ended - microphone disabled");
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty && _avatar != null) {
      print("Sending user message: $message");
      try {
        _avatar!.sendTextMessage(message);
        _messageController.clear();
      } catch (e) {
        print("Error sending message: $e");
      }
    }
  }

  Size _getPiPSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    if (isSmallScreen) {
      return const Size(200, 120);
    } else {
      return const Size(320, 200);
    }
  }

  Offset _clampPiPPosition(Offset position, Size pipSize, Size screenSize) {
    // Clamp position to stay within screen bounds
    final maxX = screenSize.width - pipSize.width - 20; // 20px margin
    final maxY = screenSize.height - pipSize.height - 20; // 20px margin
    
    return Offset(
      position.dx.clamp(20.0, maxX), // 20px minimum margin from left
      position.dy.clamp(20.0, maxY), // 20px minimum margin from top
    );
  }

  /// Enable passive microphone listening (fullscreen mode)
  Future<void> _enablePassiveMicrophoneListening() async {
    if (_avatar == null) return;
    
    try {
      print("Enabling passive microphone listening for fullscreen mode");
      await _avatar!.startTalking();  // This enables mic + STT processing
      _isMicrophoneManuallyControlled = false;
    } catch (e) {
      print("Error enabling passive microphone listening: $e");
    }
  }

  /// Disable passive microphone listening (PiP mode)
  Future<void> _disablePassiveMicrophoneListening() async {
    if (_avatar == null) return;
    
    try {
      print("Disabling passive microphone listening for PiP mode");
      await _avatar!.stopTalking();  // This disables mic + STT processing
      _isMicrophoneManuallyControlled = false;
    } catch (e) {
      print("Error disabling passive microphone listening: $e");
    }
  }

  /// Manually control microphone (for exercise-specific buttons)
  /// This method should be called by exercise widgets when they need
  /// to override the automatic PiP microphone behavior
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (_avatar == null) return;
    
    try {
      print("Manual microphone control: ${enabled ? 'enabled' : 'disabled'}");
      await _avatar!.setMicrophoneEnabled(enabled);
      _isMicrophoneManuallyControlled = enabled; // Track manual override
    } catch (e) {
      print("Error in manual microphone control: $e");
    }
  }

  /// Check if microphone is currently enabled
  bool get isMicrophoneEnabled => _avatar?.isMicrophoneEnabled ?? false;

  /// Check if we're in a state where passive listening should be active
  bool get shouldHavePassiveListening => !_isPiP && !_isMicrophoneManuallyControlled;

  Widget _buildFullscreenVideo() {
    if (_avatar == null) return const SizedBox.shrink();
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        Container(color: const Color(0xFFFFF6E9)),
        
        // Avatar video
        TavusAvatarView(
          avatar: _avatar!,
          aspectRatio: 9 / 16,
          borderRadius: BorderRadius.zero,
          showStatus: false,
          placeholder: Container(
            color: Colors.black12,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _avatarConnected 
                      ? 'Waiting for video...' 
                      : 'Connecting to avatar...',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        
        // Message input
        Positioned(
          bottom: 100,
          left: 16,
          right: 16,
          child: _buildMessageInput(),
        ),
        
        // Control buttons for fullscreen
        Positioned(
          top: 50,
          right: 16,
          child: Column(
            children: [
              // Microphone status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isPiP ? Colors.red.withOpacity(0.8) : Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPiP ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isPiP ? 'Mic Off' : 'Listening',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                heroTag: "pip_toggle",
                onPressed: _toggleCustomPiP,
                backgroundColor: Colors.black54,
                child: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                heroTag: "end_call",
                onPressed: _endCall,
                backgroundColor: Colors.red,
                child: const Icon(Icons.call_end, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPiPVideo(BuildContext context) {
    if (_avatar == null) return const SizedBox.shrink();
    
    final pipSize = _getPiPSize(context);
    final screenSize = MediaQuery.of(context).size;
    
    return AnimatedBuilder(
      animation: _pipAnimationController,
      builder: (context, child) {
        return Positioned(
          left: _pipPosition.dx,
          top: _pipPosition.dy,
          child: Opacity(
            opacity: _pipOpacity.value,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  final newPosition = Offset(
                    _pipPosition.dx + details.delta.dx,
                    _pipPosition.dy + details.delta.dy,
                  );
                  _pipPosition = _clampPiPPosition(newPosition, pipSize, screenSize);
                });
              },
              child: Container(
                width: pipSize.width,
                height: pipSize.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // PiP video
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: TavusAvatarView(
                        avatar: _avatar!,
                        aspectRatio: 16 / 10,
                        borderRadius: BorderRadius.circular(12),
                        showStatus: false,
                      ),
                    ),
                    
                    // PiP control buttons
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _toggleCustomPiP,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: _endCall,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send, color: Color(0xFF6C3428)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything and don't absorb gestures if not supposed to be visible
    if (!widget.isVisible || !_isFullyVisible || _callEnded) {
      return const IgnorePointer(
        child: SizedBox.shrink(),
      );
    }

    // If in PiP mode, only return the PiP widget in a Stack (Positioned needs Stack)
    if (_isPiP) {
      return IgnorePointer(
        ignoring: false, // Allow touches only on the PiP video itself
        child: Stack(
          children: [
            _buildPiPVideo(context),
          ],
        ),
      );
    }

    // Full screen mode - return the full Scaffold
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E9),
      body: _buildFullscreenVideo(),
    );
  }

  @override
  void dispose() {
    print("VideoCallPage dispose");
    _messageController.dispose();
    _pipAnimationController.dispose();
    
    // Dispose avatar if we own it
    if (_avatar != null) {
      _avatar!.dispose();
      _avatar = null;
    }
    
    super.dispose();
  }
}
