import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:avatar_sts2/avatar_sts2.dart';
import 'dart:convert';
void main() {
  if (kIsWeb) {
    // Register web audio unlock for RemoteAudioTracks
    registerWebAudioUnlock();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tavus Avatar Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AvatarDemo(),
    );
  }
}

class AvatarDemo extends StatefulWidget {
  const AvatarDemo({super.key});

  @override
  State<AvatarDemo> createState() => _AvatarDemoState();
}

class _AvatarDemoState extends State<AvatarDemo> with SingleTickerProviderStateMixin {
  late final TavusAvatar avatar;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _avatarVisible = true; // Track avatar visibility
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isSendingMessage = false;
  bool _hasMessageText = false;
  final _avatarKey = GlobalKey<TavusAvatarViewState>();

  @override
  void initState() {
    super.initState();
    
    // Initialize avatar - that's all the configuration needed!
    avatar = TavusAvatar(
      config: const TavusAvatarConfig(
        tokenUrl: 'https://safeguard-real.ngrok.pro/token',
        roomName: '',
        enableLogging: true,
      ),
    );
    
    // Pulse animation for the button
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Listen to avatar state changes
    avatar.stateStream.listen((state) {
      if (state == AvatarState.connected) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    });
    
    // Listen to text changes to enable/disable send button
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasMessageText) {
        setState(() {
          _hasMessageText = hasText;
        });
      }
    });
  }

  // Avatar visibility control methods
  Future<void> _hideAvatar() async {
    try {
      await avatar.publishData(json.encode({
        'type': 'avatar_control',
        'command': 'hide_avatar',
        'timestamp': DateTime.now().toIso8601String(),
      }));
      
      setState(() {
        _avatarVisible = false;
      });
      
      print('Hide avatar command sent');
    } catch (e) {
      print('Error hiding avatar: $e');
    }
  }

  Future<void> _showAvatar() async {
    try {
      await avatar.publishData(json.encode({
        'type': 'avatar_control',
        'command': 'show_avatar', 
        'timestamp': DateTime.now().toIso8601String(),
      }));
      
      setState(() {
        _avatarVisible = true;
      });
      
      print('Show avatar command sent');
    } catch (e) {
      print('Error showing avatar: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    avatar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Column(
          children: [
            // App Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tavus AI Avatar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  
                  // Connection indicator
                  StreamBuilder<AvatarState>(
                    stream: avatar.stateStream,
                    initialData: avatar.state,
                    builder: (context, snapshot) {
                      final state = snapshot.data!;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStateColor(state).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStateColor(state),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStateColor(state),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStateText(state),
                              style: TextStyle(
                                color: _getStateColor(state),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Avatar video display and message input
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    // Message input section (left side)
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Send a Message',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                focusNode: _messageFocusNode,
                                maxLines: null,
                                expands: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Type your message here...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Debug info
                            if (kDebugMode)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Debug: Connected=${avatar.isConnected}, HasText=$_hasMessageText, Sending=$_isSendingMessage',
                                  style: TextStyle(
                                    color: Colors.yellow.withOpacity(0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            // Send button
                            StreamBuilder<AvatarState>(
                              stream: avatar.stateStream,
                              initialData: avatar.state,
                              builder: (context, snapshot) {
                                final isConnected = snapshot.data == AvatarState.connected;
                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: (isConnected && 
                                               !_isSendingMessage && 
                                               _hasMessageText)
                                        ? () async {
                                            setState(() => _isSendingMessage = true);
                                            try {
                                              final message = _messageController.text.trim();
                                              print('Sending message: "$message"');
                                              await avatar.sendTextMessage(message);
                                              _messageController.clear();
                                              print('Message sent successfully');
                                            } catch (e) {
                                              print('Error sending message: $e');
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Failed to send message: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            } finally {
                                              setState(() => _isSendingMessage = false);
                                            }
                                          }
                                        : null,
                                    icon: _isSendingMessage 
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.send),
                                    label: Text(_isSendingMessage ? 'Sending...' : 'Send Message'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      backgroundColor: Colors.blue.withOpacity(0.8),
                                      disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (!avatar.isConnected)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Connect to avatar first',
                                  style: TextStyle(
                                    color: Colors.orange.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            // Quick test button for debugging
                            if (kDebugMode && avatar.isConnected)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      print('Test button pressed');
                                      await avatar.sendTextMessage('Test message from debug button');
                                      print('Test message sent successfully');
                                    } catch (e) {
                                      print('Test message failed: $e');
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple.withOpacity(0.3),
                                    foregroundColor: Colors.purple,
                                  ),
                                  child: const Text('Test Send'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Avatar video (right side)
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: TavusAvatarView(
                            key: _avatarKey,
                            avatar: avatar,
                            aspectRatio: 9 / 16,
                            borderRadius: BorderRadius.circular(24),
                            showStatus: false,
                            placeholder: _buildCustomPlaceholder(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Control section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Status text
                  StreamBuilder<String>(
                    stream: avatar.statusStream,
                    initialData: avatar.status,
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Main toggle button
                  StreamBuilder<AvatarState>(
                    stream: avatar.stateStream,
                    initialData: avatar.state,
                    builder: (context, snapshot) {
                      final state = snapshot.data!;
                      final isActive = state == AvatarState.connected || 
                                       state == AvatarState.connecting;
                      
                      return GestureDetector(
                        onTap: () => avatar.toggle(),
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isActive ? _pulseAnimation.value : 1.0,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isActive
                                        ? [Colors.red.shade400, Colors.red.shade700]
                                        : [Colors.green.shade400, Colors.green.shade700],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isActive ? Colors.red : Colors.green)
                                          .withOpacity(0.5),
                                      blurRadius: isActive ? 40 : 20,
                                      spreadRadius: isActive ? 5 : 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isActive ? Icons.stop : Icons.play_arrow,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Microphone controls (only show when connected)
                  StreamBuilder<AvatarState>(
                    stream: avatar.stateStream,
                    initialData: avatar.state,
                    builder: (context, snapshot) {
                      final state = snapshot.data!;
                      if (state != AvatarState.connected) {
                        return const SizedBox.shrink();
                      }
                      
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Microphone toggle
                              GestureDetector(
                                onTap: () {
                                  if (avatar.isMicrophoneEnabled) {
                                    avatar.stopTalking();
                                  } else {
                                    avatar.startTalking();
                                  }
                                  setState(() {});
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: avatar.isMicrophoneEnabled 
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.2),
                                    border: Border.all(
                                      color: avatar.isMicrophoneEnabled 
                                          ? Colors.green 
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    avatar.isMicrophoneEnabled 
                                        ? Icons.mic 
                                        : Icons.mic_off,
                                    size: 30,
                                    color: avatar.isMicrophoneEnabled 
                                        ? Colors.green 
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              
                              // Speaking indicator
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: avatar.isSpeaking 
                                      ? Colors.blue.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.1),
                                  border: Border.all(
                                    color: avatar.isSpeaking 
                                        ? Colors.blue 
                                        : Colors.grey.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.record_voice_over,
                                  size: 30,
                                  color: avatar.isSpeaking 
                                      ? Colors.blue 
                                      : Colors.grey.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(width: 20),
                              
                              // Picture-in-Picture button
                              GestureDetector(
                                onTap: () => print("PiP deprecated"),//_avatarKey.currentState?.togglePiP(),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.purple.withOpacity(0.2),
                                    border: Border.all(
                                      color: Colors.purple,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.picture_in_picture_alt,
                                    size: 30,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          Text(
                            avatar.isMicrophoneEnabled 
                                ? 'Microphone ON - Speak now!' 
                                : 'Tap microphone to start talking',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          
                          Text(
                            'Tap PiP button for Picture-in-Picture mode',
                            style: TextStyle(
                              color: Colors.purple.withOpacity(0.6),
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                  
                  // Avatar visibility controls (only show when connected)
                  StreamBuilder<AvatarState>(
                    stream: avatar.stateStream,
                    initialData: avatar.state,
                    builder: (context, snapshot) {
                      final state = snapshot.data!;
                      if (state != AvatarState.connected) {
                        return const SizedBox.shrink();
                      }
                      
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'Avatar Controls',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Hide Avatar Button
                              ElevatedButton.icon(
                                onPressed: _avatarVisible ? _hideAvatar : null,
                                icon: const Icon(Icons.visibility_off, size: 16),
                                label: const Text('Hide Avatar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _avatarVisible 
                                      ? Colors.orange.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.1),
                                  foregroundColor: _avatarVisible 
                                      ? Colors.orange 
                                      : Colors.grey,
                                  side: BorderSide(
                                    color: _avatarVisible 
                                        ? Colors.orange 
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16, 
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Show Avatar Button
                              ElevatedButton.icon(
                                onPressed: !_avatarVisible ? _showAvatar : null,
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text('Show Avatar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !_avatarVisible 
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.1),
                                  foregroundColor: !_avatarVisible 
                                      ? Colors.green 
                                      : Colors.grey,
                                  side: BorderSide(
                                    color: !_avatarVisible 
                                        ? Colors.green 
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16, 
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _avatarVisible 
                                ? 'Avatar is visible' 
                                : 'Voice-only mode',
                            style: TextStyle(
                              color: _avatarVisible 
                                  ? Colors.green.withOpacity(0.7)
                                  : Colors.orange.withOpacity(0.7),
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                  
                  Text(
                    'Tap to ${avatar.isConnected ? 'stop' : 'start'} conversation',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Info about automatic fallback
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Agent automatically handles fallback to OpenAI Realtime if custom STS stack encounters errors',
                            style: TextStyle(
                              color: Colors.blue.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepPurple.shade900,
            Colors.purple.shade800,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle,
            size: 100,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'AI Avatar',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 24,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to chat',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStateColor(AvatarState state) {
    switch (state) {
      case AvatarState.connected:
        return Colors.green;
      case AvatarState.connecting:
      case AvatarState.reconnecting:
        return Colors.orange;
      case AvatarState.error:
        return Colors.red;
      case AvatarState.disconnected:
        return Colors.grey;
    }
  }

  String _getStateText(AvatarState state) {
    switch (state) {
      case AvatarState.connected:
        return 'Connected';
      case AvatarState.connecting:
        return 'Connecting';
      case AvatarState.reconnecting:
        return 'Reconnecting';
      case AvatarState.error:
        return 'Error';
      case AvatarState.disconnected:
        return 'Offline';
    }
  }
}