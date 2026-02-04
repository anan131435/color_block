import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config.dart';

class GridBoard extends PositionComponent {
  late List<List<Color?>> gridState;

  GridBoard({super.position, super.size}) {
    gridState = List.generate(
      GameConfigFile.gridRows,
      (_) => List.filled(GameConfigFile.gridCols, null),
    );
  }

  void clear() {
    for (int r = 0; r < GameConfigFile.gridRows; r++) {
      for (int c = 0; c < GameConfigFile.gridCols; c++) {
        gridState[r][c] = null;
      }
    }
  }

  double get cellWidth => width / GameConfigFile.gridCols;
  double get cellHeight => height / GameConfigFile.gridRows;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int r = 0; r < GameConfigFile.gridRows; r++) {
      for (int c = 0; c < GameConfigFile.gridCols; c++) {
        final rect = Rect.fromLTWH(
          c * cellWidth,
          r * cellHeight,
          cellWidth,
          cellHeight,
        );

        // Draw background cell
        paint.color = const Color(0xFF2C2C2C); // Dark grey per aesthetics
        canvas.drawRect(rect.deflate(2), paint); // deflate for spacing

        // Draw occupied cell
        if (gridState[r][c] != null) {
          paint.color = gridState[r][c]!;
          // Make filled blocks look a bit nicer?
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(4)),
            paint,
          );
        } else {
          // Draw empty placeholder style if needed
          // Currently just the dark grey bg
        }
      }
    }
  }

  bool canPlace(List<Vector2> shape, Vector2 gridPos) {
    int startCol = gridPos.x.toInt();
    int startRow = gridPos.y.toInt();

    for (var point in shape) {
      int c = startCol + point.x.toInt();
      int r = startRow + point.y.toInt();

      if (c < 0 ||
          c >= GameConfigFile.gridCols ||
          r < 0 ||
          r >= GameConfigFile.gridRows) {
        return false;
      }
      if (gridState[r][c] != null) {
        return false;
      }
    }
    return true;
  }

  // Returns score or handling of clearing separately
  int place(List<Vector2> shape, Vector2 gridPos, Color color) {
    int startCol = gridPos.x.toInt();
    int startRow = gridPos.y.toInt();

    // Place
    for (var point in shape) {
      int c = startCol + point.x.toInt();
      int r = startRow + point.y.toInt();
      gridState[r][c] = color;
    }

    // Check Lines
    return checkLines();
  }

  int checkLines() {
    List<int> rowsToClear = [];
    List<int> colsToClear = [];

    // Check Rows
    for (int r = 0; r < GameConfigFile.gridRows; r++) {
      if (gridState[r].every((c) => c != null)) {
        rowsToClear.add(r);
      }
    }

    // Check Cols
    for (int c = 0; c < GameConfigFile.gridCols; c++) {
      bool full = true;
      for (int r = 0; r < GameConfigFile.gridRows; r++) {
        if (gridState[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) colsToClear.add(c);
    }

    if (rowsToClear.isEmpty && colsToClear.isEmpty) {
      return 10; // Just placement score
    }

    // Clear Logic
    for (int r in rowsToClear) {
      for (int c = 0; c < GameConfigFile.gridCols; c++) {
        gridState[r][c] = null; // Visual cleanup needed? Animations?
      }
    }
    for (int c in colsToClear) {
      for (int r = 0; r < GameConfigFile.gridRows; r++) {
        gridState[r][c] = null;
      }
    }

    // Calculate Score: 100 per line + bonus
    int totalLines = rowsToClear.length + colsToClear.length;
    int score = 10 + (totalLines * 100);
    if (totalLines > 1) {
      score += (totalLines - 1) * 50; // Bonus
    }

    return score;
  }
}
