import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';

/// Small audio button that plays an asset from assets/audio when tapped.
/// Pass only the file name (e.g., "Ba.mp3"). If null/empty, renders nothing.
class ExerciseAudioButton extends StatefulWidget {
  final String? audioFileName;
  final double size;

  const ExerciseAudioButton({
    super.key,
    required this.audioFileName,
    this.size = 28,
  });

  @override
  State<ExerciseAudioButton> createState() => _ExerciseAudioButtonState();
}

class _ExerciseAudioButtonState extends State<ExerciseAudioButton> {
  late final AudioPlayer _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _isPlaying = s == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (widget.audioFileName == null || widget.audioFileName!.isEmpty) return;
    final source = AssetSource('audio/${widget.audioFileName}');
    try {
      await _player.stop();
      await _player.play(source);
    } catch (e) {
      // Fail silently in UI
      debugPrint('ExerciseAudioButton: failed to play asset: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.audioFileName;
    if (name == null || name.isEmpty) return const SizedBox.shrink();

    return InkResponse(
      onTap: _isPlaying ? null : _play,
      radius: widget.size,
      child: Opacity(
        opacity: _isPlaying ? 0.6 : 1.0,
        child: SvgPicture.asset(
          'assets/svg/volume.svg',
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
