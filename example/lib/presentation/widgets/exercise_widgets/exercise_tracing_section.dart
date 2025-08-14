import 'package:flutter/material.dart';
import 'package:tracing_game/tracing_game.dart';

/// Widget for managing tracing game display
class ExerciseTracingSection extends StatefulWidget {
  final String letter;
  final ValueChanged<bool> onTraceComplete; // Callback to notify when tracing is completed

  const ExerciseTracingSection({
    super.key,
    required this.letter,
    required this.onTraceComplete,
  });

  @override
  ExerciseTracingSectionState createState() => ExerciseTracingSectionState();
}

class ExerciseTracingSectionState extends State<ExerciseTracingSection> {
  bool _traceCompleted = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(ExerciseTracingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset if the letter changed
    if (oldWidget.letter != widget.letter) {
      setState(() {
        _traceCompleted = false;
      });
    }
  }

  Future<void> _onGameFinished(int screenIndex) async {
    if (!_traceCompleted) {
      setState(() {
        _traceCompleted = true;
      });
      widget.onTraceComplete(true);
    }
  }

  Future<void> _onCurrentTracingScreenFinished(int currentScreenIndex) async {
    // Called when current screen is finished, but we only care about full completion
    // print('Current tracing screen finished: $currentScreenIndex');
  }

  Future<void> _onTracingUpdated(int currentTracingIndex) async {
    // Called during tracing progress
    // print('Tracing updated: $currentTracingIndex');
  }

  @override
  Widget build(BuildContext context) {
    // Check if letter is empty or invalid
    if (widget.letter.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, color: Colors.orange.shade600, size: 32),
              const SizedBox(height: 8),
              Text(
                'No Letter Selected',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Please select a letter to trace using the CRUD menu.',
                style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Build the tracing game widget
    return Container(
      height: 300, // Fixed height to maintain consistent layout
      margin: const EdgeInsets.all(16),
      child: TracingCharsGame(
        showAnchor: true,
        traceShapeModel: [
          TraceCharsModel(
            chars: [
              TraceCharModel(
                char: widget.letter,
                traceShapeOptions: const TraceShapeOptions(
                  innerPaintColor: Colors.orange,
                ),
              ),
            ],
          ),
        ],
        onTracingUpdated: _onTracingUpdated,
        onGameFinished: _onGameFinished,
        onCurrentTracingScreenFinished: _onCurrentTracingScreenFinished,
      ),
    );
  }
}
