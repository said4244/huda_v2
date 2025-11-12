import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../data/models/page_model.dart';
import '../../main.dart'; // For AvatarProvider
import '../../providers/lesson_progress_provider.dart';
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
  ExerciseIntroWidgetState createState() => ExerciseIntroWidgetState();
}

/// Public state class to allow external control via GlobalKey
class ExerciseIntroWidgetState extends State<ExerciseIntroWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoReady = false;
  bool _videoWatched = false;
  bool _microphoneUsed = false;
  bool _isProcessingMessages = false;
  bool _hasPlayedIntro = false;
  bool _videoError = false;
  bool _waitingForGreeting = false;
  bool _greetingCompleted = false;
  TavusAvatar? _avatar;
  
  // UI state
  bool _isMicPressed = false;
  
  // Progress tracking for double-click continue logic
  bool _progressTriggered = false;
  
  // Message tracking for debugging
  String? _currentMessageId;
  List<Map<String, dynamic>> _validatedMessages = [];
  
  // Stream subscriptions for proper cleanup
  StreamSubscription<Map<String, dynamic>>? _avatarEventSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeVideo();
    // Don't run auto sequence immediately - wait for greeting to complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupGreetingListener();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get avatar from AvatarProvider
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
    _avatar = avatarProvider.avatar;
    
    // Set up event listener if avatar is available
    if (_avatar != null && _avatarEventSubscription == null) {
      _setupAvatarEventListener();
    }
  }

  /// Set up event listener for avatar events
  void _setupAvatarEventListener() {
    if (_avatar == null) return;
    
    _avatarEventSubscription?.cancel();
    _avatarEventSubscription = _avatar!.eventStream.listen((event) {
      final eventType = event['type'] as String?;
      print('🎤 Avatar event: $eventType');
      
      if (eventType == 'avatar_speech_ended') {
        if (_waitingForGreeting && !_greetingCompleted) {
          print('✅ Greeting completed, starting lesson sequence');
          setState(() {
            _greetingCompleted = true;
            _waitingForGreeting = false;
          });
          _runAutoSequence();
        }
      } else if (eventType == 'avatar_speech_started') {
        if (_currentMessageId != null) {
          print('🗣️ Avatar started speaking message: $_currentMessageId');
        }
      }
    });
  }

  /// Set up listener to wait for avatar greeting to complete
  void _setupGreetingListener() {
    if (_avatar == null || !_avatar!.isConnected) {
      // No avatar or not connected, start sequence immediately
      _runAutoSequence();
      return;
    }
    
    // Check if we should wait for greeting
    // For now, we'll wait 2 seconds after connection to allow greeting
    print('⏳ Waiting for avatar greeting to complete...');
    setState(() {
      _waitingForGreeting = true;
    });
    
    // Setup timeout fallback - start sequence anyway if no speech event received
    Timer(const Duration(seconds: 3), () {
      if (_waitingForGreeting && !_greetingCompleted) {
        print('⚠️ Greeting timeout, starting sequence anyway');
        setState(() {
          _waitingForGreeting = false;
          _greetingCompleted = true;
        });
        _runAutoSequence();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ExerciseIntroWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if exercise data has changed
    if (oldWidget.page.exerciseData != widget.page.exerciseData) {
      print('📝 Exercise data changed, resetting widget state');
      
      // Cancel any pending operations
      _avatarEventSubscription?.cancel();
      _avatarEventSubscription = null;
      
      // Dispose old video controller
      _videoController?.dispose();
      _videoController = null;
      
      // Reset all state flags
      _isVideoReady = false;
      _videoWatched = false;
      _microphoneUsed = false;
      _isProcessingMessages = false;
      _hasPlayedIntro = false;
      _videoError = false;
      _waitingForGreeting = false;
      _greetingCompleted = false;
      _currentMessageId = null;
      _validatedMessages = [];
      
      // Reinitialize with new data
      _initializeVideo();
      
      // Re-setup avatar listener and greeting detection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupAvatarEventListener();
        _setupGreetingListener();
      });
      
      setState(() {});
    }
  }

  @override
  void dispose() {
    print('🧹 Disposing ExerciseIntroWidget - cleaning up resources');
    
    // Cancel avatar event subscription
    _avatarEventSubscription?.cancel();
    
    // Dispose video controller
    _videoController?.dispose();
    
    // If still processing messages, mark as aborted
    if (_isProcessingMessages) {
      print('⚠️ Widget disposed while processing messages - marking as aborted');
      _isProcessingMessages = false;
    }
    
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
      }).catchError((error) {
        print("Error initializing video $videoName: $error");
        setState(() {
          _isVideoReady = false;
          _videoError = true;
          _videoController?.dispose();
          _videoController = null;
        });
      });
    }
  }

  void _videoListener() {
    if (_videoController != null && 
        _videoController!.value.position >= _videoController!.value.duration) {
      if (!_videoWatched) {
        setState(() {
          _videoWatched = true;
        });
        
        // Only trigger afterVideo messages here if not already handled in sequence
        if (!_isProcessingMessages) {
          print('🎬 Video completed outside of sequence - triggering afterVideo messages');
          _triggerAfterVideoMessages();
        } else {
          print('🎬 Video completed during sequence - afterVideo handling delegated to sequence processor');
        }
      }
    }
  }

  /// Validate and prepare messages for processing
  List<Map<String, dynamic>> _validateAndPrepareMessages(List<dynamic> sendMessages) {
    final messages = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    
    print('🔍 Validating ${sendMessages.length} messages...');
    
    for (int i = 0; i < sendMessages.length; i++) {
      final msg = Map<String, dynamic>.from(sendMessages[i]);
      
      // Generate stable ID if missing
      if (msg['id'] == null || (msg['id'] as String).isEmpty) {
        // Use content hash for stable ID generation
        final content = msg['content'] as String? ?? '';
        final type = msg['type'] as String? ?? 'unknown';
        msg['id'] = 'msg_${type}_${content.hashCode.abs()}_$i';
        print('🏷️ Generated ID for message $i: ${msg['id']}');
      }
      
      // Check for duplicate IDs
      final messageId = msg['id'] as String;
      if (seenIds.contains(messageId)) {
        print('⚠️ Duplicate message ID detected: $messageId - skipping duplicate');
        continue;
      }
      seenIds.add(messageId);
      
      // Set default trigger if missing
      if (msg['trigger'] == null) {
        msg['trigger'] = 'onStart';
      }
      
      // Set default type if missing
      if (msg['type'] == null) {
        msg['type'] = 'avatarMessage';
      }
      
      // Validate content for avatar messages
      if (msg['type'] == 'avatarMessage') {
        final content = (msg['content'] as String? ?? '').trim();
        if (content.isEmpty) {
          print('❌ Skipping avatar message with empty content: $messageId');
          continue;
        }
        if (content.length > 500) {
          print('⚠️ Avatar message is very long (${content.length} chars): $messageId');
        }
      }
      
      messages.add(msg);
    }
    
    // Validate trigger references
    _validateTriggerReferences(messages);
    
    print('✅ Validated ${messages.length} messages (${sendMessages.length - messages.length} filtered out)');
    return messages;
  }

  /// Validate that trigger references point to existing messages
  void _validateTriggerReferences(List<Map<String, dynamic>> messages) {
    final messageIds = messages.map((m) => m['id'] as String).toSet();
    
    for (final message in messages) {
      final trigger = message['trigger'] as String?;
      final afterId = message['afterId'] as String?;
      
      if ((trigger == 'afterMessage' || trigger == 'afterVideo') && afterId != null) {
        // Check if afterId exists in message list or is a valid video reference
        if (!messageIds.contains(afterId) && !afterId.startsWith('video_')) {
          print('⚠️ Broken trigger reference in ${message['id']}: afterId "$afterId" not found');
        }
      }
    }
  }

  /// Trigger messages that should play after video completion
  Future<void> _triggerAfterVideoMessages() async {
    final exerciseData = widget.page.exerciseData ?? {};
    final sendMessages = exerciseData['sendMessages'] as List<dynamic>? ?? [];
    final videoName = exerciseData['videoName'] as String?;
    
    if (videoName == null) return;
    
    // Validate and prepare messages
    final messages = _validateAndPrepareMessages(sendMessages);
    
    // Find messages that should trigger after this video
    final afterVideoMessages = messages.where((msg) {
      final trigger = msg['trigger'] as String?;
      final afterId = msg['afterId'] as String?;
      return trigger == 'afterVideo' && afterId == 'video_$videoName';
    }).toList();
    
    print('🎬 Video "$videoName" completed. Found ${afterVideoMessages.length} afterVideo messages to process');
    
    // Process each afterVideo message
    for (final message in afterVideoMessages) {
      await _processMessage(message, messages);
    }
  }

  /// Main sequencing method - replaces _processInitialTriggers and _processSendMessages
  Future<void> _runAutoSequence() async {
    if (_isProcessingMessages || _hasPlayedIntro) {
      print('⏭️ Skipping auto sequence: processing=$_isProcessingMessages, played=$_hasPlayedIntro');
      return;
    }
    
    print('🚀 Starting auto sequence...');
    setState(() {
      _isProcessingMessages = true;
    });

    try {
      final exerciseData = widget.page.exerciseData ?? {};
      final sendMessages = exerciseData['sendMessages'] as List<dynamic>? ?? [];
      
      // Validate and prepare messages with enhanced logging
      _validatedMessages = _validateAndPrepareMessages(sendMessages);

      // Add legacy video as message if videoTrigger is set (backward compatibility)
      final videoName = exerciseData['videoName'] as String?;
      final videoTrigger = exerciseData['videoTrigger'] as String? ?? 'onStart';
      final autoPlay = exerciseData['autoPlay'] as bool? ?? false;
      
      if (videoName != null && autoPlay) {
        print('📹 Adding legacy video message: $videoName (trigger: $videoTrigger)');
        final videoMessage = {
          'id': 'legacy_video_${DateTime.now().millisecondsSinceEpoch}',
          'type': 'video',
          'content': videoName,
          'trigger': videoTrigger == 'onStart' ? 'onStart' : 'afterMessage',
        };
        
        // If afterAvatarX, convert to afterMessage format
        if (videoTrigger.startsWith('afterAvatar') && _validatedMessages.isNotEmpty) {
          // Find the appropriate avatar message to follow
          final avatarMessages = _validatedMessages.where((m) => m['type'] == 'avatarMessage').toList();
          if (avatarMessages.isNotEmpty) {
            videoMessage['afterId'] = avatarMessages.first['id'];
            print('🔗 Linking video to avatar message: ${avatarMessages.first['id']}');
          }
        }
        
        _validatedMessages.add(videoMessage);
      }

      // Process onStart messages first
      final onStartMessages = _validatedMessages.where((msg) => msg['trigger'] == 'onStart').toList();
      print('▶️ Processing ${onStartMessages.length} onStart messages');
      
      for (final message in onStartMessages) {
        if (!mounted || !_isProcessingMessages) {
          print('⚠️ Sequence aborted - widget disposed or stopped');
          break;
        }
        await _processMessage(message, _validatedMessages);
      }

      print('✅ Auto sequence completed successfully');
    } catch (e, stackTrace) {
      print('❌ Error in auto sequence: $e');
      print('Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingMessages = false;
          _hasPlayedIntro = true;
        });
      }
    }
  }

  /// Process a single message and its chained messages
  Future<void> _processMessage(Map<String, dynamic> message, List<Map<String, dynamic>> allMessages) async {
    final type = message['type'] as String;
    final content = message['content'] as String? ?? '';
    final messageId = message['id'] as String;
    
    print('🎯 Processing message: $messageId (type: $type)');
    _currentMessageId = messageId;

    try {
      if (type == 'avatarMessage' && _avatar != null) {
        // Validate content before sending
        final trimmedContent = content.trim();
        if (trimmedContent.isEmpty) {
          print('⚠️ Skipping avatar message with empty content: $messageId');
          return;
        }
        
        print('🗣️ Sending avatar message: "${trimmedContent.length > 50 ? trimmedContent.substring(0, 50) + '...' : trimmedContent}"');
        
        // Send avatar message and wait for speech end
        await _avatar!.sendMessageAndWait(trimmedContent, timeout: const Duration(seconds: 15));
        print('✅ Avatar message completed: $messageId');
        
      } else if (type == 'video' && _videoController != null) {
        print('📹 Playing video: $content');
        
        // Play video and wait for completion
        await _playVideoAndWait();
        print('✅ Video completed: $messageId');
      } else {
        print('⚠️ Unsupported message type or missing resources: $type');
      }

      // After finishing this message, look for chained messages
      await _processChainedMessages(messageId, allMessages);
      
      // Special handling for video completion: check for afterVideo triggers
      if (type == 'video') {
        final exerciseData = widget.page.exerciseData ?? {};
        final videoName = exerciseData['videoName'] as String?;
        if (videoName != null) {
          print('🔗 Processing afterVideo chains for: video_$videoName');
          // Process messages that are waiting for this specific video to complete
          await _processChainedMessages('video_$videoName', allMessages);
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error processing message $messageId: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _currentMessageId = null;
    }
  }

  /// Play video and wait for it to complete
  Future<void> _playVideoAndWait() async {
    if (_videoController == null || !_isVideoReady) {
      print('⚠️ Cannot play video: controller=${_videoController != null}, ready=$_isVideoReady');
      return;
    }

    print('▶️ Starting video playback...');
    final completer = Completer<void>();
    
    // Listen for video completion using video player's position
    late VoidCallback listener;
    listener = () {
      if (_videoController!.value.position >= _videoController!.value.duration) {
        _videoController!.removeListener(listener);
        setState(() {
          _videoWatched = true;
        });
        print('🎬 Video playback completed');
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    };
    
    _videoController!.addListener(listener);
    _videoController!.play();
    
    // Wait for completion or timeout
    try {
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ Video playback timed out after 30 seconds');
          _videoController!.removeListener(listener);
          throw TimeoutException('Video playback timeout', const Duration(seconds: 30));
        },
      );
    } catch (e) {
      _videoController!.removeListener(listener);
      print('❌ Video playback error: $e');
      rethrow;
    }
  }

  /// Process messages that should play after the given messageId
  Future<void> _processChainedMessages(String messageId, List<Map<String, dynamic>> allMessages) async {
    final chainedMessages = allMessages.where((msg) {
      final trigger = msg['trigger'] as String?;
      final afterId = msg['afterId'] as String?;
      return (trigger == 'afterMessage' || trigger == 'afterVideo') && afterId == messageId;
    }).toList();

    if (chainedMessages.isNotEmpty) {
      print('🔗 Found ${chainedMessages.length} chained messages for: $messageId');
      for (final chainedMessage in chainedMessages) {
        if (!mounted || !_isProcessingMessages) {
          print('⚠️ Chained message processing aborted - widget disposed or stopped');
          break;
        }
        await _processMessage(chainedMessage, allMessages);
      }
    } else {
      print('📝 No chained messages found for: $messageId');
    }
  }

  /// Restart intro if needed (called from LessonPage on navigation)
  void restartIntroIfNeeded() {
    if (!_isProcessingMessages && _hasPlayedIntro && _avatar != null) {
      print('🔄 Restarting intro sequence...');
      
      // Reset all state flags for fresh restart
      setState(() {
        _hasPlayedIntro = false;
        _videoWatched = false;
        _microphoneUsed = false;
        _isProcessingMessages = false;
        _waitingForGreeting = false;
        _greetingCompleted = false;
        _currentMessageId = null;
        _validatedMessages = [];
      });
      
      // Restart video if it exists
      if (_videoController != null) {
        _videoController!.seekTo(Duration.zero);
      }
      
      // Restart the greeting detection and sequence
      _setupGreetingListener();
    } else {
      print('⏭️ Skipping restart: processing=$_isProcessingMessages, played=$_hasPlayedIntro, avatar=${_avatar != null}');
    }
  }

  /// Pause media when page is not visible
  void pauseMedia() {
    print('⏸️ Pausing media due to page navigation');
    
    // Pause video
    _videoController?.pause();
    
    // Disable microphone if avatar is connected
    if (_avatar != null && _avatar!.isConnected) {
      _avatar!.setMicrophoneEnabled(false);
    }
    
    // Mark processing as stopped if currently running
    if (_isProcessingMessages) {
      print('⚠️ Stopping message processing due to page navigation');
      setState(() {
        _isProcessingMessages = false;
      });
    }
  }

  Future<void> _onMicrophonePressStart() async {
    if (_avatar == null) return;
    final exerciseData = widget.page.exerciseData ?? {};
    final word = (exerciseData['microphonePrompt'] as String? ?? '').trim();
    
    // Debug: verify CRUD plumbing
    print('[ExerciseIntro] microphonePrompt="$word"');
    
    setState(() {
      _isMicPressed = true;
    });

    if (word.isEmpty) {
      // Fallback: just open mic (no special context)
      await _avatar!.setMicrophoneEnabled(true);
      return;
    }

    // Build the one-turn system prompt
    final prompt = <String, dynamic>{
      'type': 'system_prompt',
    };

    // If you prefix your CRUD value with RAW:, use it verbatim
    if (word.startsWith('RAW:')) {
      prompt['purpose'] = 'debug_override';
      prompt['content'] = word.substring(4);           // no wrapper
    } else {
      prompt['purpose'] = 'pronunciation';
      prompt['content'] =
          "The user will attempt to pronounce '$word'. Evaluate strictly but kindly in Syrian Arabic, "
          "point out exact articulation (makhraj), then re-model the correct pronunciation in one short line.";
    }

    // Send prompt and wait briefly (or for server ACK) to avoid race with audio
    try {
      await _avatar!.publishSystemPromptAndWait(prompt,
          timeout: const Duration(milliseconds: 600));
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 600));
    }
    await _avatar!.setMicrophoneEnabled(true);
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
    bool sequenceCompleted = !_isProcessingMessages; // New requirement
    
    return videoRequirementMet && micRequirementMet && sequenceCompleted;
  }

  void _onContinuePressed() {
    // Only proceed if the continue button is enabled (_areRequirementsMet() is true).
    // First click: trigger progress bar update
    if (!_progressTriggered) {
      _progressTriggered = true;
      // Notify LessonProgressProvider to increment progress
      Provider.of<LessonProgressProvider>(context, listen: false).incrementCompleted();
      print('🎯 ExerciseIntroWidget: First continue click - progress updated');
      
      // Provide visual feedback that something happened
      setState(() {}); // This will trigger a rebuild and potentially update UI state
      
      return; 
    }
    
    // Second click: actually continue to next page
    print('🎯 ExerciseIntroWidget: Second continue click - navigating to next page');
    if (widget.onContinue != null) {
      widget.onContinue!();  // this calls LessonPage._goToNextPage()
    } else {
      // Fallback behavior if no callback (not expected in our case)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proceeding to next page...'),
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
    
    // Different button text based on progress state
    String buttonText = 'Continue';
    if (isEnabled && _progressTriggered) {
      buttonText = 'Continue »';
    }
    
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
            buttonText,
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
