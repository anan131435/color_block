import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Preview State
  List<Vector2>? _previewShape;
  Color? _previewColor;
  Set<int> _previewRowsToClear = {};
  Set<int> _previewColsToClear = {};

  void clearPreview() {
    _previewShape = null;
    _previewColor = null;
    _previewRowsToClear.clear();
    _previewColsToClear.clear();
  }

  void showPreview(List<Vector2> shape, Vector2 gridPos, Color color) {
    if (!canPlace(shape, gridPos)) {
      clearPreview();
      return;
    }

    int startCol = gridPos.x.toInt();
    int startRow = gridPos.y.toInt();

    // 1. Determine local preview cells
    _previewShape = [];
    _previewColor = color.withOpacity(0.5); // Semi-transparent

    for (var point in shape) {
      _previewShape!.add(
        Vector2(startCol.toDouble() + point.x, startRow.toDouble() + point.y),
      );
    }

    // 2. Simulate Lines to Clear
    _previewRowsToClear.clear();
    _previewColsToClear.clear();

    // We need to simulate the grid state with this block placed
    // 8x8 is small enough to just loop checks efficiently

    // Affected rows/cols by the new piece
    Set<int> affectedRows = {};
    Set<int> affectedCols = {};
    for (var p in _previewShape!) {
      affectedRows.add(p.y.toInt());
      affectedCols.add(p.x.toInt());
    }

    // Check Rows
    for (int r in affectedRows) {
      bool rowFull = true;
      for (int c = 0; c < GameConfigFile.gridCols; c++) {
        // Is it already filled OR is it part of the preview?
        bool isPreview = _previewShape!.any(
          (p) => p.y.toInt() == r && p.x.toInt() == c,
        );
        if (gridState[r][c] == null && !isPreview) {
          rowFull = false;
          break;
        }
      }
      if (rowFull) _previewRowsToClear.add(r);
    }

    // Check Cols
    for (int c in affectedCols) {
      bool colFull = true;
      for (int r = 0; r < GameConfigFile.gridRows; r++) {
        bool isPreview = _previewShape!.any(
          (p) => p.x.toInt() == c && p.y.toInt() == r,
        );
        if (gridState[r][c] == null && !isPreview) {
          colFull = false;
          break;
        }
      }
      if (colFull) _previewColsToClear.add(c);
    }
  }

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
        paint.color = const Color(0xFF2C2C2C);
        canvas.drawRect(rect.deflate(2), paint);

        // Draw occupied cell
        if (gridState[r][c] != null) {
          paint.color = gridState[r][c]!;
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(4)),
            paint,
          );
        }
      }
    }

    // Draw Highlights (Overlay for clearing lines)
    if (_previewRowsToClear.isNotEmpty || _previewColsToClear.isNotEmpty) {
      paint.color = Colors.white.withOpacity(0.2);
      for (int r = 0; r < GameConfigFile.gridRows; r++) {
        for (int c = 0; c < GameConfigFile.gridCols; c++) {
          if (_previewRowsToClear.contains(r) ||
              _previewColsToClear.contains(c)) {
            final rect = Rect.fromLTWH(
              c * cellWidth,
              r * cellHeight,
              cellWidth,
              cellHeight,
            );
            canvas.drawRect(rect, paint);
          }
        }
      }
    }

    // Draw Preview
    if (_previewShape != null && _previewColor != null) {
      paint.color = _previewColor!;
      for (var p in _previewShape!) {
        final rect = Rect.fromLTWH(
          p.x * cellWidth,
          p.y * cellHeight,
          cellWidth,
          cellHeight,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(4)),
          paint,
        );
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
    if (rowsToClear.isNotEmpty || colsToClear.isNotEmpty) {
      // Trigger vibration
      HapticFeedback.mediumImpact();

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
