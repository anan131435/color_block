import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config.dart';
import '../storage/prefs_manager.dart';
import 'components/grid_board.dart';
import 'components/draggable_block.dart';
import 'components/feedback_text_effect.dart';

class ColorBlockGame extends FlameGame {
  final bool isJourneyMode;
  late GridBoard gridBoard;
  final List<DraggableBlock> activeBlocks = [];

  ColorBlockGame({this.isJourneyMode = false});

  // Score
  // Score
  int score = 0;
  // High Score
  int highScore = 0;
  int comboCount = 0;
  int placementCount = 0;

  late TextComponent scoreText;
  late TextComponent highScoreText;

  // Layout
  double get gameWidth => size.x;
  double get gameHeight => size.y;

  @override
  Color backgroundColor() => const Color(0xFF304797);

  late AudioPool clickPool;
  late AudioPool swipPool;
  late AudioPool clearPool;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Initialize Audio
    FlameAudio.audioCache.prefix = 'assets/sound/';

    // Create pools for low-latency sound effects
    clickPool = await FlameAudio.createPool('click.mp3', maxPlayers: 4);
    swipPool = await FlameAudio.createPool('swip.wav', maxPlayers: 4);
    clearPool = await FlameAudio.createPool('clear_oneline.wav', maxPlayers: 4);
    await FlameAudio.audioCache.loadAll([
      'failed_game.wav',
      'clear_oneline.wav',
      'good.mp3',
      'great.mp3',
      'excellent.mp3',
      'comob.mp3',
    ]);

    // Update Streak
    await PrefsManager.updateStreak();

