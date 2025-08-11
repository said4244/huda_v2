import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../data/models/page_model.dart';
import '../../main.dart'; // For AvatarProvider
import 'package:avatar_sts2/avatar_sts2.dart';

/// Widget for displaying exercise introduction with video, headers, and interactive elements
class ExerciseIntroWidget extends StatefulWidget {
  final PageModel page;
  final VoidCallback? onContinue;

  const ExerciseIntroWidget({
    super.key,
    required this.page,
    this.onContinue,
  });

  @override
  State<ExerciseIntroWidget> createState() => _ExerciseIntroWidgetState();
}

class _ExerciseIntroWidgetState extends State<ExerciseIntroWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoReady = false;
  bool _videoWatched = false;
  bool _microphoneUsed = false;
  bool _isProcessingMessages = false;
  bool _videoError = false; // Track video loading errors
  TavusAvatar? _avatar; // This should be passed from parent or provider
  
  // UI state
  bool _isMicPressed = false;
  
  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _processInitialTriggers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get avatar from AvatarProvider
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
    _avatar = avatarProvider.avatar;
  }

  @override
  void didUpdateWidget(covariant ExerciseIntroWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if exercise data has changed
    if (oldWidget.page.exerciseData != widget.page.exerciseData) {
      // Dispose old video controller
      _videoController?.dispose();
      _videoController = null;
      
      // Reset state
      _isVideoReady = false;
      _videoWatched = false;
      _microphoneUsed = false;
      _isProcessingMessages = false;
      
      // Reinitialize with new data
      _initializeVideo();
      _processInitialTriggers();
      
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideo() {
    final exerciseData = widget.page.exerciseData ?? {};
    final videoName = exerciseData['videoName'] as String?;
    
    if (videoName != null) {
      print("Initializing video: assets/videos/$videoName");
      _videoController = VideoPlayerController.asset('assets/videos/$videoName');
      _videoController!.initialize().then((_) {
        print("Video initialized successfully: $videoName");
        setState(() {
          _isVideoReady = true;
        });
        
        // Listen for video completion
        _videoController!.addListener(_videoListener);
        
        // Auto-play if enabled and trigger is onStart
        final autoPlay = exerciseData['autoPlay'] as bool? ?? false;
        final videoTrigger = exerciseData['videoTrigger'] as String?;
        
        if (autoPlay && videoTrigger == 'onStart') {
          _videoController!.play();
        }
      }).catchError((error) {
        print("Error initializing video $videoName: $error");
        setState(() {
          _isVideoReady = false;
          _videoError = true; // Set error flag for UI display
          _videoController?.dispose();
          _videoController = null;
        });
      });
    }
  }

  void _videoListener() {
    if (_videoController != null && 
        _videoController!.value.position >= _videoController!.value.duration) {
      setState(() {
        _videoWatched = true;
      });
    }
  }

  void _processInitialTriggers() {
    final exerciseData = widget.page.exerciseData ?? {};
    final videoTrigger = exerciseData['videoTrigger'] as String?;
    
    if (videoTrigger == 'onStart') {
      _processSendMessages();
    }
  }

  Future<void> _processSendMessages() async {
    if (_isProcessingMessages) return;
    
    setState(() {
      _isProcessingMessages = true;
    });

    final exerciseData = widget.page.exerciseData ?? {};
    final sendMessages = exerciseData['sendMessages'] as List<dynamic>? ?? [];
    
    for (int i = 0; i < sendMessages.length; i++) {
      final message = sendMessages[i] as Map<String, dynamic>;
      final type = message['type'] as String;
      final content = message['content'] as String;
      final delaySeconds = (message['delaySeconds'] as num?)?.toDouble() ?? 0.0;
      
      if (type == 'avatarMessage' && _avatar != null) {
        // Use the new sendMessageAndWait helper to wait for speech end
        await _avatar!.sendMessageAndWait(content, timeout: const Duration(seconds: 15));
      } else if (type == 'video' && _videoController != null) {
        // Play video after delay
        if (delaySeconds > 0) {
          await Future.delayed(Duration(seconds: delaySeconds.round()));
        }
        _videoController!.play();
      }
      
      // Additional delay if specified
      if (delaySeconds > 0 && type == 'avatarMessage') {
        await Future.delayed(Duration(seconds: delaySeconds.round()));
      }
    }

    setState(() {
      _isProcessingMessages = false;
    });
  }

  void _onMicrophonePressStart() {
    final exerciseData = widget.page.exerciseData ?? {};
    final microphonePrompt = exerciseData['microphonePrompt'] as String? ?? '';
    
    setState(() {
      _isMicPressed = true;
    });

    if (_avatar != null && microphonePrompt.isNotEmpty) {
      // Send context prompt
      final contextPrompt = {
        'type': 'system_prompt',
        'content': 'The user will attempt to pronounce \'$microphonePrompt\'. Please evaluate their pronunciation: if at least 90% accurate, praise them; otherwise give corrective feedback.',
      };
      
      _avatar!.publishData(jsonEncode(contextPrompt));
      _avatar!.setMicrophoneEnabled(true);
    }
  }

  void _onMicrophonePressEnd() async {
    setState(() {
      _isMicPressed = false;
      _microphoneUsed = true;
    });

    if (_avatar != null) {
      await _avatar!.setMicrophoneEnabled(false);
      
      // Optional: Wait for avatar feedback to complete
      // This ensures user sees/hears the complete pronunciation feedback
      try {
        await _avatar!.eventStream
            .where((event) => event['type'] == 'avatar_speech_ended')
            .first
            .timeout(const Duration(seconds: 10)); // Timeout after 10s
      } catch (e) {
        // If no feedback comes, that's fine - continue normally
        print('No avatar feedback received or timeout: $e');
      }
    }
  }

  bool _areRequirementsMet() {
    final exerciseData = widget.page.exerciseData ?? {};
    final showMicrophone = exerciseData['showMicrophone'] as bool? ?? false;
    final videoName = exerciseData['videoName'] as String?;
    
    bool videoRequirementMet = videoName == null || _videoWatched;
    bool micRequirementMet = !showMicrophone || _microphoneUsed;
    
    return videoRequirementMet && micRequirementMet;
  }

  void _onContinuePressed() {
    // Mark exercise complete and call callback
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      // Fallback for cases where callback is not provided
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercise completed!'),
          backgroundColor: Color(0xFF4D382D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseData = widget.page.exerciseData ?? {};
    
    return Container(
      color: const Color(0xFFF2EFEB),
      child: Column(
        children: [
          // Scrollable content section
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderRow(exerciseData),
                  _buildVideoSection(exerciseData),
                  _buildHeader2(exerciseData),
                ],
              ),
            ),
          ),
          
          // Fixed bottom section
          Column(
            children: [
              _buildMicrophoneSection(exerciseData),
              _buildContinueButton(exerciseData),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(Map<String, dynamic> exerciseData) {
    final header1 = exerciseData['header1'] as String?;
    final transliteration = exerciseData['transliteration'] as String?;
    
    if (header1 == null && transliteration == null) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header1 != null)
            Expanded(
              flex: 3,
              child: Text(
                header1,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4D382D),
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          if (header1 != null && transliteration != null)
            const SizedBox(width: 16),
          if (transliteration != null)
            Expanded(
              flex: 2,
              child: Text(
                transliteration,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF4D382D),
                  fontFamily: 'Roboto',
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(Map<String, dynamic> exerciseData) {
    final videoName = exerciseData['videoName'] as String?;
    final allowUserVideoControl = exerciseData['allowUserVideoControl'] as bool? ?? false;
    
    if (videoName == null || _videoController == null) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black,
          ),
          child: _videoError
              ? _buildVideoErrorState() 
              : _isVideoReady
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: VideoPlayer(_videoController!),
                    ),
                    if (allowUserVideoControl) _buildVideoControls(),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4D382D),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: const Color(0xFFDDC6A9),
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                ),
                Expanded(
                  child: VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFFDDC6A9),
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 48,
          ),
          const SizedBox(height: 8),
          const Text(
            'Video failed to load',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Please try again later',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _videoError = false;
                _isVideoReady = false;
              });
              _initializeVideo();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader2(Map<String, dynamic> exerciseData) {
    final header2 = exerciseData['header2'] as String?;
    
    if (header2 == null) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        header2,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4D382D),
          fontFamily: 'Roboto',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMicrophoneSection(Map<String, dynamic> exerciseData) {
    final showMicrophone = exerciseData['showMicrophone'] as bool? ?? false;
    final microphonePrompt = exerciseData['microphonePrompt'] as String? ?? '';
    
    if (!showMicrophone) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (microphonePrompt.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                microphonePrompt,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF4D382D),
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          GestureDetector(
            onLongPressStart: (_) => _onMicrophonePressStart(),
            onLongPressEnd: (_) => _onMicrophonePressEnd(),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isMicPressed 
                    ? const Color(0xFF4D382D) 
                    : const Color(0xFFDDC6A9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.mic,
                color: _isMicPressed ? Colors.white : const Color(0xFF4D382D),
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hold to speak',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(Map<String, dynamic> exerciseData) {
    final showContinueButton = exerciseData['showContinueButton'] as bool? ?? false;
    
    if (!showContinueButton) {
      return const SizedBox.shrink();
    }
    
    final isEnabled = _areRequirementsMet();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isEnabled ? _onContinuePressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4D382D),
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Continue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isEnabled ? Colors.white : Colors.grey[600],
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ),
    );
  }
}
