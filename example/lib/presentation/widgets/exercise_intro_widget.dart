import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import '../../data/models/page_model.dart';
import 'package:avatar_sts2/avatar_sts2.dart';

/// Widget for displaying exercise introduction with video, headers, and interactive elements
class ExerciseIntroWidget extends StatefulWidget {
  final PageModel page;

  const ExerciseIntroWidget({
    super.key,
    required this.page,
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
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideo() {
    final exerciseData = widget.page.exerciseData ?? {};
    final videoName = exerciseData['videoName'] as String?;
    
    if (videoName != null) {
      _videoController = VideoPlayerController.asset('assets/videos/$videoName');
      _videoController!.initialize().then((_) {
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
        await _avatar!.sendTextMessage(content);
        // Wait for estimated speaking time (0.5 seconds per word)
        final wordCount = content.split(' ').length;
        final speakingDelay = Duration(seconds: (wordCount * 0.5).round());
        await Future.delayed(speakingDelay);
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

  void _onMicrophonePressEnd() {
    setState(() {
      _isMicPressed = false;
      _microphoneUsed = true;
    });

    if (_avatar != null) {
      _avatar!.setMicrophoneEnabled(false);
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
    // Mark exercise complete and navigate to next page
    // This should be handled by parent widget/provider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exercise completed!'),
        backgroundColor: Color(0xFF4D382D),
      ),
    );
    
    // TODO: Update progress and navigate to next page
    // This would typically be handled by a provider or callback to parent
  }

  @override
  Widget build(BuildContext context) {
    final exerciseData = widget.page.exerciseData ?? {};
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2EFEB),
      appBar: _buildAppBar(exerciseData),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      children: [
                        _buildHeaderRow(exerciseData),
                        _buildVideoSection(exerciseData),
                        _buildHeader2(exerciseData),
                        const Spacer(),
                        _buildMicrophoneSection(exerciseData),
                        _buildContinueButton(exerciseData),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, dynamic> exerciseData) {
    final showRightArrow = exerciseData['showRightArrow'] as bool? ?? false;
    
    return AppBar(
      backgroundColor: const Color(0xFFF2EFEB),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Color(0xFF4D382D),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: showRightArrow
          ? [
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF4D382D),
                ),
                onPressed: _onContinuePressed,
              ),
            ]
          : null,
    );
  }

  Widget _buildProgressBar() {
    // TODO: Get actual progress from provider
    const double progress = 0.3; // Placeholder
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey[300],
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4D382D)),
        minHeight: 4,
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
          child: _isVideoReady
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
