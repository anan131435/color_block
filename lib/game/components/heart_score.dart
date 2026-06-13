import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../color_block_game.dart';

class DigitComponent extends PositionComponent {
  String _char = '0';
  Color color;
  double _scaleAnim = 1.0;
  double _offsetY = 0.0;
  double _animTime = 0.0;
  bool _isAnimating = false;
  
  DigitComponent({required String char, required this.color, required super.position}) : _char = char {
    anchor = Anchor.center;
    size = Vector2(14, 24); // Size of a single digit
  }
  
  set char(String newChar) {
    if (_char != newChar) {
      _char = newChar;
      // Trigger bounce animation
      _isAnimating = true;
      _animTime = 0.0;
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    if (_isAnimating) {
      _animTime += dt;
      const double duration = 0.22; // 220ms bounce
      if (_animTime >= duration) {
        _isAnimating = false;
        _scaleAnim = 1.0;
        _offsetY = 0.0;
      } else {
        double progress = _animTime / duration;
        // Lift and scale bounce curve using sine wave
        _scaleAnim = 1.0 + sin(progress * pi) * 0.45;
        _offsetY = -sin(progress * pi) * 10.0;
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final textPaint = TextPaint(
      style: GoogleFonts.fredoka(
        color: color,
        fontSize: 22, // Proportionate font size inside heart
        fontWeight: FontWeight.w900,
        shadows: [
          const Shadow(
            color: Colors.black38,
            offset: Offset(0, 1.5),
            blurRadius: 3,
          ),
        ],
      ),
    );
    
    canvas.save();
    canvas.translate(0, _offsetY);
    canvas.scale(_scaleAnim);
    textPaint.render(
      canvas,
      _char,
      Vector2(width / 2, height / 2),
      anchor: Anchor.center,
    );
    canvas.restore();
  }
}

class HeartScoreComponent extends PositionComponent with HasGameReference<ColorBlockGame> {
  double _time = 0;
  double _visualScore = 0;
  final List<DigitComponent> _digitComponents = [];
  
  static const List<Color> rainbowColors = [
    Color(0xFF00E5FF), // Light Blue
    Color(0xFFFF4081), // Pink
    Color(0xFFFFB300), // Orange
    Color(0xFF00E676), // Green
    Color(0xFFD500F9), // Purple
  ];
  
  HeartScoreComponent({required super.position}) : super(size: Vector2(92, 85), anchor: Anchor.center);
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    _updateDigits('0');
  }
  
  void _updateDigits(String scoreStr) {
    // If the number of digits changed, rebuild all digit components
    if (_digitComponents.length != scoreStr.length) {
      for (final comp in _digitComponents) {
        comp.removeFromParent();
      }
      _digitComponents.clear();
      
      final double digitSpacing = 13.0; // Spacing between digits
      final double totalWidth = scoreStr.length * digitSpacing;
      final double startX = (width - totalWidth) / 2;
      
      for (int i = 0; i < scoreStr.length; i++) {
        final comp = DigitComponent(
          char: scoreStr[i],
          color: rainbowColors[i % rainbowColors.length],
          position: Vector2(startX + i * digitSpacing + digitSpacing / 2, height * 0.42),
        );
        add(comp);
        _digitComponents.add(comp);
      }
    } else {
      // Otherwise, just update characters (they will bounce if they changed)
      for (int i = 0; i < scoreStr.length; i++) {
        _digitComponents[i].char = scoreStr[i];
      }
    }
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
      double speed = max(30.0, diff * 4.0);
      _visualScore = min(game.score.toDouble(), _visualScore + speed * dt);
      _updateDigits('${_visualScore.round()}');
    } else if (_visualScore > game.score) {
      _visualScore = game.score.toDouble();
      _updateDigits('${game.score}');
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
      
    final Path highlightPath = Path();
    highlightPath.moveTo(width * 0.25, height * 0.15);
    highlightPath.quadraticBezierTo(width * 0.12, height * 0.2, width * 0.12, height * 0.4);
    canvas.drawPath(highlightPath, highlightPaint);
  }
  
  Path _getHeartPath(double w, double h) {
    final path = Path();
    path.moveTo(w / 2, h * 0.25);
    path.cubicTo(w * 0.15, h * 0.0, 0, h * 0.2, 0, h * 0.48);
    path.cubicTo(0, h * 0.72, w * 0.25, h * 0.88, w / 2, h * 0.98);
    path.cubicTo(w * 0.75, h * 0.88, w, h * 0.72, w, h * 0.48);
    path.cubicTo(w, h * 0.2, w * 0.85, h * 0.0, w / 2, h * 0.25);
    path.close();
    return path;
  }
}
