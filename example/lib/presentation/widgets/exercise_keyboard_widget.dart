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
                  ExerciseSubheader(
                    text: exerciseData['header2'] as String?,
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
      ),
    );
  }



  Widget _buildContinueButton(Map<String, dynamic> exerciseData) {
    final showContinueButton = exerciseData['showContinueButton'] as bool? ?? false;
    
    if (!showContinueButton) {
      return const SizedBox.shrink();
    }
    
    final isEnabled = areRequirementsMet();
    
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
  const ArabicForcedTypingDemo({super.key, required this.initialTarget, this.asSection = false});

  @override
  State<ArabicForcedTypingDemo> createState() => _ArabicForcedTypingDemoState();
}

class _ArabicForcedTypingDemoState extends State<ArabicForcedTypingDemo> {
  final _validator = InputValidator();
  late InputState _state;

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
  }

  void _backspace() {
    setState(() {
      _state = _validator.processBackspace(currentState: _state);
    });
  }

  @override
  Widget build(BuildContext context) {
    final expected = _state.expectedInput;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        // Target text with per-character feedback (green = correct, red = incorrect)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            textDirection: TextDirection.rtl,
            children: List.generate(expected.length, (i) {
              final stateAtI = _state.characterStates.firstWhere(
                (s) => s.index == i,
                orElse: () => CharacterState(index: i, character: '', status: CharacterStatus.pending),
              );
              Color border;
              if (stateAtI.status == CharacterStatus.correct) {
                border = Colors.green;
              } else if (stateAtI.status == CharacterStatus.incorrect) {
                border = Colors.red;
              } else {
                border = Colors.grey;
              }
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  expected[i],
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 20),
                ),
              );
            }),
          ),
        ),

        // Current input string (assembled)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _state.currentInput,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 22),
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
