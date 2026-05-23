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
import 'components/relaxing_text.dart';

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

    await FlameAudio.audioCache.loadAll(['failed_game.wav', 'clear_oneline.wav', 'great.mp3', 'excellent.mp3']);

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

    for (int i = 0; i < 3; i++) {
      _spawnSingleBlock(i, slotWidth, poolY);
    }
  }

  void _spawnSingleBlock(int index, double slotWidth, double poolY) {
    if (index < 0 || index >= 3) return;

    var rng = Random();
    var shape =
        GameConfigFile.shapes[rng.nextInt(GameConfigFile.shapes.length)];
    var color = GameConfigFile
        .blockColors[rng.nextInt(GameConfigFile.blockColors.length)];

    // Calculate spawn pos
    Vector2 spawnPos = Vector2(slotWidth * index + slotWidth / 2, poolY + 50);

    var block = DraggableBlock(
      shapeOffsets: shape,
      color: color,
      cellSize: gridBoard.cellWidth, // Use active grid cell size
      originalPosition: spawnPos,
      onPlace: () {
        // Find which block this was and null logic if needed
        // Assuming block removes itself from parent
        checkEndGame(); // or check refill
      },
    );
    block.position = spawnPos;
    add(block);
    activeBlocks.add(block);
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
      
      // Calculate screen center above the board for visual pop-up
      final Vector2 textPos = Vector2(gameWidth / 2, gameHeight / 2 - 50);

      if (points == 110) {
        FlameAudio.play('great.mp3');
        add(FeedbackTextEffect(
          text: 'GREAT!',
          textColor: const Color(0xFFFFEB3B), // Yellow like "COLOR" on home page
          position: textPos,
        ));
      } else if (points >= 260) {
        FlameAudio.play('excellent.mp3');
        add(FeedbackTextEffect(
          text: 'EXCELLENT!!',
          textColor: const Color(0xFFFF5722), // Orange/Red like "BLOCK" on home page
          position: textPos,
        ));
      }
    } catch (e) {
      print('Error playing clear sound sequence: $e');
    }
  }

  void reset() {
    score = 0;
    scoreText.text = '0';
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
