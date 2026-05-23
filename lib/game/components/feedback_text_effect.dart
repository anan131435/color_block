import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedbackTextEffect extends PositionComponent {
  final String text;
  final Color textColor;
  double opacity = 1.0;
  double age = 0.0;

  late final TextPainter shadowPainter;
  late final TextPainter mainPainter;

  FeedbackTextEffect({
    required this.text,
    required this.textColor,
    required Vector2 position,
  }) : super(
          position: position,
          anchor: Anchor.center,
          priority: 200, // Render on top of board and elements
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    shadowPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    mainPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Initial layouts to set width and height bounds based on Fredoka style
    _updatePainters();
    width = mainPainter.width;
    height = mainPainter.height;

    // Start small and pop up
    scale = Vector2.all(0.0);
    add(
      ScaleEffect.to(
        Vector2.all(1.2),
        EffectController(duration: 0.35, curve: Curves.elasticOut),
      ),
    );

    // Move upward slowly
    add(
      MoveEffect.by(
        Vector2(0, -60),
        EffectController(duration: 0.9, curve: Curves.easeOut),
      ),
    );

    // Random tilt for a stylish pop look
    angle = -0.12 + Random().nextDouble() * 0.24;

    // Spawn bursting particles in the game parent component
    _spawnParticles();
  }

  void _updatePainters() {
    final shadowColor = Color.lerp(textColor, Colors.black, 0.42)!;

    shadowPainter.text = TextSpan(
      text: text,
      style: GoogleFonts.fredoka(
        fontSize: 54,
        fontWeight: FontWeight.w900,
        color: shadowColor.withOpacity(opacity),
      ),
    );
    shadowPainter.layout();

    mainPainter.text = TextSpan(
      text: text,
      style: GoogleFonts.fredoka(
        fontSize: 54,
        fontWeight: FontWeight.w900,
        color: textColor.withOpacity(opacity),
        shadows: [
          Shadow(
            blurRadius: 10,
            color: Colors.black45.withOpacity(opacity),
            offset: const Offset(2, 2),
          ),
        ],
      ),
    );
    mainPainter.layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    age += dt;
    if (age > 0.65) {
      opacity = (1.0 - (age - 0.65) / 0.25).clamp(0.0, 1.0);
      _updatePainters();
    }

    // Auto-remove when animation finishes
    if (age >= 0.9) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (opacity <= 0) return;

    // 1. Draw 3D shadow layers (matching home page Color Block style)
    for (double i = 5; i > 0; i--) {
      shadowPainter.paint(
        canvas,
        Offset(i, i),
      );
    }

    // 2. Draw main text
    mainPainter.paint(
      canvas,
      Offset.zero,
    );
  }

  void _spawnParticles() {
    final rng = Random();
    // Add particles to the game world parent so they burst in absolute space
    final targetParent = parent;
    if (targetParent == null) return;

    // Spawn 22 particles for a dense, obvious explosion effect
    for (int i = 0; i < 22; i++) {
      final double angle = rng.nextDouble() * 2 * pi;
      // Increase speed (120 to 320) so they shoot out more dynamically
      final double speed = 120 + rng.nextDouble() * 200;
      final double distance = 10 + rng.nextDouble() * 25;
      final Vector2 direction = Vector2(cos(angle), sin(angle));

      final particleColor = [
        const Color(0xFFFFEB3B), // Yellow
        const Color(0xFFFF5722), // Orange/Red
        const Color(0xFFE91E63), // Pink
        const Color(0xFF00E5FF), // Cyan
        const Color(0xFF00E676), // Green
      ][rng.nextInt(5)];

      // Spawn relative to the current center position of the text pop
      final particle = _BurstParticle(
        position: position + (direction * distance),
        direction: direction,
        speed: speed,
        color: particleColor,
      );
      targetParent.add(particle);
    }
  }
}

class _BurstParticle extends PositionComponent {
  final Vector2 direction;
  final double speed;
  final Color color;
  double opacity = 1.0;

  _BurstParticle({
    required Vector2 position,
    required this.direction,
    required this.speed,
    required this.color,
  }) : super(
          position: position,
          anchor: Anchor.center,
          priority: 201, // Render slightly above the text
        );

  @override
  void update(double dt) {
    super.update(dt);
    // Move particle outward
    position += direction * speed * dt;
    // Slow down fade-out slightly so they stay visible a tiny bit longer
    opacity = (opacity - dt * 1.5).clamp(0.0, 1.0);
    // Slow down shrink scale slightly so they stay larger longer
    scale -= Vector2.all(dt * 1.2);

    // Auto-remove when faded or invisible
    if (scale.x <= 0 || opacity <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (opacity <= 0 || scale.x <= 0) return;

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // Draw diamond shape path - Increase base size to 14.0 for a larger visual impact!
    final path = Path();
    double size = 14.0 * scale.x;
    path.moveTo(0, -size);
    path.lineTo(size / 2, 0);
    path.lineTo(0, size);
    path.lineTo(-size / 2, 0);
    path.close();

    canvas.drawPath(path, paint);
  }
}
