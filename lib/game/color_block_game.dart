import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'config.dart';
import '../storage/prefs_manager.dart';
import 'components/grid_board.dart';
import 'components/draggable_block.dart';
import 'components/feedback_text_effect.dart';
import 'components/heart_score.dart';
import 'adaptive_shape_generator.dart';

class ColorBlockGame extends FlameGame {
  final bool isJourneyMode;
  late GridBoard gridBoard;
  final List<DraggableBlock> activeBlocks = [];

  // Adaptive shape generator (used for the first kAdaptiveRounds placements)
  final AdaptiveShapeGenerator _shapeGenerator = AdaptiveShapeGenerator();

  ColorBlockGame({this.isJourneyMode = false});

  // Score
  int score = 0;
  // High Score
  int highScore = 0;
  int _startHighScore = 0;
  bool isNewRecord = false;
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
  late AudioPool goodPool;
  late AudioPool greatPool;
  late AudioPool excellentPool;
  late AudioPool comboPool;
  late AudioPool failPool;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Initialize Audio
    FlameAudio.audioCache.prefix = 'assets/sound/';

    // Create pools for low-latency sound effects
    clickPool = await FlameAudio.createPool('click.mp3', maxPlayers: 4);
    swipPool = await FlameAudio.createPool('swip.wav', maxPlayers: 4);
    clearPool = await FlameAudio.createPool('clear_oneline.wav', maxPlayers: 4);
    goodPool = await FlameAudio.createPool('good.mp3', maxPlayers: 2);
    greatPool = await FlameAudio.createPool('great.mp3', maxPlayers: 2);
    excellentPool = await FlameAudio.createPool('excellent.mp3', maxPlayers: 2);
    comboPool = await FlameAudio.createPool('comob.mp3', maxPlayers: 2);
    failPool = await FlameAudio.createPool('failed_game.wav', maxPlayers: 1);

    // Update Streak
    await PrefsManager.updateStreak();

