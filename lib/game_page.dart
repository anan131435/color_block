import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/color_block_game.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<ColorBlockGame>(
        game: ColorBlockGame(),
        overlayBuilderMap: {
          'GameOver': (BuildContext context, ColorBlockGame game) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                color: const Color(0xCC000000),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Game Over!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Score: ${game.score}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        game.overlays.remove('GameOver');
                        // Reset game logic
                        // Easiest is to replace the game instance or call reset
                        // Since we are inside GameWidget, we can call a method on game
                        game.reset();
                      },
                      child: const Text('Restart'),
                    ),
                  ],
                ),
              ),
            );
          },
        },
      ),
    );
  }
}
