import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_page.dart';
import 'storage/prefs_manager.dart';

class HomeSecondPage extends StatefulWidget {
  const HomeSecondPage({super.key});

  @override
  State<HomeSecondPage> createState() => _HomeSecondPageState();
}

class _HomeSecondPageState extends State<HomeSecondPage> {
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final score = await PrefsManager.getHighScore();
    if (mounted) {
      setState(() {
        _highScore = score;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6431AD), // Deep teal/blue
              Color(0xFF5530A4), // Very deep blue
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background Stars/Snowflakes
            ...List.generate(40, (index) {
              final random = Random(index);
              return Positioned(
                left: random.nextDouble() * MediaQuery.of(context).size.width,
                top: random.nextDouble() * MediaQuery.of(context).size.height,
                child: Opacity(
                  opacity: random.nextDouble() * 0.4 + 0.1,
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white24,
                    size: 8,
                  ),
                ),
              );
            }),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  // Logo / Title
                  const BlockBlasterTitle(),
                  const SizedBox(height: 30),
                  // Middle Block Cluster
                  const MiddleBlockCluster(),
                  const Spacer(),
                  // Game Modes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        GameModeCard(
                          title: "Puzzle",
                          subtitle: "LEVEL 1",
                          color: const Color(0xFFFFA726),
                          titleOutlineColor: Colors.redAccent,
                          previewColor: const Color(0xFF0D2535),
                          onPlay: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GamePage(isJourneyMode: true),
                              ),
                            ).then((_) => _loadStats());
                          },
                        ),
                        const SizedBox(height: 40),
                        GameModeCard(
                          title: "Classic",
                          subtitle: _highScore.toString(),
                          isScore: true,
                          color: const Color(0xFF29B6F6),
                          titleOutlineColor: const Color(0xFF0277BD),
                          previewColor: const Color(0xFF0D2535),
                          onPlay: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GamePage(),
                              ),
                            ).then((_) => _loadStats());
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlockBlasterTitle extends StatelessWidget {
  const BlockBlasterTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _build3DText("COLOR", const Color(0xFFFFEB3B), 70),
        const SizedBox(height: 2),
        _build3DText("BLOCK", const Color(0xFFFF5722), 52),
      ],
    );
  }

  Widget _build3DText(String text, Color color, double fontSize) {
    return Stack(
      children: [
        // 3D Shadow Layers
        for (double i = 5; i > 0; i--)
          Transform.translate(
            offset: Offset(i, i),
            child: Text(
              text,
              style: GoogleFonts.fredoka(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: Color.lerp(color, Colors.black, 0.4),
              ),
            ),
          ),
        // Main Text
        Text(
          text,
          style: GoogleFonts.fredoka(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color,
            shadows: [
              const Shadow(
                blurRadius: 10,
                color: Colors.black45,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

extension WidgetOffset on Widget {
  Widget withOffset(double dx, double dy) {
    return Transform.translate(offset: Offset(dx, dy), child: this);
  }
}

class MiddleBlockCluster extends StatelessWidget {
  const MiddleBlockCluster({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBlock(const Color(0xFFFFEB3B)),
              _buildBlock(const Color(0xFFFFEB3B)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 26),
              _buildBlock(const Color(0xFFFFEB3B)),
              const SizedBox(width: 26),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlock(Color color) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }
}

class GameModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isScore;
  final Color color;
  final Color titleOutlineColor;
  final Color previewColor;
  final VoidCallback onPlay;

  const GameModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.isScore = false,
    required this.color,
    required this.titleOutlineColor,
    required this.previewColor,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Card
        Container(
          height: 135,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 8),
                blurRadius: 6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Shine Reflection
                Positioned(
                  top: -50,
                  left: -50,
                  child: Transform.rotate(
                    angle: 0.5,
                    child: Container(
                      width: 100,
                      height: 250,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    // Preview Box
                    Container(
                      width: 95,
                      height: 95,
                      decoration: BoxDecoration(
                        color: previewColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Center(child: GridPreview(isPuzzle: !isScore)),
                    ),
                    const SizedBox(width: 20),
                    // Level/Score Info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isScore)
                                const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.orange,
                                  size: 26,
                                ),
                              if (isScore) const SizedBox(width: 10),
                              Text(
                                isScore ? "" : "LEVEL",
                                style: GoogleFonts.fredoka(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  shadows: const [
                                    Shadow(offset: Offset(1, 1), blurRadius: 2),
                                  ],
                                ),
                              ),
                              if (!isScore) const SizedBox(width: 10),
                              Text(
                                subtitle,
                                style: GoogleFonts.fredoka(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  shadows: const [
                                    Shadow(offset: Offset(1, 1), blurRadius: 2),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Play Button
                          GestureDetector(
                            onTap: onPlay,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8BC34A),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF689F38),
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Text(
                                "PLAY",
                                style: GoogleFonts.fredoka(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Overlapping Title Tag
        Positioned(
          top: -24,
          right: 12,
          child: Stack(
            children: [
              // Thick Outline
              Text(
                title,
                style: GoogleFonts.fredoka(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 8
                    ..color = titleOutlineColor,
                ),
              ),
              // Shadow for outline
              Transform.translate(
                offset: const Offset(2, 2),
                child: Text(
                  title,
                  style: GoogleFonts.fredoka(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 8
                      ..color = Colors.black26,
                  ),
                ),
              ),
              // Main White Text
              Text(
                title,
                style: GoogleFonts.fredoka(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GridPreview extends StatelessWidget {
  final bool isPuzzle;

  const GridPreview({super.key, required this.isPuzzle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (r) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (c) {
            bool hasBlock = false;
            Color blockColor = Colors.transparent;
            Widget? icon;

            if (isPuzzle) {
              if ((r == 1 && c == 0) || (r == 2 && (c == 0 || c == 1))) {
                hasBlock = true;
                blockColor = const Color(0xFFEF6C00);
              } else if (r == 1 && c == 1) {
                icon = const Icon(Icons.favorite, color: Colors.pink, size: 12);
              } else if (r == 1 && c == 2) {
                icon = const Icon(Icons.star, color: Colors.yellow, size: 12);
              } else if (r == 1 && c == 3) {
                icon = const Icon(
                  Icons.water_drop,
                  color: Colors.blue,
                  size: 12,
                );
              }
            } else {
              if (r >= 1 &&
                  (c == 0 || (r == 2 && c == 1) || (r == 3 && c == 2))) {
                hasBlock = true;
                blockColor = const Color(0xFF009688);
              }
            }

            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: hasBlock ? blockColor : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(2),
              ),
              child: icon,
            );
          }),
        );
      }),
    );
  }
}
