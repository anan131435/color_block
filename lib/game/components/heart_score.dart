import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../color_block_game.dart';

class HeartScoreComponent extends PositionComponent with HasGameReference<ColorBlockGame> {
  double _time = 0;
  double _visualScore = 0;
  late TextComponent scoreText;
  
  HeartScoreComponent({required super.position}) : super(size: Vector2(92, 85), anchor: Anchor.center);
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Add Score Text as a child of the heart so it scales together
    scoreText = TextComponent(
      text: '0',
      anchor: Anchor.center,
      position: Vector2(width / 2, height * 0.44), // Slightly above center for visual balance inside the heart
      textRenderer: TextPaint(
        style: GoogleFonts.fredoka(
          color: Colors.white,
          fontSize: 24, // Adjusted font size to fit inside the smaller heart
          fontWeight: FontWeight.w900,
          shadows: [
            const Shadow(
              color: Colors.black45,
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
    add(scoreText);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Heartbeat scale pulse (lub-dub)
    _time += dt * 3.5; // speed of heartbeat
    double t = (_time % (2 * pi));
    double pulse = 0.0;
    if (t < pi / 2) {
      pulse = sin(t * 2) * 0.08; // first beat (lub)
    } else if (t < pi) {
      pulse = sin((t - pi / 2) * 2) * 0.04; // second beat (dub)
    }
    scale = Vector2.all(1.0 + pulse);
    
    // Score interpolation (rolling score)
    if (_visualScore < game.score) {
      double diff = game.score - _visualScore;
      // Rolling speed depends on difference, ensuring it finishes in ~0.5s
      double speed = max(30.0, diff * 4.0);
      _visualScore = min(game.score.toDouble(), _visualScore + speed * dt);
      scoreText.text = '${_visualScore.round()}';
    } else if (_visualScore > game.score) {
      // Handles reset
      _visualScore = game.score.toDouble();
      scoreText.text = '${game.score}';
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw glowing shadow
    final Paint glowPaint = Paint()
      ..color = const Color(0xFFFF4081).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    
    final Path heartPath = _getHeartPath(width, height);
    
    // Offset glow slightly
    canvas.save();
    canvas.translate(0, 2);
    canvas.drawPath(heartPath, glowPaint);
    canvas.restore();
    
    // Draw main pink heart with gradient
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFF80AB), // Soft pink
          Color(0xFFF50057), // Vibrant pink
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(heartPath, paint);
    
    // Draw highlight on top part of the heart for 3D effect
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    // Draw a subtle curve highlight on the left lobe
    final Path highlightPath = Path();
    highlightPath.moveTo(width * 0.25, height * 0.15);
    highlightPath.quadraticBezierTo(width * 0.12, height * 0.2, width * 0.12, height * 0.4);
    canvas.drawPath(highlightPath, highlightPaint);
  }
  
  Path _getHeartPath(double w, double h) {
    final path = Path();
    // Start at top middle cleft
    path.moveTo(w / 2, h * 0.25);
    
    // Left lobe curve
    path.cubicTo(
      w * 0.15, h * 0.0,
      0, h * 0.2,
      0, h * 0.48,
    );
    
    // Left bottom curve to tip
    path.cubicTo(
      0, h * 0.72,
      w * 0.25, h * 0.88,
      w / 2, h * 0.98,
    );
    
    // Right bottom curve to tip
    path.cubicTo(
      w * 0.75, h * 0.88,
      w, h * 0.72,
      w, h * 0.48,
    );
    
    // Right lobe curve
    path.cubicTo(
      w, h * 0.2,
      w * 0.85, h * 0.0,
      w / 2, h * 0.25,
    );
    
    path.close();
    return path;
  }
}
