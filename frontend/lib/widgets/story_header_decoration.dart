import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A quiet botanical corner ornament, drawn at any display density.
class StoryHeaderDecoration extends CustomPainter {
  const StoryHeaderDecoration();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 145, size.height / 110);
    final leaf = Paint()
      ..color = const Color(0xFFAAA986).withValues(alpha: .32);
    final stem = Paint()
      ..color = const Color(0xFF969B76).withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final hill = Paint()
      ..color = const Color(0xFFD6CEAA).withValues(alpha: .20);
    canvas.drawPath(
      Path()
        ..moveTo(35, 58)
        ..quadraticBezierTo(67, 25, 92, 42)
        ..quadraticBezierTo(119, 16, 145, 37)
        ..lineTo(145, 70)
        ..close(),
      hill,
    );
    // Distant roof and spire silhouettes.
    final temple = Paint()
      ..color = const Color(0xFFB9BB99).withValues(alpha: .26);
    for (final x in [92.0, 128.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x - 10, 49)
          ..lineTo(x - 10, 34)
          ..lineTo(x - 5, 29)
          ..lineTo(x - 3, 22)
          ..lineTo(x, 18)
          ..lineTo(x + 3, 22)
          ..lineTo(x + 5, 29)
          ..lineTo(x + 10, 34)
          ..lineTo(x + 10, 49)
          ..close(),
        temple,
      );
      canvas.drawLine(Offset(x, 10), Offset(x, 24), stem);
    }
    canvas.drawPath(
      Path()
        ..moveTo(142, 108)
        ..quadraticBezierTo(91, 80, 60, 25),
      stem,
    );
    canvas.drawPath(
      Path()
        ..moveTo(138, 104)
        ..quadraticBezierTo(112, 65, 121, 26),
      stem,
    );
    void drawLeaf(double x, double y, double angle, double length) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(length * .45, -length * .45, length, 0)
          ..quadraticBezierTo(length * .45, length * .22, 0, 0),
        leaf,
      );
      canvas.restore();
    }

    drawLeaf(79, 53, -2.9, 25);
    drawLeaf(85, 61, -1.1, 24);
    drawLeaf(99, 78, -2.7, 29);
    drawLeaf(105, 83, -.8, 25);
    drawLeaf(120, 66, -.65, 22);
    drawLeaf(119, 48, -2.7, 20);
    drawLeaf(130, 92, -2.8, 27);
    void flower(double x, double y, double radius, int petals) {
      final petal = Paint()
        ..color = const Color(0xFFC7A565).withValues(alpha: .36);
      for (var i = 0; i < petals; i++) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(i * math.pi * 2 / petals);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, -radius * .6),
            width: radius * .48,
            height: radius * 1.3,
          ),
          petal,
        );
        canvas.restore();
      }
      canvas.drawCircle(
        Offset(x, y),
        radius * .20,
        Paint()..color = const Color(0xFFB79050).withValues(alpha: .42),
      );
    }

    flower(63, 25, 8, 8);
    flower(106, 67, 14, 9);
    flower(126, 24, 6, 7);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StoryHeaderDecoration oldDelegate) => false;
}
