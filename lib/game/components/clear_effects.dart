import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LaserClearEffect extends PositionComponent {
  final bool isHorizontal;
  final Color laserColor;
  double _time = 0.0;
  final double duration = 0.45; // 450ms animation

  LaserClearEffect({
    required this.isHorizontal,
    required this.laserColor,
    required super.position,
    required super.size,
  }) : super(
          anchor: Anchor.topLeft,
          priority: 150, // Render above cells but below text popups
        );

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_time >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = (_time / duration).clamp(0.0, 1.0);

    // Expand quickly, then fade out
    double scale = 0.05 + sin(progress * pi / 2) * 1.75;
    double opacity = 1.0 - pow(progress, 1.5);

    final Paint glowPaint = Paint()
      ..color = laserColor.withOpacity(opacity * 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    final Paint outerPaint = Paint()
      ..color = laserColor.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final Paint corePaint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    if (isHorizontal) {
      double currentHeight = size.y * scale;
      final rect = Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: size.x,
        height: currentHeight,
      );

      // 1. Draw blurred glow
      canvas.drawRect(rect, glowPaint);

      // 2. Draw colored outer beam
      canvas.drawRect(rect, outerPaint);

      // 3. Draw bright white core (15% height)
      final coreRect = Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: size.x,
        height: currentHeight * 0.18,
      );
      canvas.drawRect(coreRect, corePaint);
    } else {
      double currentWidth = size.x * scale;
      final rect = Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: currentWidth,
        height: size.y,
      );

      // 1. Draw blurred glow
      canvas.drawRect(rect, glowPaint);

      // 2. Draw colored outer beam
      canvas.drawRect(rect, outerPaint);

      // 3. Draw bright white core (15% width)
      final coreRect = Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: currentWidth * 0.18,
        height: size.y,
      );
      canvas.drawRect(coreRect, corePaint);
    }
  }
}

class StarParticle extends PositionComponent {
  final Vector2 velocity;
  final Color color;
  final double maxLifetime;
  final double spinSpeed;
  double _time = 0.0;
  double _scale = 1.0;

  StarParticle({
    required Vector2 position,
    required this.velocity,
    required this.color,
    required this.maxLifetime,
    required this.spinSpeed,
  }) : super(
          position: position,
          anchor: Anchor.center,
          priority: 160, // Render above laser effect
        );

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_time >= maxLifetime) {
      removeFromParent();
      return;
    }

    // Move
    position += velocity * dt;

    // Apply physics: gravity pull down, slight drag
    velocity.y += 180 * dt;
    velocity.x *= 0.96;

    // Spin
    angle += spinSpeed * dt;

    // Scale down
    double progress = _time / maxLifetime;
    _scale = 1.0 - progress;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_scale <= 0) return;

    final double opacity = (1.0 - (_time / maxLifetime)).clamp(0.0, 1.0);

    // Glow paint
    final glowPaint = Paint()
      ..color = color.withOpacity(opacity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
      ..style = PaintingStyle.fill;

    // Solid paint
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // White core paint
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // Custom 4-pointed star path
    double size = 12.0 * _scale;
    final path = Path();
    path.moveTo(0, -size);
    path.quadraticBezierTo(0, 0, size, 0);
    path.quadraticBezierTo(0, 0, 0, size);
    path.quadraticBezierTo(0, 0, -size, 0);
    path.quadraticBezierTo(0, 0, 0, -size);
    path.close();

    canvas.save();
    // 1. Draw glowing background star
    canvas.drawPath(path, glowPaint);

    // 2. Draw colored main star
    canvas.drawPath(path, paint);

    // 3. Draw tiny white core sparkle inside
    double innerSize = size * 0.42;
    final innerPath = Path();
    innerPath.moveTo(0, -innerSize);
    innerPath.quadraticBezierTo(0, 0, innerSize, 0);
    innerPath.quadraticBezierTo(0, 0, 0, innerSize);
    innerPath.quadraticBezierTo(0, 0, -innerSize, 0);
    innerPath.quadraticBezierTo(0, 0, 0, -innerSize);
    innerPath.close();

    canvas.drawPath(innerPath, corePaint);
    canvas.restore();
  }
}
