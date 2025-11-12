import 'package:flutter/material.dart';
import '../../data/models/level_model.dart';

/// Collection of SVG icons as Flutter widgets for level types
/// These are embedded SVG paths converted to Flutter CustomPainter widgets
/// for performance and consistency across the app

/// Star icon for star-type levels
class StarSvg extends StatelessWidget {
  final double size;
  final Color color;

  const StarSvg({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StarPainter(color),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;

  _StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.4;

    // Create star shape
    for (int i = 0; i < 10; i++) {
      final angle = (i * 36 - 90) * (3.14159 / 180);
      final radius = i % 2 == 0 ? outerRadius : innerRadius;
      final x = centerX + radius * (i % 2 == 0 ? 0.8 : 0.6) * 
                (angle == 0 ? 0 : (i % 2 == 0 ? 
                  (i < 5 ? 1 : -1) * 0.8 : 
                  (i < 5 ? 1 : -1) * 0.4));
      final y = centerY + radius * (i % 2 == 0 ? 0.8 : 0.6) * 
                (angle == 0 ? -1 : (i % 2 == 0 ? 
                  (i == 2 || i == 8 ? 0.3 : (i == 4 || i == 6 ? 1 : -0.3)) : 
                  (i == 3 || i == 7 ? 0.8 : (i == 1 || i == 9 ? -0.8 : 0))));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Book icon for lesson levels
class BookSvg extends StatelessWidget {
  final double size;
  final Color color;

  const BookSvg({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.8),
      painter: _BookPainter(color),
    );
  }
}

class _BookPainter extends CustomPainter {
  final Color color;

  _BookPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.1, 
                   size.width * 0.8, size.height * 0.8),
      const Radius.circular(2),
    );

    canvas.drawRRect(rect, paint);

    // Draw pages
    final linePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (0.2 + i * 0.15);
      canvas.drawLine(
        Offset(size.width * 0.2, y),
        Offset(size.width * 0.8, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dumbbell icon for practice levels
class DumbbellSvg extends StatelessWidget {
  final double size;
  final Color color;

  const DumbbellSvg({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.6),
      painter: _DumbbellPainter(color),
    );
  }
}

class _DumbbellPainter extends CustomPainter {
  final Color color;

  _DumbbellPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;
    final barWidth = size.width * 0.6;
    final barHeight = size.height * 0.15;
    final weightSize = size.height * 0.4;

    // Draw center bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, centerY),
          width: barWidth,
          height: barHeight,
        ),
        const Radius.circular(2),
      ),
      paint,
    );

    // Draw left weight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.15, centerY),
          width: weightSize * 0.6,
          height: weightSize,
        ),
        const Radius.circular(2),
      ),
      paint,
    );

    // Draw right weight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.85, centerY),
          width: weightSize * 0.6,
          height: weightSize,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Chest/treasure icon for reward levels
class ChestSvg extends StatelessWidget {
  final double size;
  final Color color;

  const ChestSvg({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.8),
      painter: _ChestPainter(color),
    );
  }
}

class _ChestPainter extends CustomPainter {
  final Color color;

  _ChestPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Chest body
    final chestRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.3, 
                   size.width * 0.8, size.height * 0.6),
      const Radius.circular(4),
    );
    canvas.drawRRect(chestRect, paint);

    // Chest lid
    final lidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.05, size.height * 0.1, 
                   size.width * 0.9, size.height * 0.3),
      const Radius.circular(6),
    );
    canvas.drawRRect(lidRect, paint);

    // Lock/keyhole
    final lockPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.6),
      size.width * 0.08,
      lockPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Trophy icon for achievement levels
class TrophySvg extends StatelessWidget {
  final double size;
  final Color color;

  const TrophySvg({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TrophyPainter(color),
    );
  }
}

class _TrophyPainter extends CustomPainter {
  final Color color;

  _TrophyPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Trophy cup
    final cupPath = Path();
    cupPath.moveTo(size.width * 0.3, size.height * 0.2);
    cupPath.lineTo(size.width * 0.7, size.height * 0.2);
    cupPath.lineTo(size.width * 0.65, size.height * 0.6);
    cupPath.lineTo(size.width * 0.35, size.height * 0.6);
    cupPath.close();

    canvas.drawPath(cupPath, paint);

    // Trophy base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.25, size.height * 0.7, 
                     size.width * 0.5, size.height * 0.15),
        const Radius.circular(2),
      ),
      paint,
    );

    // Trophy stem
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.45, size.height * 0.6, 
                     size.width * 0.1, size.height * 0.15),
        const Radius.circular(1),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Fast forward icon for jump levels
class FastForwardSvg extends StatelessWidget {
  final double size;
  final Color color;

  const FastForwardSvg({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.8),
      painter: _FastForwardPainter(color),
    );
  }
}

class _FastForwardPainter extends CustomPainter {
  final Color color;

  _FastForwardPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // First triangle
    final triangle1 = Path();
    triangle1.moveTo(size.width * 0.1, size.height * 0.2);
    triangle1.lineTo(size.width * 0.45, size.height * 0.5);
    triangle1.lineTo(size.width * 0.1, size.height * 0.8);
    triangle1.close();

    canvas.drawPath(triangle1, paint);

    // Second triangle
    final triangle2 = Path();
    triangle2.moveTo(size.width * 0.55, size.height * 0.2);
    triangle2.lineTo(size.width * 0.9, size.height * 0.5);
    triangle2.lineTo(size.width * 0.55, size.height * 0.8);
    triangle2.close();

    canvas.drawPath(triangle2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Checkmark icon for completed levels
class CheckmarkSvg extends StatelessWidget {
  final double size;
  final Color color;

  const CheckmarkSvg({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CheckmarkPainter(color),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final Color color;

  _CheckmarkPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.7);
    path.lineTo(size.width * 0.8, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Utility function to get the appropriate icon for a level
Widget getLevelIcon(LevelModel level, {double size = 24.0}) {
  final color = level.status == LevelStatus.completed 
    ? Colors.white 
    : Colors.white;

  if (level.status == LevelStatus.completed) {
    return CheckmarkSvg(size: size, color: color);
  }

  switch (level.type) {
    case LevelType.star:
      return StarSvg(size: size, color: color);
    case LevelType.book:
      return BookSvg(size: size, color: color);
    case LevelType.dumbbell:
      return DumbbellSvg(size: size, color: color);
    case LevelType.chest:
      // For chest, return a simple icon since it's handled specially in level_tile
      return Icon(Icons.card_giftcard, size: size, color: color);
    case LevelType.trophy:
      return TrophySvg(size: size, color: color);
    case LevelType.fastForward:
      return FastForwardSvg(size: size, color: color);
  }
}
