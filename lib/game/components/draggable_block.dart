import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../color_block_game.dart';

class DraggableBlock extends PositionComponent
    with DragCallbacks, HasGameReference<ColorBlockGame> {
  final List<Vector2> shapeOffsets;
  final Color color;
  final double cellSize;
  Vector2 originalPosition;
  final VoidCallback onPlace;

  DraggableBlock({
    required this.shapeOffsets,
    required this.color,
    required this.cellSize,
    required this.originalPosition,
    required this.onPlace,
  }) : super(anchor: Anchor.center) {
    // Calculate size based on shape
    double maxX = 0;
    double maxY = 0;
    for (var v in shapeOffsets) {
      if (v.x > maxX) maxX = v.x;
      if (v.y > maxY) maxY = v.y;
    }
    width = (maxX + 1) * cellSize;
    height = (maxY + 1) * cellSize;

    // Initial scale small
    scale = Vector2.all(0.6);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // Expand touch area for better usability
    // Since blocks in pool are small (0.6 scale), we add generous padding
    const double padding = 50.0;
    return Rect.fromLTRB(
      -padding,
      -padding,
      width + padding,
      height + padding,
    ).contains(point.toOffset());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = color;
    final r = 4.0;

    for (var v in shapeOffsets) {
      final rect = Rect.fromLTWH(
        v.x * cellSize,
        v.y * cellSize,
        cellSize,
        cellSize,
      );
      // Deflate slightly for gap
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(2), Radius.circular(r)),
        paint,
      );
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    priority = 100; // Bring to front
    // Scale up
    add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.1)));

    // Position offset - Shift visual position so block is above finger
    // We adjust position relative to current touch point (which is implicitly handled by starting movement from here)
    // Shift Y up by ~80% of block height or fixed amount
    position.y -= 100;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // Keep moving with the finger (delta)
    position += event.localDelta;
    game.updatePreview(this);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    game.clearPreview();

    // Check if valid drop
    // We need to convert our Center position to grid coordinates
    // We need access to GridBoard.

    bool placed = game.attemptPlacement(this);

    if (placed) {
      onPlace();
      removeFromParent();
    } else {
      // Return to original
      add(
        MoveEffect.to(
          originalPosition,
          EffectController(duration: 0.2, curve: Curves.easeOut),
        ),
      );
      add(ScaleEffect.to(Vector2.all(0.6), EffectController(duration: 0.2)));
      priority = 0;
    }
  }
}