    // Load High Score and display
    highScore = await PrefsManager.getHighScore();
    _startHighScore = highScore;
    highScoreText = TextComponent(
      text: '🏆 $highScore',
      position: Vector2(20, 40),
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

    // Add Score (Current Game) with a beating heart background
    final heartScore = HeartScoreComponent(
      position: Vector2(gameWidth / 2, 110),
    );
    add(heartScore);
    scoreText = TextComponent(text: '0');

    // Calculate Grid Size and Position dynamically to prevent overlapping with scores/bottom blocks.
    double topPadding = 145.0; // Space for high score (y=40) and current score (y=90) plus padding
    double bottomPadding = 165.0; // Space for candidate blocks pool at bottom
    double availableHeight = max(200.0, gameHeight - topPadding - bottomPadding);
    
    // Scale board size to fit available space comfortably
    double gridScreenSize = min(gameWidth * 0.9, availableHeight);
    
    // Center the board in the available vertical space
    double boardCenterY = topPadding + (availableHeight / 2);
    
    gridBoard = GridBoard(
      size: Vector2.all(gridScreenSize),
      position: Vector2(
        gameWidth / 2,
        boardCenterY,
      ),
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
    activeBlocks.clear();

    // Slot positions at the bottom
    double poolY = gridBoard.position.y + gridBoard.height / 2 + 30;
    double slotWidth = gameWidth / 3;
    final rng = Random();

    // -----------------------------------------------------------------------
    // Phase 1 (placements 0-19): ADAPTIVE mode
    //   The AdaptiveShapeGenerator analyses the current board and synthesises
    //   shapes that fit open regions, complete near-full lines, and are always
    //   immediately placeable.  Shapes are not limited to the fixed enum list.
    //
    // Phase 2 (placements 20+): CLASSIC weighted-random mode
    //   Reverts to the original difficulty-scaled random selection.
    // -----------------------------------------------------------------------

    List<List<Vector2>> selectedShapes;

    if (placementCount < AdaptiveShapeGenerator.kAdaptiveRounds) {
      // --- Adaptive phase ---
      selectedShapes = _shapeGenerator.generate(gridBoard.gridState, placementCount);

      // Safety: if generator returned fewer than 3 shapes, pad with easy ones
      while (selectedShapes.length < 3) {
        selectedShapes.add([Vector2(0, 0), Vector2(1, 0)]);
      }
    } else {
      // --- Classic weighted-random phase ---
      // Calculate board fullness
      int filled = 0;
      for (int r = 0; r < GameConfigFile.gridRows; r++) {
        for (int c = 0; c < GameConfigFile.gridCols; c++) {
          if (gridBoard.gridState[r][c] != null) filled++;
        }
      }

      // Classify shapes by difficulty
      final List<int> easyIndices   = [0, 1, 2, 22, 23, 24, 25, 26, 27];
      final List<int> mediumIndices = [3, 4, 5, 6, 7, 8, 9, 10, 14, 15, 16, 17, 28, 29];
      final List<int> hardIndices   = [11, 12, 13, 18, 19, 20, 21];

      List<Vector2> selectRandomShape() {
        double easyProb;
        double medProb;
        if (filled > 38) {
          easyProb = 1.0; medProb = 0.0;
        } else if (filled > 25) {
          easyProb = 0.65; medProb = 0.30;
        } else {
          easyProb = 0.40; medProb = 0.45;
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

      bool canShapeBePlaced(List<Vector2> shape) {
        for (int r = 0; r < GameConfigFile.gridRows; r++) {
          for (int c = 0; c < GameConfigFile.gridCols; c++) {
            if (gridBoard.canPlace(shape, Vector2(c.toDouble(), r.toDouble()))) return true;
          }
        }
        return false;
      }

      selectedShapes = [];
      bool hasPlaceable = false;
      int attempts = 0;
      while (!hasPlaceable && attempts < 20) {
        selectedShapes.clear();
        hasPlaceable = false;
        for (int i = 0; i < 3; i++) {
          var shp = selectRandomShape();
          selectedShapes.add(shp);
          if (canShapeBePlaced(shp)) hasPlaceable = true;
        }
        attempts++;
      }

      if (!hasPlaceable) {
        bool hasEmptyCell = false;
        for (int r = 0; r < GameConfigFile.gridRows && !hasEmptyCell; r++) {
          for (int c = 0; c < GameConfigFile.gridCols && !hasEmptyCell; c++) {
            if (gridBoard.gridState[r][c] == null) hasEmptyCell = true;
          }
        }
        if (hasEmptyCell && selectedShapes.isNotEmpty) {
          selectedShapes[2] = GameConfigFile.shapes[0]; // Force 1x1
        }
      }
    }

    // Spawn the selected shapes into the pool slots
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
        int linesCleared = 0;
        if (points == 110) linesCleared = 1;
        else if (points == 260) linesCleared = 2;
        else if (points == 410) linesCleared = 3;
        else if (points == 560) linesCleared = 4;
        
        if (linesCleared > 0) {
          _triggerVibrations(linesCleared);
        } else {
          HapticFeedback.vibrate();
        }
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
    // The rolling score inside HeartScoreComponent will catch up automatically
    if (score > highScore) {
      highScore = score;
      highScoreText.text = '🏆 $highScore';
      PrefsManager.saveHighScore(score);
      if (score > _startHighScore && score > 0) {
        isNewRecord = true;
      }
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
      failPool.start();
      if (isNewRecord) {
        overlays.add('NewRecord');
      } else {
        overlays.add('GameOver');
      }
    }
  }

  Future<void> _playClearSequence(int points) async {
    try {
      clearPool.start();
      
      // Calculate lines cleared based on score points
      int linesCleared = 0;
      if (points == 110) linesCleared = 1;
      else if (points == 260) linesCleared = 2;
      else if (points == 410) linesCleared = 3;
      else if (points == 560) linesCleared = 4;

      if (linesCleared == 0) return;

      // Calculate screen center at the board for visual pop-up
      final Vector2 textPos = gridBoard.position;

      // Play combo sound if consecutive turns are cleared
      if (comboCount >= 2) {
        // combo X 1 (comboCount==2) -> 0.4 volume
        // combo X 2 (comboCount==3) -> 0.7 volume
        // combo X 3+ (comboCount>=4) -> 1.0 volume
        double comboVolume = 0.5;
        if (comboCount == 3) {
          comboVolume = 0.8;
        } else if (comboCount >= 4) {
          comboVolume = 1.0;
        }
        comboPool.start(volume: comboVolume);

        add(FeedbackTextEffect(
          text: 'COMBO x$comboCount!',
          textColor: const Color(0xFF00E5FF), // Cyan for combos
          position: textPos,
        ));
      } else {
        // Play multiclear sounds for single placements (volume kept consistent at 0.2, one level lower than combo X 1)
        if (linesCleared == 1) {
          goodPool.start(volume: 0.5);
          add(FeedbackTextEffect(
            text: 'GOOD!',
            textColor: const Color(0xFF00E676), // Vibrant green
            position: textPos,
          ));
        } else if (linesCleared == 2) {
          greatPool.start(volume: 0.5);
          add(FeedbackTextEffect(
            text: 'GREAT!',
            textColor: const Color(0xFFFFEB3B), // Yellow like "COLOR" on home page
            position: textPos,
          ));
        } else if (linesCleared >= 3) {
          excellentPool.start(volume: 0.5);
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

  Future<void> _triggerVibrations(int linesCleared) async {
    final int count = min(linesCleared, 3); // Capped at 3 vibrations
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        // iOS heavyImpact is very short, so 280ms is perfect for distinct taps.
        // Android standard vibrate is longer, so we need 450ms to avoid overlapping.
        final int delayMs = isIOS ? 280 : 450;
        await Future.delayed(Duration(milliseconds: delayMs));
      }
      
      if (isIOS) {
        await HapticFeedback.heavyImpact();
      } else {
        await HapticFeedback.vibrate();
      }
    }
  }

  void reset() {
    score = 0;
    // The rolling score inside HeartScoreComponent will reset automatically
    comboCount = 0; // Reset turn-by-turn combo
    placementCount = 0; // Reset placement counter
    isNewRecord = false;
    if (overlays.isActive('GameOver')) overlays.remove('GameOver');
    if (overlays.isActive('NewRecord')) overlays.remove('NewRecord');
    // Refresh high score just in case
    PrefsManager.getHighScore().then((val) {
      highScore = val;
      _startHighScore = val;
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
