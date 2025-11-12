import 'package:flutter/material.dart';
import 'exercise_widgets/exercise_intro_theme.dart';
import 'exercise_widgets/exercise_intro_strings.dart';
import 'exercise_widgets/exercise_header.dart';
import 'exercise_widgets/exercise_video_section.dart';
import 'exercise_widgets/primary_continue_button.dart';
import 'exercise_widgets/base_exercise_page.dart';
import 'exercise_widgets/arabic_keyboard_widget.dart';
import 'exercise_widgets/input_validator.dart';
import 'exercise_widgets/chat_message.dart';
import 'exercise_widgets/arabic_keyboard.dart';
import 'exercise_widgets/exercise_audio_button.dart';
import 'exercise_widgets/exercise_image_section.dart';

/// Widget for displaying Arabic typing exercise with video, headers, and interactive elements
class ExerciseKeyboardWidget extends BaseExercisePage {
  const ExerciseKeyboardWidget({
    super.key,
    required super.page,
    super.onContinue,
  });

  @override
  ExerciseKeyboardWidgetState createState() => ExerciseKeyboardWidgetState();
}

/// Public state class to allow external control via GlobalKey
class ExerciseKeyboardWidgetState extends BaseExerciseState<ExerciseKeyboardWidget> {
  bool _typingComplete = false;
  
