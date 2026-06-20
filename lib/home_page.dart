import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'game_page.dart';
import 'storage/prefs_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _checkPrivacyPolicy();
  }

  Future<void> _loadStats() async {
    final score = await PrefsManager.getHighScore();
    if (mounted) {
      setState(() {
        _highScore = score;
      });
    }
  }

  Future<void> _checkPrivacyPolicy() async {
    final accepted = await PrefsManager.isPrivacyAccepted();
    if (!accepted && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPrivacyDialog();
      });
    }
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // Main Container
                Container(
                  width: min(MediaQuery.of(context).size.width * 0.85, 340),
                  margin: const EdgeInsets.only(top: 45),
                  padding: const EdgeInsets.only(
                    top: 55,
                    bottom: 24,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4561DC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF6F89FC),
                      width: 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Welcome to Color Block!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Please read and accept our",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          children: [
                            // TextSpan(
                            //   text: "Terms of Use",
                            //   style: const TextStyle(
                            //     color: Color(0xFF00E5FF),
                            //     decoration: TextDecoration.underline,
                            //   ),
                            //   recognizer: TapGestureRecognizer()
                            //     ..onTap = () {
                            //       _launchPrivacyUrl();
                            //     },
                            // ),
                            // const TextSpan(text: " and "),
                            TextSpan(
                              text: "Privacy Policy",
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _launchPrivacyUrl();
                                },
                            ),
                            const TextSpan(text: "."),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () async {
                          await PrefsManager.acceptPrivacy();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF388E3C),
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "Accept",
                              style: GoogleFonts.fredoka(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Emoji Icon
                Positioned(
                  top: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const PixelKissEmoji(pixelSize: 6.0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchPrivacyUrl() async {
    final Uri url = Uri.parse(
      'https://midnight-cosmonaut-0c4.notion.site/Privacy-Policy-for-Color-Block-36acd5edb337800f9358d8e9461aff3f?pvs=74',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching privacy url: $e");
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
              // Color(0xFF6431AD), // Deep purple/violet
              // Color(0xFF5530A4), // Very deep violet
              Color(0xFF383CC1), // Deep blue/purple
              Color(0xFF4C87F5), // Lighter blue

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
                                settings: const RouteSettings(name: 'GamePage_Puzzle'),
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
                                settings: const RouteSettings(name: 'GamePage_Classic'),
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

class PixelKissEmoji extends StatelessWidget {
  final double pixelSize;
  const PixelKissEmoji({super.key, this.pixelSize = 6.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(20 * pixelSize, 14 * pixelSize),
      painter: _PixelKissEmojiPainter(pixelSize),
    );
  }
}

class _PixelKissEmojiPainter extends CustomPainter {
  final double pixelSize;
  _PixelKissEmojiPainter(this.pixelSize);

  static const List<String> grid = [
    '.....OOOOOO.........',
    '...OOYYYYYYOO.......',
    '..OYYYYYYYYYYO......',
    '.OYYKKYYYYYKKYYO....',
    '.OYKKKKYYYKKKKYYO...',
    'OYYYYYYYYYYYYYYOO...',
    'OYYKKKYYYYYKYKYYO.RR.RR.',
    'OYYYYYYYYYYKYKYYORRRRRRR',
    'OYYYYYYYYYYYKYKYYORWRRRRR',
    'OYYYYYYYKKYYYYYYO.RRRRR.',
    '.OYYYYYKYKYKYYYO...RRR..',
    '.OYYYYYYKKYYYYO.....R...',
    '..OYYYYYYYYYYO......',
    '...OOOOOOOOOO.......',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (int r = 0; r < grid.length; r++) {
      final row = grid[r];
      for (int c = 0; c < row.length; c++) {
        final char = row[c];
        if (char == '.') continue;

        Color color;
        if (char == 'Y') {
          color = const Color(0xFFFFD54F); // Yellow face
        } else if (char == 'O') {
          color = const Color(0xFFF39C12); // Orange outline
        } else if (char == 'K') {
          color = const Color(0xFF1C110C); // Dark detail/black
        } else if (char == 'R') {
          color = const Color(0xFFE74C3C); // Red heart
        } else if (char == 'W') {
          color = const Color(0xFFFFFFFF); // White highlight
        } else {
          continue;
        }

        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(c * pixelSize, r * pixelSize, pixelSize, pixelSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelKissEmojiPainter oldDelegate) {
    return oldDelegate.pixelSize != pixelSize;
  }
}
