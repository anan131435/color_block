import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/color_block_game.dart';

class GamePage extends StatefulWidget {
  final bool isJourneyMode;
  const GamePage({super.key, this.isJourneyMode = false});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late ColorBlockGame _game;

  @override
  void initState() {
    super.initState();
    _game = ColorBlockGame(isJourneyMode: widget.isJourneyMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<ColorBlockGame>(
        game: _game,
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
                        if (context.mounted &&
                            game.overlays.isActive('GameOver')) {
                          game.overlays.remove('GameOver');
                          game.reset();
                        }
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
