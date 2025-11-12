import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../data/models/page_model.dart';
import '../../../main.dart'; // For AvatarProvider
import '../../../providers/lesson_progress_provider.dart';
import 'package:avatar_sts2/avatar_sts2.dart';

/// Abstract base widget class for exercise pages
abstract class BaseExercisePage extends StatefulWidget {
  final PageModel page;
  final VoidCallback? onContinue;

  const BaseExercisePage({
    super.key,
    required this.page,
    this.onContinue,
  });
}

/// Base state class containing common exercise functionality
abstract class BaseExerciseState<T extends BaseExercisePage> extends State<T> {
  // Video-related state
  VideoPlayerController? videoController;
  bool isVideoReady = false;
  bool videoWatched = false;
  bool videoError = false;
  
  // Avatar-related state
  TavusAvatar? avatar;
  bool isProcessingMessages = false;
  bool hasPlayedIntro = false;
  bool waitingForGreeting = false;
  bool greetingCompleted = false;
  
  // Microphone-related state
  bool isMicPressed = false;
  bool microphoneUsed = false;
  
  // Continue button state
  bool progressTriggered = false;
  
  // Message tracking
  String? currentMessageId;
  List<Map<String, dynamic>> validatedMessages = [];
  
  // Stream subscriptions for proper cleanup
  StreamSubscription<Map<String, dynamic>>? avatarEventSubscription;

  @override
  void initState() {
    super.initState();
    initializeVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupGreetingListener();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get avatar from AvatarProvider
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
    final newAvatar = avatarProvider.avatar;
    
    // Check if avatar instance has changed
    if (newAvatar != avatar) {
      print('🔄 Avatar instance changed: ${avatar?.hashCode} → ${newAvatar?.hashCode}');
      
      // Cancel old subscription if it exists
      avatarEventSubscription?.cancel();
      avatarEventSubscription = null;
      
      // Update avatar reference
      avatar = newAvatar;
      
      // Set up event listener for new avatar if available
      if (avatar != null) {
        setupAvatarEventListener();
        
        // Reset greeting state since we have a new avatar
        if (mounted) {
          setState(() {
            waitingForGreeting = false;
            greetingCompleted = false;
          });
          
          // Re-setup greeting listener for new avatar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setupGreetingListener();
          });
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if exercise data has changed
    if (oldWidget.page.exerciseData != widget.page.exerciseData) {
      print('📝 Exercise data changed, resetting widget state');
      resetExerciseState();
    }
  }

  @override
  void dispose() {
    print('🧹 Disposing BaseExerciseState - cleaning up resources');
    cleanupResources();
    super.dispose();
  }

  /// Reset all exercise state when data changes
  void resetExerciseState() {
    // Cancel any pending operations
    avatarEventSubscription?.cancel();
    avatarEventSubscription = null;
    
    // Dispose old video controller
    videoController?.dispose();
    videoController = null;
    
    // Reset all state flags
    isVideoReady = false;
    videoWatched = false;
    microphoneUsed = false;
    isProcessingMessages = false;
    hasPlayedIntro = false;
    videoError = false;
    waitingForGreeting = false;
    greetingCompleted = false;
    currentMessageId = null;
    validatedMessages = [];
    progressTriggered = false;
    isMicPressed = false;
    
    // Reinitialize with new data
    initializeVideo();
    
    // Re-setup avatar listener and greeting detection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupAvatarEventListener();
      setupGreetingListener();
    });
    
