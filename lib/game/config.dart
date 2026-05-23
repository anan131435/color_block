import 'dart:ui';
import 'dart:math';
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

  static const List<Color> blockColors = [color1, color2, color3, color4, color5, color6, color7];

  // Small Shapes (Size 1, 2, 3)
  static final List<List<Vector2>> smallShapes = [
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
  ];

  // Size 4 Shapes (Classic Shapes)
  static final List<List<Vector2>> size4Shapes = [
    // 2x2 Square
    [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)],
    // L Shape & Rotations
    [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(1, 2)],
    [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(0, 1)],
    [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(1, 2)],
    [Vector2(2, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)],
    // J Shape & Rotations
    [Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(0, 2)],
    [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)],
    [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0, 2)],
    [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(2, 1)],
    // T Shape & Rotations
    [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(1, 1)],
    [Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 2)],
    [Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)],
    [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(0, 2)],
    // Z Shape & Rotations
    [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 1)],
    [Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(0, 2)],
    // S Shape & Rotations
    [Vector2(1, 0), Vector2(2, 0), Vector2(0, 1), Vector2(1, 1)],
    [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 2)],
  ];

  // Size 5 Shapes
  static final List<List<Vector2>> size5Shapes = [
    // 1x5 Vertical
    [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3), Vector2(0, 4)],
    // 1x5 Horizontal
    [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(4, 0)],
  ];

  // Size 6 Shapes
  static final List<List<Vector2>> size6Shapes = [
    // 3x2 Rectangle (horizontal)
    [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)],
    // 2x3 Rectangle (vertical)
    [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(0, 2), Vector2(1, 2)],
  ];

  // Size 8 Shapes
  static final List<List<Vector2>> size8Shapes = [
    // 4x2 Rectangle (horizontal)
    [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1)],
    // 2x4 Rectangle (vertical)
    [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(0, 2), Vector2(1, 2), Vector2(0, 3), Vector2(1, 3)],
  ];

  // Size 9 Shapes
  static final List<List<Vector2>> size9Shapes = [
    // 3x3 Solid Square
    [
      Vector2(0, 0), Vector2(1, 0), Vector2(2, 0),
      Vector2(0, 1), Vector2(1, 1), Vector2(2, 1),
      Vector2(0, 2), Vector2(1, 2), Vector2(2, 2)
    ],
  ];

  // All shapes flattened for backwards compatibility
  static final List<List<Vector2>> shapes = [
    ...smallShapes,
    ...size4Shapes,
    ...size5Shapes,
    ...size6Shapes,
    ...size8Shapes,
    ...size9Shapes,
  ];

  // Get a random shape using weighted categories (mostly small/medium blocks to keep difficulty low)
  static List<Vector2> getRandomShape() {
    final rng = Random();
    final double roll = rng.nextDouble();

    if (roll < 0.30) {
      // Small shapes (size 1-3) - 30% chance
      return smallShapes[rng.nextInt(smallShapes.length)];
    } else if (roll < 0.65) {
      // Size 4 shapes (classic Tetris shapes) - 35% chance
      return size4Shapes[rng.nextInt(size4Shapes.length)];
    } else if (roll < 0.77) {
      // Size 5 shapes - 12% chance
      return size5Shapes[rng.nextInt(size5Shapes.length)];
    } else if (roll < 0.89) {
      // Size 6 shapes - 12% chance
      return size6Shapes[rng.nextInt(size6Shapes.length)];
    } else if (roll < 0.96) {
      // Size 8 shapes - 7% chance
      return size8Shapes[rng.nextInt(size8Shapes.length)];
    } else {
      // Size 9 shapes - 4% chance
      return size9Shapes[rng.nextInt(size9Shapes.length)];
    }
  }

  // Get a random shape filtered by max cell size
  static List<Vector2> getRandomShapeFiltered({int maxSize = 9}) {
    final rng = Random();
    while (true) {
      final double roll = rng.nextDouble();
      List<Vector2> shape;
      if (roll < 0.30) {
        shape = smallShapes[rng.nextInt(smallShapes.length)];
      } else if (roll < 0.65) {
        shape = size4Shapes[rng.nextInt(size4Shapes.length)];
      } else if (roll < 0.77) {
        shape = size5Shapes[rng.nextInt(size5Shapes.length)];
      } else if (roll < 0.89) {
        shape = size6Shapes[rng.nextInt(size6Shapes.length)];
      } else if (roll < 0.96) {
        shape = size8Shapes[rng.nextInt(size8Shapes.length)];
      } else {
        shape = size9Shapes[rng.nextInt(size9Shapes.length)];
      }
      if (shape.length <= maxSize) {
        return shape;
      }
    }
  }
}
