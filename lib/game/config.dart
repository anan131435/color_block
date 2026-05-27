import 'dart:ui';
import 'package:flame/components.dart';

class GameConfigFile {
  static const int gridRows = 8;
  static const int gridCols = 8;

  // Gem Colors
  static const Color color1 = Color(0xFFC91C39); // Gem Red
  static const Color color2 = Color(0xFF54BA44); // Gem Green (Lime)
  static const Color color3 = Color(0xFFEA7B30); // Gem Yellow (Amber)
  static const Color color4 = Color(0xFF2567D3); // Gem Blue
  static const Color color5 = Color(0xFF09BAC1);
  static const Color color6 = Color(0xFF8051D4);
  static const Color color7 = Color(0xFFE6B73F);
  // Add more varieties if needed, but these match the reference vibes (Red, Green, Yellow)

  static const List<Color> blockColors = [color1, color2, color3, color4,color5,color6,color7];

  // Shapes defined as list of (x, y) offsets
  // Removed const since Vector2 is not const
  static final List<List<Vector2>> shapes = [
    // 1x1
    [Vector2(0, 0)],
    // 1x2 Vertical
    [Vector2(0, 0), Vector2(0, 1)],
    // 1x2 Horizontal
    [Vector2(0, 0), Vector2(1, 0)],
    // 1x3 Vertical
    [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2)],
    // 1x3 Horizontal
    [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)],
    // 2x2 Square
    [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)],
    // L shape (3x2)
    [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(1, 2)],
    // J shape
    [Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(0, 2)],
    // T shape
    [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(1, 1)],

    // === 1x4 直线 ===
    // 1x4 Vertical
    [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)],
    // 1x4 Horizontal
    [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)],

    // === 1x5 直线 ===
    // 1x5 Vertical
    [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3), Vector2(0, 4)],
    // 1x5 Horizontal
    [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(4, 0)],

    // === 3x3 正方形 ===
    [
      Vector2(0, 0), Vector2(1, 0), Vector2(2, 0),
      Vector2(0, 1), Vector2(1, 1), Vector2(2, 1),
      Vector2(0, 2), Vector2(1, 2), Vector2(2, 2)
    ],

    // === Z & S 形方块 ===
    // Z Shape (Horizontal)
    [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 1)],
    // Z Shape (Vertical)
    [Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(0, 2)],
    // S Shape (Horizontal)
    [Vector2(1, 0), Vector2(2, 0), Vector2(0, 1), Vector2(1, 1)],
    // S Shape (Vertical)
    [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 2)],

    // === 大 L 型拐角 (3x3 范围, 5 方格) ===
    // Big L (Normal)
    [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(1, 2), Vector2(2, 2)],
    // Big L (Rotated 90)
    [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(0, 1), Vector2(0, 2)],
    // Big L (Rotated 180)
    [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(2, 1), Vector2(2, 2)],
    // Big L (Rotated 270)
    [Vector2(2, 0), Vector2(2, 1), Vector2(2, 2), Vector2(1, 2), Vector2(0, 2)],

    // === 小 L 型拐角 (2x2 范围, 3 方格) ===
    // Small L (Normal)
    [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1)],
    // Small L (Rotated 90)
    [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1)],
    // Small L (Rotated 180)
    [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)],
    // Small L (Rotated 270)
    [Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)],

    // === 对角斜线 ===
    // 2-block Diagonal (Forward)
    [Vector2(0, 0), Vector2(1, 1)],
    // 2-block Diagonal (Backward)
    [Vector2(1, 0), Vector2(0, 1)],
    // 3-block Diagonal (Forward)
    [Vector2(0, 0), Vector2(1, 1), Vector2(2, 2)],
    // 3-block Diagonal (Backward)
    [Vector2(2, 0), Vector2(1, 1), Vector2(0, 2)],
  ];
}