    setState(() {});
  }

  /// Clean up all resources
  void cleanupResources() {
    // Cancel avatar event subscription
    avatarEventSubscription?.cancel();
    avatarEventSubscription = null;
    
    // Clear avatar reference
    avatar = null;
    
    // Dispose video controller
    videoController?.dispose();
    
    // If still processing messages, mark as aborted
    if (isProcessingMessages) {
      print('⚠️ Widget disposed while processing messages - marking as aborted');
      isProcessingMessages = false;
    }
  }

  /// Initialize video controller
  void initializeVideo() {
    final exerciseData = widget.page.exerciseData ?? {};
    final videoName = exerciseData['videoName'] as String?;
    
    if (videoName != null) {
      print("Initializing video: assets/videos/$videoName");
      videoController = VideoPlayerController.asset('assets/videos/$videoName');
      videoController!.initialize().then((_) {
        print("Video initialized successfully: $videoName");
        if (!mounted) return; // Guard against disposed widget
        setState(() {
          isVideoReady = true;
        });
        
        // Listen for video completion
        videoController!.addListener(videoListener);
      }).catchError((error) {
        print("Error initializing video $videoName: $error");
        if (!mounted) return; // Guard against disposed widget
        setState(() {
          isVideoReady = false;
          videoError = true;
          videoController?.dispose();
          videoController = null;
        });
      });
    }
  }

  /// Video completion listener
  void videoListener() {
    if (!mounted) return; // Guard against disposed widget
    
    if (videoController != null && 
        videoController!.value.position >= videoController!.value.duration) {
      if (!videoWatched) {
        setState(() {
          videoWatched = true;
        });
        
        // Only trigger afterVideo messages here if not already handled in sequence
        if (!isProcessingMessages) {
          print('🎬 Video completed outside of sequence - triggering afterVideo messages');
          triggerAfterVideoMessages();
        } else {
          print('🎬 Video completed during sequence - afterVideo handling delegated to sequence processor');
        }
      }
    }
  }

  /// Set up event listener for avatar events
  void setupAvatarEventListener() {
    if (avatar == null) return;
    
    avatarEventSubscription?.cancel();
    avatarEventSubscription = avatar!.eventStream.listen((event) {
      final eventType = event['type'] as String?;
      print('🎤 Avatar event: $eventType');
      
      if (eventType == 'avatar_speech_ended') {
        if (waitingForGreeting && !greetingCompleted) {
          print('✅ Greeting completed, starting lesson sequence');
          setState(() {
            greetingCompleted = true;
            waitingForGreeting = false;
          });
          runAutoSequence();
        }
      } else if (eventType == 'avatar_speech_started') {
        if (currentMessageId != null) {
          print('🗣️ Avatar started speaking message: $currentMessageId');
        }
      }
    });
  }

  /// Set up listener to wait for avatar greeting to complete
  void setupGreetingListener() {
    if (avatar == null || !avatar!.isConnected) {
      // No avatar or not connected, start sequence immediately
      runAutoSequence();
      return;
    }
    
    print('⏳ Waiting for avatar greeting to complete...');
    setState(() {
      waitingForGreeting = true;
    });
    
    // Setup timeout fallback - start sequence anyway if no speech event received
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return; // Guard against disposed widget
      if (waitingForGreeting && !greetingCompleted) {
        print('⚠️ Greeting timeout, starting sequence anyway');
        setState(() {
          waitingForGreeting = false;
          greetingCompleted = true;
        });
        runAutoSequence();
      }
    });
  }

  /// Main sequencing method - processes sendMessages from exercise data
  Future<void> runAutoSequence() async {
    if (isProcessingMessages || hasPlayedIntro) {
      print('⏭️ Skipping auto sequence: processing=$isProcessingMessages, played=$hasPlayedIntro');
      return;
    }
    
    print('🚀 Starting auto sequence...');
    setState(() {
      isProcessingMessages = true;
    });

    try {
      final exerciseData = widget.page.exerciseData ?? {};
      final sendMessages = exerciseData['sendMessages'] as List<dynamic>? ?? [];
      
      // Validate and prepare messages with enhanced logging
      validatedMessages = validateAndPrepareMessages(sendMessages);

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
        if (videoTrigger.startsWith('afterAvatar') && validatedMessages.isNotEmpty) {
          // Find the appropriate avatar message to follow
          final avatarMessages = validatedMessages.where((m) => m['type'] == 'avatarMessage').toList();
          if (avatarMessages.isNotEmpty) {
            videoMessage['afterId'] = avatarMessages.first['id'];
            print('🔗 Linking video to avatar message: ${avatarMessages.first['id']}');
          }
        }
        
        validatedMessages.add(videoMessage);
      }

      // Process onStart messages first
      final onStartMessages = validatedMessages.where((msg) => msg['trigger'] == 'onStart').toList();
      print('▶️ Processing ${onStartMessages.length} onStart messages');
      
      for (final message in onStartMessages) {
        if (!mounted || !isProcessingMessages) {
          print('⚠️ Sequence aborted - widget disposed or stopped');
          break;
        }
        await processMessage(message, validatedMessages);
      }

      print('✅ Auto sequence completed successfully');
    } catch (e, stackTrace) {
      print('❌ Error in auto sequence: $e');
      print('Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          isProcessingMessages = false;
          hasPlayedIntro = true;
        });
      }
    }
  }

  /// Validate and prepare messages for processing
  List<Map<String, dynamic>> validateAndPrepareMessages(List<dynamic> sendMessages) {
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
    validateTriggerReferences(messages);
    
    print('✅ Validated ${messages.length} messages (${sendMessages.length - messages.length} filtered out)');
    return messages;
  }

  /// Validate that trigger references point to existing messages
  void validateTriggerReferences(List<Map<String, dynamic>> messages) {
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

  /// Process a single message and its chained messages
  Future<void> processMessage(Map<String, dynamic> message, List<Map<String, dynamic>> allMessages) async {
    final type = message['type'] as String;
    final content = message['content'] as String? ?? '';
    final messageId = message['id'] as String;
    
    print('🎯 Processing message: $messageId (type: $type)');
    currentMessageId = messageId;

    try {
      if (type == 'avatarMessage' && avatar != null) {
        // Validate content before sending
        final trimmedContent = content.trim();
        if (trimmedContent.isEmpty) {
          print('⚠️ Skipping avatar message with empty content: $messageId');
          return;
        }
        
        print('🗣️ Sending avatar message: "${trimmedContent.length > 50 ? trimmedContent.substring(0, 50) + '...' : trimmedContent}"');
        
        // Send avatar message and wait for speech end
        await avatar!.sendMessageAndWait(trimmedContent, timeout: const Duration(seconds: 15));
        print('✅ Avatar message completed: $messageId');
        
      } else if (type == 'video' && videoController != null) {
        print('📹 Playing video: $content');
        
        // Play video and wait for completion
        await playVideoAndWait();
        print('✅ Video completed: $messageId');
      } else {
        print('⚠️ Unsupported message type or missing resources: $type');
      }

      // After finishing this message, look for chained messages
      await processChainedMessages(messageId, allMessages);
      
      // Special handling for video completion: check for afterVideo triggers
      if (type == 'video') {
        final exerciseData = widget.page.exerciseData ?? {};
        final videoName = exerciseData['videoName'] as String?;
        if (videoName != null) {
          print('🔗 Processing afterVideo chains for: video_$videoName');
          // Process messages that are waiting for this specific video to complete
          await processChainedMessages('video_$videoName', allMessages);
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error processing message $messageId: $e');
      print('Stack trace: $stackTrace');
    } finally {
      currentMessageId = null;
    }
  }

  /// Play video and wait for it to complete
  Future<void> playVideoAndWait() async {
    if (videoController == null || !isVideoReady) {
      print('⚠️ Cannot play video: controller=${videoController != null}, ready=$isVideoReady');
      return;
    }

    print('▶️ Starting video playback...');
    final completer = Completer<void>();
    
    // Listen for video completion using video player's position
    late VoidCallback listener;
    listener = () {
      if (!mounted) return; // Guard against disposed widget
      
      if (videoController!.value.position >= videoController!.value.duration) {
        videoController!.removeListener(listener);
        setState(() {
          videoWatched = true;
        });
        print('🎬 Video playback completed');
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    };
    
    videoController!.addListener(listener);
    videoController!.play();
    
    // Wait for completion or timeout
    try {
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ Video playback timed out after 30 seconds');
          videoController!.removeListener(listener);
          throw TimeoutException('Video playback timeout', const Duration(seconds: 30));
        },
      );
    } catch (e) {
      videoController!.removeListener(listener);
      print('❌ Video playback error: $e');
      rethrow;
    }
  }

  /// Process messages that should play after the given messageId
  Future<void> processChainedMessages(String messageId, List<Map<String, dynamic>> allMessages) async {
    final chainedMessages = allMessages.where((msg) {
      final trigger = msg['trigger'] as String?;
      final afterId = msg['afterId'] as String?;
      return (trigger == 'afterMessage' || trigger == 'afterVideo') && afterId == messageId;
    }).toList();

    if (chainedMessages.isNotEmpty) {
      print('🔗 Found ${chainedMessages.length} chained messages for: $messageId');
      for (final chainedMessage in chainedMessages) {
        if (!mounted || !isProcessingMessages) {
          print('⚠️ Chained message processing aborted - widget disposed or stopped');
          break;
        }
        await processMessage(chainedMessage, allMessages);
      }
    } else {
      print('📝 No chained messages found for: $messageId');
    }
  }

  /// Trigger messages that should play after video completion
  Future<void> triggerAfterVideoMessages() async {
    final exerciseData = widget.page.exerciseData ?? {};
    final sendMessages = exerciseData['sendMessages'] as List<dynamic>? ?? [];
    final videoName = exerciseData['videoName'] as String?;
    
    if (videoName == null) return;
    
    // Validate and prepare messages
    final messages = validateAndPrepareMessages(sendMessages);
    
    // Find messages that should trigger after this video
    final afterVideoMessages = messages.where((msg) {
      final trigger = msg['trigger'] as String?;
      final afterId = msg['afterId'] as String?;
      return trigger == 'afterVideo' && afterId == 'video_$videoName';
    }).toList();
    
    print('🎬 Video "$videoName" completed. Found ${afterVideoMessages.length} afterVideo messages to process');
    
    // Process each afterVideo message
    for (final message in afterVideoMessages) {
      await processMessage(message, messages);
    }
  }

  /// Handle microphone press start
  Future<void> onMicrophonePressStart() async {
    if (avatar == null) return;
    final exerciseData = widget.page.exerciseData ?? {};
    final word = (exerciseData['microphonePrompt'] as String? ?? '').trim();
    
    // Debug: verify CRUD plumbing
    print('[BaseExercise] microphonePrompt="$word"');
    
    if (!mounted) return; // Guard against disposed widget
    setState(() {
      isMicPressed = true;
    });

    if (word.isEmpty) {
      // Fallback: just open mic (no special context)
      await avatar!.setMicrophoneEnabled(true);
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
      await avatar!.publishSystemPromptAndWait(prompt,
          timeout: const Duration(milliseconds: 600));
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 600));
    }
    await avatar!.setMicrophoneEnabled(true);
  }

  /// Handle microphone press end
  Future<void> onMicrophonePressEnd() async {
    if (!mounted) return; // Guard against disposed widget
    setState(() {
      isMicPressed = false;
      microphoneUsed = true;
    });

    if (avatar != null) {
      await avatar!.setMicrophoneEnabled(false);
      
      // Optional: Wait for avatar feedback to complete
      // This ensures user sees/hears the complete pronunciation feedback
      try {
        await avatar!.eventStream
            .where((event) => event['type'] == 'avatar_speech_ended')
            .first
            .timeout(const Duration(seconds: 10)); // Timeout after 10s
      } catch (e) {
        // If no feedback comes, that's fine - continue normally
        print('No avatar feedback received or timeout: $e');
      }
    }
  }

  /// Check if all requirements are met for continue button
  bool areRequirementsMet() {
    final exerciseData = widget.page.exerciseData ?? {};
    final showMicrophone = exerciseData['showMicrophone'] as bool? ?? false;
    final videoName = exerciseData['videoName'] as String?;
    
    bool videoRequirementMet = videoName == null || videoWatched;
    bool micRequirementMet = !showMicrophone || microphoneUsed;
    bool sequenceCompleted = !isProcessingMessages; // New requirement
    
    return videoRequirementMet && micRequirementMet && sequenceCompleted;
  }

  /// Handle continue button press with two-phase logic
  void onContinuePressed() {
    // Only proceed if the continue button is enabled (areRequirementsMet() is true).
    // First click: trigger progress bar update
    if (!progressTriggered) {
      progressTriggered = true;
      // Notify LessonProgressProvider to increment progress
      Provider.of<LessonProgressProvider>(context, listen: false).incrementCompleted();
      print('🎯 BaseExercise: First continue click - progress updated');
      
      // Provide visual feedback that something happened
      setState(() {}); // This will trigger a rebuild and potentially update UI state
      
      return; 
    }
    
    // Second click: actually continue to next page
    print('🎯 BaseExercise: Second continue click - navigating to next page');
    if (widget.onContinue != null) {
      widget.onContinue!();  // this calls LessonPage._goToNextPage()
    } else {
      // Fallback behavior if no callback (not expected in our case)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proceeding to next page...'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  /// Restart intro if needed (called from LessonPage on navigation)
  void restartIntroIfNeeded() {
    if (!mounted) return; // Guard against disposed widget
    if (!isProcessingMessages && hasPlayedIntro && avatar != null) {
      print('🔄 Restarting intro sequence...');
      
      // Reset all state flags for fresh restart
      setState(() {
        hasPlayedIntro = false;
        videoWatched = false;
        microphoneUsed = false;
        isProcessingMessages = false;
        waitingForGreeting = false;
        greetingCompleted = false;
        currentMessageId = null;
        validatedMessages = [];
        progressTriggered = false;
      });
      
      // Restart video if it exists
      if (videoController != null) {
        videoController!.seekTo(Duration.zero);
      }
      
      // Restart the greeting detection and sequence
      setupGreetingListener();
    } else {
      print('⏭️ Skipping restart: processing=$isProcessingMessages, played=$hasPlayedIntro, avatar=${avatar != null}');
    }
  }

  /// Pause media when page is not visible
  void pauseMedia() {
    print('⏸️ Pausing media due to page navigation');
    
    // Pause video
    videoController?.pause();
    
    // Disable microphone if avatar is connected
    if (avatar != null && avatar!.isConnected) {
      avatar!.setMicrophoneEnabled(false);
    }
    
    // Mark processing as stopped if currently running
    if (isProcessingMessages) {
      print('⚠️ Stopping message processing due to page navigation');
      if (!mounted) return; // Guard against disposed widget
      setState(() {
        isProcessingMessages = false;
      });
    }
  }

  /// Abstract method for building the exercise-specific content
  Widget buildExerciseContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return buildExerciseContent(context);
  }
}
