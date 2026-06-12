import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'config.dart';

/// Adaptive Shape Generator
///
/// For the first [kAdaptiveRounds] placements, dynamically generates shapes
/// that match open regions on the board, making the early game accessible
/// and rewarding.  After that, normal random selection resumes.
class AdaptiveShapeGenerator {
  static const int kAdaptiveRounds = 20;

  final Random _rng;

  AdaptiveShapeGenerator({Random? rng}) : _rng = rng ?? Random();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Generate 3 shapes adapted to [gridState].
  /// [placementCount] is the number of blocks placed so far.
  List<List<Vector2>> generate(
    List<List<Color?>> gridState,
    int placementCount,
  ) {
    if (placementCount >= kAdaptiveRounds) {
      return _fallbackShapes(gridState);
    }

    final results = <List<Vector2>>[];

    // 1. Find all line-clearing shapes (prioritizing 3-line clears, then 2-line clears)
    final lineClearingCandidates = _findLineClearingCandidates(gridState);
    
    // Sort so that highest clearedCount is first
    lineClearingCandidates.sort((a, b) => b.clearedCount.compareTo(a.clearedCount));

    // Deduplicate line clearing candidates by shape to avoid identical shapes in the same turn
    final seenShapes = <String>{};
    final uniqueLineClearingCandidates = <_LineClearingCandidate>[];
    for (final cand in lineClearingCandidates) {
      final sorted = [...cand.shape]
        ..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
      final key = sorted.map((v) => '${v.x.toInt()},${v.y.toInt()}').join('|');
      if (seenShapes.add(key)) {
        uniqueLineClearingCandidates.add(cand);
      }
    }

    // 2. Analyse the board and build the standard candidate pool
    final analysis = _analyseBoard(gridState);
    final candidates = _buildCandidatePool(gridState, analysis);

    // 3. Select the 3 shapes
    int lineClearIdx = 0;
    for (int i = 0; i < 3; i++) {
      if (lineClearIdx < uniqueLineClearingCandidates.length) {
        final candidate = uniqueLineClearingCandidates[lineClearIdx++];
        results.add(candidate.shape);
      } else {
        // Fall back to picking from the general candidate pool
        final shape = _pickShape(candidates, gridState, guaranteePlace: i == 0 || results.isEmpty);
        results.add(shape);
      }
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // Board analysis
  // ---------------------------------------------------------------------------

  _BoardAnalysis _analyseBoard(List<List<Color?>> g) {
    final int rows = GameConfigFile.gridRows;
    final int cols = GameConfigFile.gridCols;

    // Row / column fill counts
    final rowFill = List<int>.filled(rows, 0);
    final colFill = List<int>.filled(cols, 0);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (g[r][c] != null) {
          rowFill[r]++;
          colFill[c]++;
        }
      }
    }

    // Find contiguous empty regions using flood-fill
    final visited = List.generate(rows, (_) => List<bool>.filled(cols, false));
    final regions = <_EmptyRegion>[];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (g[r][c] == null && !visited[r][c]) {
          final cells = <_Cell>[];
          _floodFill(g, visited, r, c, cells, rows, cols);
          regions.add(_EmptyRegion(cells));
        }
      }
    }

    // Sort regions by size (largest first – these are the most valuable targets)
    regions.sort((a, b) => b.cells.length.compareTo(a.cells.length));

    // Identify "almost complete" rows/cols (≥ 5 of 8 filled)
    final nearCompleteRows = <int>[];
    final nearCompleteCols = <int>[];
    for (int r = 0; r < rows; r++) {
      if (rowFill[r] >= 5) nearCompleteRows.add(r);
    }
    for (int c = 0; c < cols; c++) {
      if (colFill[c] >= 5) nearCompleteCols.add(c);
    }

    return _BoardAnalysis(
      rowFill: rowFill,
      colFill: colFill,
      regions: regions,
      nearCompleteRows: nearCompleteRows,
      nearCompleteCols: nearCompleteCols,
      totalFilled: rowFill.fold(0, (s, v) => s + v),
    );
  }

  void _floodFill(
    List<List<Color?>> g,
    List<List<bool>> visited,
    int r,
    int c,
    List<_Cell> cells,
    int rows,
    int cols,
  ) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return;
    if (visited[r][c] || g[r][c] != null) return;
    visited[r][c] = true;
    cells.add(_Cell(r, c));
    _floodFill(g, visited, r - 1, c, cells, rows, cols);
    _floodFill(g, visited, r + 1, c, cells, rows, cols);
    _floodFill(g, visited, r, c - 1, cells, rows, cols);
    _floodFill(g, visited, r, c + 1, cells, rows, cols);
  }

  // ---------------------------------------------------------------------------
  // Candidate pool construction
  // ---------------------------------------------------------------------------

  List<List<Vector2>> _buildCandidatePool(
    List<List<Color?>> g,
    _BoardAnalysis analysis,
  ) {
    final pool = <List<Vector2>>[];

    // --- Strategy A: Shapes that complete near-complete rows/cols ---
    for (final row in analysis.nearCompleteRows) {
      final missingCols = <int>[];
      for (int c = 0; c < GameConfigFile.gridCols; c++) {
        if (g[row][c] == null) missingCols.add(c);
      }
      if (missingCols.isEmpty) continue;

      // Build a shape from consecutive missing cells in the row
      final groups = _consecutiveGroups(missingCols);
      for (final group in groups) {
        final shape = group.map((c) => Vector2(c.toDouble(), 0)).toList();
        if (shape.isNotEmpty && shape.length <= 5) {
          // Normalize to origin
          final normalized = _normalizeShape(shape);
          if (_canBePlaced(normalized, g)) {
            pool.add(normalized);
            // Add it multiple times to increase probability
            if (analysis.nearCompleteRows.length >= 2) pool.add(normalized);
          }
        }
      }
    }

    for (final col in analysis.nearCompleteCols) {
      final missingRows = <int>[];
      for (int r = 0; r < GameConfigFile.gridRows; r++) {
        if (g[r][col] == null) missingRows.add(r);
      }
      if (missingRows.isEmpty) continue;

      final groups = _consecutiveGroups(missingRows);
      for (final group in groups) {
        final shape = group.map((r) => Vector2(0, r.toDouble())).toList();
        if (shape.isNotEmpty && shape.length <= 5) {
          final normalized = _normalizeShape(shape);
          if (_canBePlaced(normalized, g)) {
            pool.add(normalized);
            if (analysis.nearCompleteCols.length >= 2) pool.add(normalized);
          }
        }
      }
    }

    // --- Strategy B: Organic shapes derived from largest empty region ---
    if (analysis.regions.isNotEmpty) {
      final largest = analysis.regions.first;
      final regionShapes = _generateRegionFittingShapes(largest, g);
      pool.addAll(regionShapes);
    }

    // --- Strategy C: Small friendly shapes for the second-largest region ---
    if (analysis.regions.length > 1) {
      final second = analysis.regions[1];
      final small = _generateSmallFittingShapes(second, g);
      pool.addAll(small);
    }

    // --- Strategy D: Always include some classic easy shapes as safety net ---
    final classics = _classicEasyShapes();
    pool.addAll(classics.where((s) => _canBePlaced(s, g)));

    // Deduplicate
    return _deduplicateShapes(pool);
  }

  /// Generate shapes (2–5 cells) that fit inside [region] and can be placed
  List<List<Vector2>> _generateRegionFittingShapes(
    _EmptyRegion region,
    List<List<Color?>> g,
  ) {
    final shapes = <List<Vector2>>[];
    final cellSet = {for (var c in region.cells) '${c.row},${c.col}'};

    // Try to build rectangles and L-shapes anchored at cells in the region
    for (int attempt = 0; attempt < 12; attempt++) {
      if (region.cells.isEmpty) break;
      final anchor = region.cells[_rng.nextInt(region.cells.length)];

      // Random width and height (1–3)
      final w = 1 + _rng.nextInt(3);
      final h = 1 + _rng.nextInt(3);
      if (w == 1 && h == 1 && _rng.nextDouble() < 0.8) continue; // rarely 1x1

      final candidate = <Vector2>[];
      bool allInRegion = true;
      for (int dr = 0; dr < h; dr++) {
        for (int dc = 0; dc < w; dc++) {
          final key = '${anchor.row + dr},${anchor.col + dc}';
          if (!cellSet.contains(key)) {
            allInRegion = false;
            break;
          }
          candidate.add(Vector2(dc.toDouble(), dr.toDouble()));
        }
        if (!allInRegion) break;
      }

      if (allInRegion && candidate.length >= 2 && candidate.length <= 5) {
        final normalized = _normalizeShape(candidate);
        if (_canBePlaced(normalized, g)) {
          shapes.add(normalized);
        }
      }
    }

    // Also try L-shapes / T-shapes organically grown from region cells
    for (int attempt = 0; attempt < 8; attempt++) {
      if (region.cells.length < 3) break;
      final organic = _growOrganic(region, cellSet, 2 + _rng.nextInt(3), g);
      if (organic != null) shapes.add(organic);
    }

    return shapes;
  }

  List<List<Vector2>> _generateSmallFittingShapes(
    _EmptyRegion region,
    List<List<Color?>> g,
  ) {
    final shapes = <List<Vector2>>[];
    if (region.cells.length < 2) return shapes;

    final cellSet = {for (var c in region.cells) '${c.row},${c.col}'};
    for (int attempt = 0; attempt < 6; attempt++) {
      final organic = _growOrganic(region, cellSet, 1 + _rng.nextInt(2), g);
      if (organic != null) shapes.add(organic);
    }
    return shapes;
  }

  /// Randomly grow a connected shape within [region]
  List<Vector2>? _growOrganic(
    _EmptyRegion region,
    Set<String> cellSet,
    int targetSize,
    List<List<Color?>> g,
  ) {
    if (region.cells.isEmpty) return null;
    final start = region.cells[_rng.nextInt(region.cells.length)];
    final chosen = <_Cell>[start];
    final frontier = <_Cell>[start];

    while (chosen.length < targetSize + 1 && frontier.isNotEmpty) {
      final cur = frontier[_rng.nextInt(frontier.length)];
      final directions = [
        _Cell(cur.row - 1, cur.col),
        _Cell(cur.row + 1, cur.col),
        _Cell(cur.row, cur.col - 1),
        _Cell(cur.row, cur.col + 1),
      ]..shuffle(_rng);

      bool added = false;
      for (final n in directions) {
        if (cellSet.contains('${n.row},${n.col}') &&
            !chosen.any((c) => c.row == n.row && c.col == n.col)) {
          chosen.add(n);
          frontier.add(n);
          added = true;
          break;
        }
      }
      if (!added) frontier.remove(cur);
    }

    if (chosen.length < 2) return null;

    // Convert chosen cells to relative offsets
    final minRow = chosen.map((c) => c.row).reduce(min);
    final minCol = chosen.map((c) => c.col).reduce(min);
    final shape = chosen
        .map((c) => Vector2((c.col - minCol).toDouble(), (c.row - minRow).toDouble()))
        .toList();

    final normalized = _normalizeShape(shape);
    if (!_canBePlaced(normalized, g)) return null;
    return normalized;
  }

  List<List<Vector2>> _classicEasyShapes() {
    return [
      // 1x2
      [Vector2(0, 0), Vector2(1, 0)],
      [Vector2(0, 0), Vector2(0, 1)],
      // 1x3
      [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)],
      [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2)],
      // 2x2
      [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)],
      // Small L
      [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1)],
      [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1)],
      [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)],
      [Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)],
    ];
  }

  // ---------------------------------------------------------------------------
  // Shape selection
  // ---------------------------------------------------------------------------

  List<Vector2> _pickShape(
    List<List<Vector2>> candidates,
    List<List<Color?>> g, {
    bool guaranteePlace = false,
  }) {
    if (candidates.isEmpty) return _classicEasyShapes().first;

    // Shuffle and try to find a placeable shape if required
    final shuffled = [...candidates]..shuffle(_rng);

    if (guaranteePlace) {
      for (final s in shuffled) {
        if (_canBePlaced(s, g)) return s;
      }
      // Ultimate fallback: 1x1
      return [Vector2(0, 0)];
    }

    // Otherwise just pick randomly from the pool (bias toward smaller shapes
    // for the very early game when board is empty)
    return shuffled[_rng.nextInt(min(shuffled.length, 8))];
  }

  // ---------------------------------------------------------------------------
  // Fallback for non-adaptive rounds
  // ---------------------------------------------------------------------------

  List<List<Vector2>> _fallbackShapes(List<List<Color?>> g) {
    // Delegate to classic shapes from config
    final all = GameConfigFile.shapes;
    final result = <List<Vector2>>[];
    final rng = _rng;

    for (int i = 0; i < 3; i++) {
      List<Vector2> shape;
      int tries = 0;
      do {
        shape = all[rng.nextInt(all.length)];
        tries++;
      } while (!_canBePlaced(shape, g) && tries < 20);
      result.add(shape);
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  bool _canBePlaced(List<Vector2> shape, List<List<Color?>> g) {
    final rows = GameConfigFile.gridRows;
    final cols = GameConfigFile.gridCols;
    for (int sr = 0; sr < rows; sr++) {
      for (int sc = 0; sc < cols; sc++) {
        bool fits = true;
        for (final offset in shape) {
          final r = sr + offset.y.toInt();
          final c = sc + offset.x.toInt();
          if (r < 0 || r >= rows || c < 0 || c >= cols || g[r][c] != null) {
            fits = false;
            break;
          }
        }
        if (fits) return true;
      }
    }
    return false;
  }

  /// Normalize shape so min x = 0, min y = 0
  List<Vector2> _normalizeShape(List<Vector2> shape) {
    if (shape.isEmpty) return shape;
    final minX = shape.map((v) => v.x).reduce(min);
    final minY = shape.map((v) => v.y).reduce(min);
    return shape.map((v) => Vector2(v.x - minX, v.y - minY)).toList();
  }

  /// Split a sorted list of ints into groups of consecutive integers
  List<List<int>> _consecutiveGroups(List<int> sorted) {
    if (sorted.isEmpty) return [];
    final groups = <List<int>>[];
    var cur = [sorted.first];
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == sorted[i - 1] + 1) {
        cur.add(sorted[i]);
      } else {
        groups.add(cur);
        cur = [sorted[i]];
      }
    }
    groups.add(cur);
    return groups;
  }

  /// Remove duplicate shapes (same cell sets)
  List<List<Vector2>> _deduplicateShapes(List<List<Vector2>> shapes) {
    final seen = <String>{};
    final result = <List<Vector2>>[];
    for (final shape in shapes) {
      final sorted = [...shape]
        ..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
      final key = sorted.map((v) => '${v.x.toInt()},${v.y.toInt()}').join('|');
      if (seen.add(key)) result.add(shape);
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Multi-line Clearing Shape Synthesizer
  // ---------------------------------------------------------------------------

  List<_LineClearingCandidate> _findLineClearingCandidates(List<List<Color?>> g) {
    final candidates = <_LineClearingCandidate>[];
    
    // Define empty cells for each row and column
    final Map<int, List<_Cell>> lineEmptyCells = {};
    for (int r = 0; r < 8; r++) {
      lineEmptyCells[r] = [];
      for (int c = 0; c < 8; c++) {
        if (g[r][c] == null) {
          lineEmptyCells[r]!.add(_Cell(r, c));
        }
      }
    }
    for (int c = 0; c < 8; c++) {
      lineEmptyCells[c + 8] = [];
      for (int r = 0; r < 8; r++) {
        if (g[r][c] == null) {
          lineEmptyCells[c + 8]!.add(_Cell(r, c));
        }
      }
    }

    // Helper to connect target cells and return normalized shape
    List<Vector2>? connect(List<_Cell> targets) {
      final targetVectors = targets.map((c) => Vector2(c.col.toDouble(), c.row.toDouble())).toList();
      final connected = _connectCells(targetVectors, g, 5); // Max 5 cells
      if (connected == null) return null;
      return _normalizeShape(connected);
    }

    // Identify which lines are active (non-empty and not completely empty either, 
    // but having at most 5 missing blocks so they can potentially be completed)
    final List<int> activeLines = [];
    for (int i = 0; i < 16; i++) {
      final len = lineEmptyCells[i]!.length;
      if (len > 0 && len <= 5) {
        activeLines.add(i);
      }
    }

    // 1. Check all combinations of 3 lines
    for (int i = 0; i < activeLines.length; i++) {
      final l1 = activeLines[i];
      for (int j = i + 1; j < activeLines.length; j++) {
        final l2 = activeLines[j];
        for (int k = j + 1; k < activeLines.length; k++) {
          final l3 = activeLines[k];
          
          final Set<String> combinedKeys = {};
          final List<_Cell> combinedCells = [];
          for (final l in [l1, l2, l3]) {
            for (final cell in lineEmptyCells[l]!) {
              final key = '${cell.row},${cell.col}';
              if (combinedKeys.add(key)) {
                combinedCells.add(cell);
              }
            }
          }
          
          if (combinedCells.isNotEmpty && combinedCells.length <= 5) {
            final shape = connect(combinedCells);
            if (shape != null) {
              candidates.add(_LineClearingCandidate(
                shape: shape,
                clearedCount: 3,
                lines: [l1, l2, l3],
              ));
            }
          }
        }
      }
    }

    // 2. Check combinations of 2 lines
    for (int i = 0; i < activeLines.length; i++) {
      final l1 = activeLines[i];
      for (int j = i + 1; j < activeLines.length; j++) {
        final l2 = activeLines[j];
        
        final Set<String> combinedKeys = {};
        final List<_Cell> combinedCells = [];
        for (final l in [l1, l2]) {
          for (final cell in lineEmptyCells[l]!) {
            final key = '${cell.row},${cell.col}';
            if (combinedKeys.add(key)) {
              combinedCells.add(cell);
            }
          }
        }
        
        if (combinedCells.isNotEmpty && combinedCells.length <= 5) {
          final shape = connect(combinedCells);
          if (shape != null) {
            candidates.add(_LineClearingCandidate(
              shape: shape,
              clearedCount: 2,
              lines: [l1, l2],
            ));
          }
        }
      }
    }

    // 3. Check 1-line clears
    for (final l in activeLines) {
      final cells = lineEmptyCells[l]!;
      if (cells.isNotEmpty && cells.length <= 5) {
        final shape = connect(cells);
        if (shape != null) {
          candidates.add(_LineClearingCandidate(
            shape: shape,
            clearedCount: 1,
            lines: [l],
          ));
        }
      }
    }

    return candidates;
  }

  List<Vector2>? _connectCells(List<Vector2> targets, List<List<Color?>> g, int maxCells) {
    if (targets.isEmpty) return null;
    if (targets.length > maxCells) return null;
    
    final targetCells = targets.map((v) => _Cell(v.y.toInt(), v.x.toInt())).toList();
    
    if (_isConnected(targetCells)) {
      return targets;
    }
    
    final Set<String> targetKeys = targetCells.map((c) => '${c.row},${c.col}').toSet();
    List<_Cell>? bestConnection;
    int steps = 0;
    
    void search(List<_Cell> current, Set<String> visited) {
      steps++;
      if (steps > 150) return; // Prevent performance bottlenecks
      if (current.length > maxCells) return;
      
      // Check if current contains all targets
      bool containsAll = true;
      for (final t in targetKeys) {
        if (!visited.contains(t)) {
          containsAll = false;
          break;
        }
      }
      
      if (containsAll) {
        if (_isConnected(current)) {
          if (bestConnection == null || current.length < bestConnection!.length) {
            bestConnection = List.from(current);
          }
        }
        return;
      }
      
      if (current.length == maxCells) return;
      
      // Grow current: find all empty neighbors of current cells
      final Set<String> candidates = {};
      for (final cell in current) {
        final neighbors = [
          _Cell(cell.row - 1, cell.col),
          _Cell(cell.row + 1, cell.col),
          _Cell(cell.row, cell.col - 1),
          _Cell(cell.row, cell.col + 1),
        ];
        for (final n in neighbors) {
          if (n.row >= 0 && n.row < 8 && n.col >= 0 && n.col < 8 && g[n.row][n.col] == null) {
            final key = '${n.row},${n.col}';
            if (!visited.contains(key)) {
              candidates.add(key);
            }
          }
        }
      }
      
      for (final candKey in candidates) {
        final parts = candKey.split(',');
        final r = int.parse(parts[0]);
        final c = int.parse(parts[1]);
        final newCell = _Cell(r, c);
        
        current.add(newCell);
        visited.add(candKey);
        
        search(current, visited);
        
        current.removeLast();
        visited.remove(candKey);
      }
    }
    
    final startCell = targetCells.first;
    search([startCell], {'${startCell.row},${startCell.col}'});
    
    if (bestConnection != null) {
      return bestConnection!.map((c) => Vector2(c.col.toDouble(), c.row.toDouble())).toList();
    }
    
    return null;
  }

  bool _isConnected(List<_Cell> cells) {
    if (cells.isEmpty) return true;
    final Set<String> cellSet = cells.map((c) => '${c.row},${c.col}').toSet();
    final visited = <String>{};
    
    void dfs(_Cell c) {
      final key = '${c.row},${c.col}';
      if (!cellSet.contains(key) || visited.contains(key)) return;
      visited.add(key);
      dfs(_Cell(c.row - 1, c.col));
      dfs(_Cell(c.row + 1, c.col));
      dfs(_Cell(c.row, c.col - 1));
      dfs(_Cell(c.row, c.col + 1));
    }
    
    dfs(cells.first);
    return visited.length == cells.length;
  }
}

// ---------------------------------------------------------------------------
// Private data classes
// ---------------------------------------------------------------------------

class _Cell {
  final int row, col;
  const _Cell(this.row, this.col);
}

class _EmptyRegion {
  final List<_Cell> cells;
  const _EmptyRegion(this.cells);
}

class _BoardAnalysis {
  final List<int> rowFill;
  final List<int> colFill;
  final List<_EmptyRegion> regions;
  final List<int> nearCompleteRows;
  final List<int> nearCompleteCols;
  final int totalFilled;

  const _BoardAnalysis({
    required this.rowFill,
    required this.colFill,
    required this.regions,
    required this.nearCompleteRows,
    required this.nearCompleteCols,
    required this.totalFilled,
  });
}

class _LineClearingCandidate {
  final List<Vector2> shape;
  final int clearedCount;
  final List<int> lines;

  _LineClearingCandidate({
    required this.shape,
    required this.clearedCount,
    required this.lines,
  });
}