    // Load High Score and display
    highScore = await PrefsManager.getHighScore();
    highScoreText = TextComponent(
      text: '🏆 $highScore',
      position: Vector2(20, 50),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE6B73F),
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'Noto Color Emoji', // Fallback
        ),
      ),
    );
    add(highScoreText);

    // Add Score (Current Game)
    scoreText = TextComponent(
      text: '0',
      position: Vector2(gameWidth / 2, 100),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);

    // Calculate Grid Size
    // Max width 90% of screen, but need vertical space too.
    double gridScreenSize = min(gameWidth * 0.9, gameHeight * 0.6);
    gridBoard = GridBoard(
      size: Vector2.all(gridScreenSize),
      position: Vector2(
        gameWidth / 2,
        gameHeight / 2 - 50,
      ), // Center slightly shifted up
    )..anchor = Anchor.center;

    add(gridBoard);

    if (isJourneyMode) {
      preFillGrid();
    }

    // Spawn initial blocks
    spawnBlocks();

    // Add "RELAXING" text component at the bottom margin of the screen
    // double relaxingY = gameHeight - 60;
    // Safety check: ensure it doesn't overlap the candidate blocks pool if the screen is very short.
    // The candidate blocks are spawned centered at poolY + 50, with a max visual size bounded to cellSize * 2.2.
    // So the pool bottom bounds are roughly poolY + 50 + gridBoard.cellWidth * 1.1.
    // double poolY = gridBoard.position.y + gridBoard.height / 2 + 30;
    // double poolBottom = poolY + 50 + gridBoard.cellWidth * 1.1;
    // if (relaxingY < poolBottom + 30) {
    //   relaxingY = poolBottom + 30; // Safety padding fallback
    // }

    // add(RelaxingText(
    //   position: Vector2(gameWidth / 2, relaxingY),
    // ));
  }

  void preFillGrid() {
    final rng = Random();
    // Pre-fill about 15-20 random cells
    int cellsToFill = 15 + rng.nextInt(6);
    for (int i = 0; i < cellsToFill; i++) {
      int r = rng.nextInt(GameConfigFile.gridRows);
      int c = rng.nextInt(GameConfigFile.gridCols);
      if (gridBoard.gridState[r][c] == null) {
        gridBoard.gridState[r][c] = GameConfigFile
            .blockColors[rng.nextInt(GameConfigFile.blockColors.length)];
      }
    }
  }

  void spawnBlocks() {
    // Clear list
    activeBlocks.clear(); // Components remove themselves on place

    // We need 3 slots at the bottom
    double poolY = gridBoard.position.y + gridBoard.height / 2 + 30;
    double slotWidth = gameWidth / 3;

    // 1. Calculate board fullness
    int filled = 0;
    for (int r = 0; r < GameConfigFile.gridRows; r++) {
      for (int c = 0; c < GameConfigFile.gridCols; c++) {
        if (gridBoard.gridState[r][c] != null) {
          filled++;
        }
      }
    }

    // Classify shapes by difficulty
    final List<int> easyIndices = [0, 1, 2, 22, 23, 24, 25, 26, 27];
    final List<int> mediumIndices = [3, 4, 5, 6, 7, 8, 9, 10, 14, 15, 16, 17, 28, 29];
    final List<int> hardIndices = [11, 12, 13, 18, 19, 20, 21];

    final rng = Random();

    // Calculate recommended shape indices if placementCount < 60
    List<int> recommendedIndices = [];
    if (placementCount < 60) {
      // 1. Gather all empty cell positions in rows/columns close to clearing (5 to 7 filled)
      List<Vector2> targetEmptyCells = [];
      
      // Scan rows
      for (int r = 0; r < GameConfigFile.gridRows; r++) {
        int filledInRow = 0;
        for (int c = 0; c < GameConfigFile.gridCols; c++) {
          if (gridBoard.gridState[r][c] != null) {
            filledInRow++;
          }
        }
        if (filledInRow >= 5 && filledInRow <= 7) {
          for (int c = 0; c < GameConfigFile.gridCols; c++) {
            if (gridBoard.gridState[r][c] == null) {
              targetEmptyCells.add(Vector2(c.toDouble(), r.toDouble()));
            }
          }
        }
      }

      // Scan columns
      for (int c = 0; c < GameConfigFile.gridCols; c++) {
        int filledInCol = 0;
        for (int r = 0; r < GameConfigFile.gridRows; r++) {
          if (gridBoard.gridState[r][c] != null) {
            filledInCol++;
          }
        }
        if (filledInCol >= 5 && filledInCol <= 7) {
          for (int r = 0; r < GameConfigFile.gridRows; r++) {
            if (gridBoard.gridState[r][c] == null) {
              Vector2 cell = Vector2(c.toDouble(), r.toDouble());
              if (!targetEmptyCells.any((v) => v.x == cell.x && v.y == cell.y)) {
                targetEmptyCells.add(cell);
              }
            }
          }
        }
      }

      // 2. Scan which satisfying placeable shapes can cover at least one target empty cell
      // We search over popular, satisfying medium/large shapes (excluding 1x1 to keep it interesting)
      final List<int> candidateSearchIndices = [
        1, 2, 3, 4, 5, 6, 7, 8, 14, 15, 16, 17, 22, 23, 24, 25
      ];

      if (targetEmptyCells.isNotEmpty) {
        for (int shapeIdx in candidateSearchIndices) {
          var shape = GameConfigFile.shapes[shapeIdx];
          bool isUseful = false;
          
          // Test all positions on the grid
          for (int r = 0; r < GameConfigFile.gridRows; r++) {
            for (int c = 0; c < GameConfigFile.gridCols; c++) {
              Vector2 pos = Vector2(c.toDouble(), r.toDouble());
              if (gridBoard.canPlace(shape, pos)) {
                // Check if this placement covers any of the targeted empty cells
                for (var offset in shape) {
                  double targetX = pos.x + offset.x;
                  double targetY = pos.y + offset.y;
                  if (targetEmptyCells.any((v) => v.x == targetX && v.y == targetY)) {
                    isUseful = true;
                    break;
                  }
                }
              }
              if (isUseful) break;
            }
            if (isUseful) break;
          }
          
          if (isUseful) {
            recommendedIndices.add(shapeIdx);
          }
        }
      }

      // If recommendedIndices is empty (e.g. at the start of the game),
      // pre-populate with nice, easy-to-use shapes (no 1x1, to avoid triviality)
      if (recommendedIndices.isEmpty) {
        recommendedIndices.addAll([1, 2, 5, 6, 7, 8, 22, 23, 24, 25]);
      }
    }

    // Weighted selector
    List<Vector2> selectRandomShape() {
      // If we have recommended shapes and are in the first 60 placements,
      // choose from them with 70% probability to help players clear lines.
      if (placementCount < 60 && recommendedIndices.isNotEmpty && rng.nextDouble() < 0.70) {
        int shapeIndex = recommendedIndices[rng.nextInt(recommendedIndices.length)];
        return GameConfigFile.shapes[shapeIndex];
      }

      double easyProb;
      double medProb;
      
      if (filled > 38) { // >60% filled: Rescue Mode (only easy blocks)
        easyProb = 1.0;
        medProb = 0.0;
      } else if (filled > 25) { // 40%-60% filled: Normal Mode
        easyProb = 0.65;
        medProb = 0.30;
      } else { // <40% filled: Challenging Mode
        easyProb = 0.40;
        medProb = 0.45;
      }

      double rand = rng.nextDouble();
      int shapeIndex;
      if (rand < easyProb) {
        shapeIndex = easyIndices[rng.nextInt(easyIndices.length)];
      } else if (rand < easyProb + medProb) {
        shapeIndex = mediumIndices[rng.nextInt(mediumIndices.length)];
      } else {
        shapeIndex = hardIndices[rng.nextInt(hardIndices.length)];
      }
      return GameConfigFile.shapes[shapeIndex];
    }

    // Helper to check if a shape can be placed anywhere
    bool canShapeBePlaced(List<Vector2> shape) {
      for (int r = 0; r < GameConfigFile.gridRows; r++) {
        for (int c = 0; c < GameConfigFile.gridCols; c++) {
          if (gridBoard.canPlace(shape, Vector2(c.toDouble(), r.toDouble()))) {
            return true;
          }
        }
      }
      return false;
    }

    // 2. Select 3 shapes and guarantee at least one is placeable
    List<List<Vector2>> selectedShapes = [];
    bool hasPlaceable = false;
    int attempts = 0;

    while (!hasPlaceable && attempts < 20) {
      selectedShapes.clear();
      hasPlaceable = false;
      for (int i = 0; i < 3; i++) {
        var shp = selectRandomShape();
        selectedShapes.add(shp);
        if (canShapeBePlaced(shp)) {
          hasPlaceable = true;
        }
      }
      attempts++;
    }

    // If still not placeable after 20 attempts, force the third shape to be 1x1
    if (!hasPlaceable) {
      bool hasEmptyCell = false;
      for (int r = 0; r < GameConfigFile.gridRows; r++) {
        for (int c = 0; c < GameConfigFile.gridCols; c++) {
          if (gridBoard.gridState[r][c] == null) {
            hasEmptyCell = true;
            break;
          }
        }
        if (hasEmptyCell) break;
      }
      if (hasEmptyCell && selectedShapes.isNotEmpty) {
        selectedShapes[2] = GameConfigFile.shapes[0]; // Force 1x1
      }
    }

    // 3. Spawn the selected shapes
    for (int i = 0; i < 3; i++) {
      var color = GameConfigFile.blockColors[rng.nextInt(GameConfigFile.blockColors.length)];
      Vector2 spawnPos = Vector2(slotWidth * i + slotWidth / 2, poolY + 50);

      var block = DraggableBlock(
        shapeOffsets: selectedShapes[i],
        color: color,
        cellSize: gridBoard.cellWidth,
        originalPosition: spawnPos,
        onPlace: () {
          checkEndGame();
        },
      );
      block.position = spawnPos;
      add(block);
      activeBlocks.add(block);
    }
  }

  // Called by block when dropped
  bool attemptPlacement(DraggableBlock block) {
    // convert block top-left to grid space
    // Block anchor is Center.
    // Grid anchor is Center.

    // Absolute positions
    Vector2 blockTopLeft = block.absolutePosition - (block.size / 2);
    Vector2 gridTopLeft = gridBoard.absolutePosition - (gridBoard.size / 2);

    Vector2 relativePos = blockTopLeft - gridTopLeft;

    // Calculate potential grid index
    // We use a lenient snap: round to nearest cell
    int col = (relativePos.x / gridBoard.cellWidth).round();
    int row = (relativePos.y / gridBoard.cellHeight).round();

    Vector2 gridIndex = Vector2(col.toDouble(), row.toDouble());

    if (gridBoard.canPlace(block.shapeOffsets, gridIndex)) {
      int points = gridBoard.place(block.shapeOffsets, gridIndex, block.color);
      clickPool.start();

      // Update turn-by-turn combo count
      if (points > 10) {
        comboCount++;
      } else {
        comboCount = 0;
      }

      addScore(points);

      // Trigger vibration feedback and play audio sequence
      if (points > 10) {
        // Clear lines (Score is 10 + totalLines * 100 + bonus)
        HapticFeedback.vibrate();
        _playClearSequence(points);
      } else {
        // Just place block (Score is 10)
        HapticFeedback.heavyImpact();
      }

      // Remove from active list
      activeBlocks.remove(block);
      placementCount++;

      if (activeBlocks.isEmpty) {
        spawnBlocks();
      } else {
        checkEndGame(); // Check if remaining blocks can be placed?
        // Actually PRD says: "Loss: when all 3 blocks cannot be placed".
        // Wait, "When bottom 3 blocks CANNOT be put into board".
        // Usually checked after every move.
      }
      return true;
    }
    return false;
  }

  void addScore(int points) {
    score += points;
    scoreText.text = '$score';
    if (score > highScore) {
      highScore = score;
      highScoreText.text = '🏆 $highScore';
      PrefsManager.saveHighScore(score);
    }
  }

  void updatePreview(DraggableBlock block) {
    // Similar logic to attemptPlacement to find grid position
    Vector2 blockTopLeft = block.absolutePosition - (block.size / 2);
    Vector2 gridTopLeft = gridBoard.absolutePosition - (gridBoard.size / 2);
    Vector2 relativePos = blockTopLeft - gridTopLeft;

    int col = (relativePos.x / gridBoard.cellWidth).round();
    int row = (relativePos.y / gridBoard.cellHeight).round();
    Vector2 gridIndex = Vector2(col.toDouble(), row.toDouble());

    gridBoard.showPreview(block.shapeOffsets, gridIndex, block.color);
  }

  void clearPreview() {
    gridBoard.clearPreview();
  }

  void checkEndGame() {
    // If activeBlocks is empty, we just spawned/will spawn.
    if (activeBlocks.isEmpty) return;

    // Check if ANY of the active blocks can be placed ANYWHERE.
    bool canMove = false;

    for (var block in activeBlocks) {
      // Brute force check grid
      for (int r = 0; r < GameConfigFile.gridRows; r++) {
        for (int c = 0; c < GameConfigFile.gridCols; c++) {
          if (gridBoard.canPlace(
            block.shapeOffsets,
            Vector2(c.toDouble(), r.toDouble()),
          )) {
            canMove = true;
            break;
          }
        }
        if (canMove) break;
      }
      if (canMove) break;
    }

    if (!canMove) {
      // Game Over
      FlameAudio.play('failed_game.wav');
      overlays.add('GameOver');
    }
  }

  Future<void> _playClearSequence(int points) async {
    try {
      FlameAudio.play('clear_oneline.wav');
      
      // Calculate lines cleared based on score points
      int linesCleared = 0;
      if (points == 110) linesCleared = 1;
      else if (points == 260) linesCleared = 2;
      else if (points == 410) linesCleared = 3;
      else if (points == 560) linesCleared = 4;

      if (linesCleared == 0) return;

      // Calculate screen center above the board for visual pop-up
      final Vector2 textPos = Vector2(gameWidth / 2, gameHeight / 2 - 50);

      // Play combo sound if consecutive turns are cleared
      if (comboCount >= 2) {
        // FlameAudio.play('comob.mp3');
        add(FeedbackTextEffect(
          text: 'COMBO x$comboCount!',
          textColor: const Color(0xFF00E5FF), // Cyan for combos
          position: textPos,
        ));
      } else {
        // Play multiclear sounds for single placements
        if (linesCleared == 1) {
          FlameAudio.play('good.mp3');
          add(FeedbackTextEffect(
            text: 'GOOD!',
            textColor: const Color(0xFF00E676), // Vibrant green
            position: textPos,
          ));
        } else if (linesCleared == 2) {
          FlameAudio.play('great.mp3');
          add(FeedbackTextEffect(
            text: 'GREAT!',
            textColor: const Color(0xFFFFEB3B), // Yellow like "COLOR" on home page
            position: textPos,
          ));
        } else if (linesCleared >= 3) {
          FlameAudio.play('excellent.mp3');
          add(FeedbackTextEffect(
            text: 'EXCELLENT!!',
            textColor: const Color(0xFFFF5722), // Orange/Red like "BLOCK" on home page
            position: textPos,
          ));
        }
      }
    } catch (e) {
      print('Error playing clear sound sequence: $e');
    }
  }

  void reset() {
    score = 0;
    scoreText.text = '0';
    comboCount = 0; // Reset turn-by-turn combo
    placementCount = 0; // Reset placement counter
    // Refresh high score just in case
    PrefsManager.getHighScore().then((val) {
      highScore = val;
      highScoreText.text = '🏆 $highScore';
    });
    gridBoard.clear();
    if (isJourneyMode) {
      preFillGrid();
    }
    PrefsManager.updateStreak();

    // Remove existing draggable blocks
    // We iterate backwards or make a copy to avoid modification issues
    for (final child in children.toList()) {
      if (child is DraggableBlock) {
        child.removeFromParent();
      }
    }

    spawnBlocks();
  }
}
