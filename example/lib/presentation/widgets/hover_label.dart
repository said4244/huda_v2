import 'package:flutter/material.dart';

/// Floating label widget that appears above level tiles
/// Features:
/// - Bouncing animation (2s infinite)
/// - White rounded container with triangle pointer
/// - Dynamic width calculation based on text
/// - Positioned absolutely at -32px from top
class HoverLabel extends StatefulWidget {
  final String text;
  final bool isVisible;
  final Color backgroundColor;
  final Color textColor;

  const HoverLabel({
    super.key,
    required this.text,
    this.isVisible = true,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
  });

  @override
  State<HoverLabel> createState() => _HoverLabelState();
}

class _HoverLabelState extends State<HoverLabel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Bouncing translate animation with custom timing
    // Up movement (0.0 to 0.4): 2x speed (40% of time)
    // Down movement (0.4 to 1.0): 1.5x normal speed (60% of time)
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: -10.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const _CustomBounceCurve(),
    ));
    
    if (widget.isVisible) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(HoverLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: _buildLabel(), // Removed Opacity wrapper for 100% opacity
        );
      },
    );
  }

  Widget _buildLabel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Bigger padding
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(8), // Less rounded (was 16)
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // Slightly stronger shadow for better visibility
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 14, // Bigger font (was 12)
              fontWeight: FontWeight.w700, // Bolder (was w600)
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Triangle pointer
        CustomPaint(
          size: const Size(8, 6),
          painter: _TrianglePainter(widget.backgroundColor),
        ),
      ],
    );
  }

}

/// Custom painter for the triangle pointer below the label
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height); // Bottom center point
    path.lineTo(0, 0); // Top left
    path.lineTo(size.width, 0); // Top right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Convenience widget for common label types
class StartLabel extends StatelessWidget {
  final Color textColor;
  
  const StartLabel({super.key, this.textColor = Colors.black87});

  @override
  Widget build(BuildContext context) {
    return HoverLabel(
      text: 'START',
      backgroundColor: Colors.white,
      textColor: textColor,
    );
  }
}

class JumpLabel extends StatelessWidget {
  final Color textColor;
  
  const JumpLabel({super.key, this.textColor = Colors.black87});

  @override
  Widget build(BuildContext context) {
    return HoverLabel(
      text: 'JUMP HERE?',
      backgroundColor: Colors.white,
      textColor: textColor,
    );
  }
}

class OpenLabel extends StatelessWidget {
  final Color textColor;
  
  const OpenLabel({super.key, this.textColor = Colors.black87});

  @override
  Widget build(BuildContext context) {
    return HoverLabel(
      text: 'OPEN',
      backgroundColor: Colors.white,
      textColor: textColor,
    );
  }
}

/// Helper function to get the appropriate label for a level
Widget? getLevelLabel(String? labelText, {Color textColor = Colors.black87}) {
  if (labelText == null) return null;
  
  switch (labelText.toUpperCase()) {
    case 'START':
      return StartLabel(textColor: textColor);
    case 'JUMP HERE?':
      return JumpLabel(textColor: textColor);
    case 'OPEN':
      return OpenLabel(textColor: textColor);
    default:
      return HoverLabel(text: labelText, textColor: textColor);
  }
}

/// Custom curve for bounce animation with different speeds for up/down movement
class _CustomBounceCurve extends Curve {
  const _CustomBounceCurve();

  @override
  double transform(double t) {
    // Split the animation into two phases:
    // Phase 1 (0.0 to 0.2): Going up - 4x speed (doubled from 2x)
    // Phase 2 (0.2 to 1.0): Going down - 3x speed (doubled from 1.5x)
    
    if (t <= 0.2) {
      // Up movement: 4x speed (compress 0.0-0.2 into 0.0-1.0 range)
      final normalizedT = t / 0.2; // Convert 0.0-0.2 to 0.0-1.0
      return Curves.easeOut.transform(normalizedT);
    } else {
      // Down movement: 3x speed (compress 0.2-1.0 into 1.0-0.0 range)
      final normalizedT = (t - 0.2) / 0.8; // Convert 0.2-1.0 to 0.0-1.0
      return 1.0 - Curves.easeIn.transform(normalizedT);
    }
  }
}
