import 'dart:ui';
import 'package:flame/components.dart';

class GameConfigFile {
  static const int gridRows = 8;
  static const int gridCols = 8;

  static const Color color1 = Color(0xFFFF5252); // Red
  static const Color color2 = Color(0xFF69F0AE); // Green
  static const Color color3 = Color(0xFFFFD740); // Yellow
  static const Color color4 = Color(0xFF448AFF); // Blue

  static const List<Color> blockColors = [color1, color2, color3, color4];

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
  ];
}
