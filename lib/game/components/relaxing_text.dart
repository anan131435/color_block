import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RelaxingText extends PositionComponent {
  late final TextPainter shadowPainter;
  late final TextPainter mainPainter;
  final String text = "ADDICTIVE";
  final Color textColor = const Color(0xFFFFEB3B); // Golden yellow like "COLOR"

  RelaxingText({required Vector2 position})
      : super(
          position: position,
          anchor: Anchor.center,
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

    final shadowColor = Color.lerp(textColor, Colors.black, 0.42)!;

    shadowPainter.text = TextSpan(
      text: text,
      style: GoogleFonts.fredoka(
        fontSize: 32, // Bubbly and readable bottom text
        fontWeight: FontWeight.w900,
        color: shadowColor,
        letterSpacing: 2.0,
      ),
    );
    shadowPainter.layout();

    mainPainter.text = TextSpan(
      text: text,
      style: GoogleFonts.fredoka(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: textColor,
        letterSpacing: 2.0,
        shadows: [
          const Shadow(
            blurRadius: 8,
            color: Colors.black38,
            offset: Offset(1.5, 1.5),
          ),
        ],
      ),
    );
    mainPainter.layout();

    width = mainPainter.width;
    height = mainPainter.height;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Draw 3D shadow layers (matching COLOR BLOCK homepage style)
    for (double i = 4; i > 0; i--) {
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
}
