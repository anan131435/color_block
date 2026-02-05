import 'dart:ui';
import 'package:flutter/material.dart';

class BlockRenderer {
  /// Renders a single "Faceted Gem" styled block.
  /// [rect]: The bounds of the cell to draw in.
  /// [color]: The base color of the gem.
  /// [opacity]: Transparency, mostly for previews.
  static void render(
    Canvas canvas,
    Rect rect,
    Color color, {
    double opacity = 1.0,
  }) {
    // 1. Spacing: a small gap between blocks
    final cellRect = rect.deflate(1.0);

    // If fully transparent, don't draw
    if (opacity <= 0.0) return;

    // 2. Bevel Configuration
    // The width of the slanted edge.
    final bevel = 6.0;

    // 3. Prepare Colors
    // We create variants of the base color for the facets.
    final hsl = HSLColor.fromColor(color);

    // Top: Very bright (Highlight)
    final topColor = hsl
        .withLightness((hsl.lightness + 0.3).clamp(0.0, 1.0))
        .toColor()
        .withOpacity(opacity);
    // Left: Bright
    final leftColor = hsl
        .withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0))
        .toColor()
        .withOpacity(opacity);
    // Center: Base
    final centerColor = color.withOpacity(opacity);
    // Right: Shadow
    final rightColor = hsl
        .withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0))
        .toColor()
        .withOpacity(opacity);
    // Bottom: Dark Shadow
    final bottomColor = hsl
        .withLightness((hsl.lightness - 0.3).clamp(0.0, 1.0))
        .toColor()
        .withOpacity(opacity);

    // 4. Coordinates
    // Outer corners
    final pixelLeft = cellRect.left;
    final pixelRight = cellRect.right;
    final pixelTop = cellRect.top;
    final pixelBottom = cellRect.bottom;

    // Inner corners (deflated by bevel)
    final innerLeft = pixelLeft + bevel;
    final innerRight = pixelRight - bevel;
    final innerTop = pixelTop + bevel;
    final innerBottom = pixelBottom - bevel;

    // 5. Draw Facets using Paths
    final paint = Paint()..style = PaintingStyle.fill;

    // TOP Facet (Trapezoid)
    if (innerTop < innerBottom) {
      // Ensure space exists
      final topPath = Path()
        ..moveTo(pixelLeft, pixelTop)
        ..lineTo(pixelRight, pixelTop)
        ..lineTo(innerRight, innerTop)
        ..lineTo(innerLeft, innerTop)
        ..close();
      paint.color = topColor;
      canvas.drawPath(topPath, paint);

      // BOTTOM Facet
      final bottomPath = Path()
        ..moveTo(pixelLeft, pixelBottom)
        ..lineTo(pixelRight, pixelBottom)
        ..lineTo(innerRight, innerBottom)
        ..lineTo(innerLeft, innerBottom)
        ..close();
      paint.color = bottomColor;
      canvas.drawPath(bottomPath, paint);

      // LEFT Facet
      final leftPath = Path()
        ..moveTo(pixelLeft, pixelTop)
        ..lineTo(innerLeft, innerTop)
        ..lineTo(innerLeft, innerBottom)
        ..lineTo(pixelLeft, pixelBottom)
        ..close();
      paint.color = leftColor;
      canvas.drawPath(leftPath, paint);

      // RIGHT Facet
      final rightPath = Path()
        ..moveTo(pixelRight, pixelTop)
        ..lineTo(innerRight, innerTop)
        ..lineTo(innerRight, innerBottom)
        ..lineTo(pixelRight, pixelBottom)
        ..close();
      paint.color = rightColor;
      canvas.drawPath(rightPath, paint);

      // CENTER Face (Rect)
      final centerRect = Rect.fromLTRB(
        innerLeft,
        innerTop,
        innerRight,
        innerBottom,
      );
      paint.color = centerColor;
      canvas.drawRect(centerRect, paint);

      // Optional: Add a subtle gradient to the center face for more "gem" depth
      // Or a small shine path
    } else {
      // Fallback if too small for bevels (rare)
      paint.color = centerColor;
      canvas.drawRect(cellRect, paint);
    }
  }
}
