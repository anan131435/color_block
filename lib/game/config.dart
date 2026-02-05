import 'dart:ui';
import 'package:flame/components.dart';

class GameConfigFile {
  static const int gridRows = 8;
  static const int gridCols = 8;

  // Gem Colors
  static const Color color1 = Color(0xFFE53935); // Gem Red
  static const Color color2 = Color(0xFF76FF03); // Gem Green (Lime)
  static const Color color3 = Color(0xFFFFC400); // Gem Yellow (Amber)
  static const Color color4 = Color(0xFF2979FF); // Gem Blue
  // Add more varieties if needed, but these match the reference vibes (Red, Green, Yellow)

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