  @override
  Widget buildExerciseContent(BuildContext context) {
    final exerciseData = widget.page.exerciseData ?? {};
    
    return Container(
      color: ExerciseIntroTheme.backgroundColor,
      child: Column(
        children: [
          // Scrollable content section
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ExerciseHeader(
                    title: exerciseData['header1'] as String?,
                    transliteration: exerciseData['transliteration'] as String?,
                  ),
                  _buildVideoSection(exerciseData),
                  // Header 2 row with optional audio button on the left (RTL-aware positioning handled via row order)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: ExerciseIntroTheme.paddingLarge),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Audio button pinned near the screen edge with standard margin
                        ExerciseAudioButton(
                          audioFileName: _extractAudioFileName(exerciseData),
                          size: 28,
                        ),
                        const SizedBox(width: ExerciseIntroTheme.gapLarge),
                        Expanded(
                          child: ExerciseSubheader(
                            text: exerciseData['header2'] as String?,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Optional image section (same sizing/positioning style as video)
                  if ((exerciseData['showImage'] as bool? ?? false) &&
                      ((exerciseData['imageFileName'] as String?)?.trim().isNotEmpty ?? false))
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: ExerciseImageSection(
                        imageFileName: (exerciseData['imageFileName'] as String).trim(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Fixed bottom section
          Column(
            children: [
              _buildMicrophoneSection(exerciseData),
              _buildContinueButton(exerciseData),
              const SizedBox(height: ExerciseIntroTheme.paddingLarge),
            ],
          ),
        ],
      ),
    );
  }

  String? _extractAudioFileName(Map<String, dynamic> exerciseData) {
    final raw = (exerciseData['audioFileName'] ?? exerciseData['audio'] ?? exerciseData['audio_file']) as String?;
    final name = raw?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  Widget _buildVideoSection(Map<String, dynamic> exerciseData) {
    final allowUserVideoControl = exerciseData['allowUserVideoControl'] as bool? ?? false;
    
    return ExerciseVideoSection(
      controller: videoController,
      isReady: isVideoReady,
      isError: videoError,
      isPlaying: videoController?.value.isPlaying ?? false,
      allowUserControl: allowUserVideoControl,
      onPlayPause: () {
        if (videoController?.value.isPlaying ?? false) {
          videoController?.pause();
        } else {
          videoController?.play();
        }
      },
      onRetry: () {
        setState(() {
          videoError = false;
          isVideoReady = false;
        });
        initializeVideo();
      },
    );
  }

  Widget _buildMicrophoneSection(Map<String, dynamic> exerciseData) {
  // Always show the Arabic forced typing demo instead of the microphone.
    final String initialTarget = (exerciseData['typingTarget'] as String?)
            ?? (exerciseData['header1'] as String?)
            ?? 'مرحبا كيف حالك؟';

    // Replace the microphone area with the Arabic forced typing demo as an inline section.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: ArabicForcedTypingDemo(
        initialTarget: initialTarget,
        asSection: true,
        onCompletionChanged: (complete) {
          // Safe to set since fired from user actions or post-frame
          if (mounted) setState(() => _typingComplete = complete);
        },
      ),
    );
  }



  Widget _buildContinueButton(Map<String, dynamic> exerciseData) {
    final showContinueButton = exerciseData['showContinueButton'] as bool? ?? false;
    
    if (!showContinueButton) {
      return const SizedBox.shrink();
    }
    
  // Enable only when typing of target text is complete
  final isEnabled = _typingComplete;
    
    // Different button text based on progress state
    String buttonText = ExerciseIntroStrings.continueText;
    if (isEnabled && progressTriggered) {
      buttonText = ExerciseIntroStrings.continueArrowText;
    }
    
    return PrimaryContinueButton(
      text: buttonText,
      enabled: isEnabled,
      onPressed: onContinuePressed,
    );
  }
}

class ArabicForcedTypingDemo extends StatefulWidget {
  final String initialTarget;
  final bool asSection; // when true, render inline (no Scaffold/AppBar)
  final ValueChanged<bool>? onCompletionChanged;
  const ArabicForcedTypingDemo({
    super.key,
    required this.initialTarget,
    this.asSection = false,
    this.onCompletionChanged,
  });

  @override
  State<ArabicForcedTypingDemo> createState() => _ArabicForcedTypingDemoState();
}

class _ArabicForcedTypingDemoState extends State<ArabicForcedTypingDemo> {
  final _validator = InputValidator();
  late InputState _state;
  bool _lastComplete = false;

  @override
  void initState() {
    super.initState();
    _setTarget(widget.initialTarget);
  }

  void _setTarget(String text) {
    setState(() {
      _state = InputState(
        expectedInput: text,
        currentInput: '',
        characterStates: [],
        isComplete: false,
        cursorPosition: 0,
      );
    });
  _notifyCompletion(false);
  }

  void _typeChar(String ch) {
    final pos = _validator.getNextInputPosition(_state);
    setState(() {
      _state = _validator.processCharacterInput(
        currentState: _state,
        inputCharacter: ch,
        position: pos,
      );
    });
  _notifyCompletion(_state.isComplete);
  }

  void _backspace() {
    setState(() {
      _state = _validator.processBackspace(currentState: _state);
    });
    _notifyCompletion(_state.isComplete);
  }

  void _notifyCompletion(bool complete) {
    if (widget.onCompletionChanged == null) return;
    if (complete == _lastComplete) return;
    _lastComplete = complete;
    // Use post-frame to avoid setState during build issues in parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCompletionChanged!(complete);
    });
  }

  @override
  Widget build(BuildContext context) {
    final expected = _state.expectedInput;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        // Single input box that shows the target as gray placeholders; per-character coloring
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: RichText(
                text: TextSpan(
                  children: List.generate(expected.length, (i) {
                    final expectedChar = expected[i];
                    // find state for this index
                    final stateAtI = _state.characterStates.firstWhere(
                      (s) => s.index == i,
                      orElse: () => CharacterState(index: i, character: '', status: CharacterStatus.pending),
                    );

                    // default: gray placeholder
                    Color color = Colors.grey.shade500;
                    FontWeight weight = FontWeight.normal;

                    if (stateAtI.status == CharacterStatus.correct) {
                      // Correct => turn black
                      color = Colors.black;
                    } else if (stateAtI.status == CharacterStatus.incorrect) {
                      // If expected is a haraka and typed char is NOT a haraka => likely forgotten haraka
                      if (ArabicKeyboard.isHaraka(expectedChar) &&
                          !ArabicKeyboard.harakat.contains(stateAtI.character)) {
                        color = Colors.orange.shade700;
                      } else {
                        color = Colors.red.shade700;
                      }
                      weight = FontWeight.w600;
                    } else {
                      // Pending: if next expected is a haraka, hint with orange
                      if (ArabicKeyboard.isHaraka(expectedChar)) {
                        color = Colors.orange.shade600;
                      }
                    }

                    // Show expected char but color according to correctness
                    return TextSpan(
                      text: expectedChar,
                      style: TextStyle(fontSize: 22, color: color, fontWeight: weight),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),

        if (_state.isComplete)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Complete!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),

        const SizedBox(height: 8),

        // The Arabic keyboard
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ArabicKeyboardWidget(
            enabled: true,
            currentInputState: _state,
            highlightNextKey: true,
            onKeyPressed: _typeChar,
            onBackspace: _backspace,
            onSpace: () => _typeChar(' '),
            onEnter: () {
              if (_state.isComplete) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Great job!')),
                );
              }
            },
          ),
        ),
      ],
    );

    if (widget.asSection) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arabic Forced Typing'),
        actions: [
          IconButton(
            tooltip: 'Load new target',
            onPressed: () => _setTarget('مرحبا كيف حالك؟'),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: content,
    );
  }
}
