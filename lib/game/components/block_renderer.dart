import 'dart:ui';
import 'package:flutter/material.dart';

class BlockRenderer {
  /// Renders a single 3D-styled block within [rect] using [color].
  /// [opacity] allows for transparency (e.g., for previews).
  static void render(
    Canvas canvas,
    Rect rect,
    Color color, {
    double opacity = 1.0,
  }) {
    // 1. Deflate slightly for gap between blocks
    final effectiveRect = rect.deflate(2.0);
    final rrect = RRect.fromRectAndRadius(
      effectiveRect,
      const Radius.circular(6.0),
    );

    // 2. Prepare Colors (HSL for lightness adjustment)
    final hsl = HSLColor.fromColor(color);

    // Lighter top-left
    final lightColor = hsl
        .withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0))
        .toColor()
        .withOpacity(opacity);
    // Base color
    final baseColor = color.withOpacity(opacity);
    // Darker bottom-right
    final darkColor = hsl
        .withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0))
        .toColor()
        .withOpacity(opacity);

    // 3. Main Body Gradient
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lightColor, baseColor, darkColor],
      ).createShader(effectiveRect);

    canvas.drawRRect(rrect, paint);

    // 4. Inner Highlights/Shadows (Bevel effect)
    // Top-Left Light Rim
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.center,
        colors: [Colors.white.withOpacity(0.5 * opacity), Colors.transparent],
      ).createShader(effectiveRect);

    canvas.drawRRect(rrect.deflate(1.0), highlightPaint);

    // Bottom-Right Dark Rim
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        begin: Alignment.center,
        end: Alignment.bottomRight,
        colors: [Colors.transparent, Colors.black.withOpacity(0.3 * opacity)],
      ).createShader(effectiveRect);

    canvas.drawRRect(rrect.deflate(1.0), shadowPaint);

    // Optional: Center Gloss
    // A small radial gradient at top-left to simulate light reflection
    /*
    final glossRect = Rect.fromLTWH(
      effectiveRect.left + effectiveRect.width * 0.1,
      effectiveRect.top + effectiveRect.height * 0.1,
      effectiveRect.width * 0.4,
      effectiveRect.height * 0.4,
    );
     final glossPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.2 * opacity), Colors.transparent],
      ).createShader(glossRect);
    canvas.drawOval(glossRect, glossPaint);
    */
  }
}
