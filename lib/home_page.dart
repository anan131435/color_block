import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_page.dart';
import 'storage/prefs_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _highScore = 0;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final score = await PrefsManager.getHighScore();
    final streak = await PrefsManager.getStreak();
    if (mounted) {
      setState(() {
        _highScore = score;
        _streak = streak;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF383CC1), // Deep blue/purple
              Color(0xFF4C87F5), // Lighter blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo
              const GameLogo(),
              const SizedBox(height: 40),
              // Stats Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: StatsCard(highScore: _highScore, streak: _streak),
              ),
              const Spacer(),
              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    GameButton(
                      text: "Puzzle",
                      icon: Icons.location_on_rounded,
                      color: const Color(0xFFFFB347),
                      shadowColor: const Color(0xFFD8781B),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const GamePage(isJourneyMode: true),
                          ),
                        ).then((_) {
                          _loadStats();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    GameButton(
                      text: "Classic",
                      icon: Icons.grid_view_rounded,
                      color: const Color(0xFF4CAF50),
                      shadowColor: const Color(0xFF2E7D32),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GamePage(),
                          ),
                        ).then((_) {
                          // Refresh stats when returning from game
                          _loadStats();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class GameLogo extends StatelessWidget {
  const GameLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLetter('C', const Color(0xFF00B0FF)),
            _buildLetter('O', const Color(0xFF76FF03)),
            _buildLetter('L', const Color(0xFFFFD600)),
            _buildLetter('O', const Color(0xFFFF9100)),
            _buildLetter('R', const Color(0xFFFF3D00)),
          ],
        ),
        Stack(
          children: [
            Text(
              "BLOCK",
              style: GoogleFonts.fredoka(
                fontSize: 60,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  const BoxShadow(
                    color: Color(0xFF1565C0),
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
            // Decorative squares
            Positioned(
              left: -20,
              top: 10,
              child: _buildDecoSquare(const Color(0xFF76FF03)),
            ),
            Positioned(
              right: -20,
              bottom: 10,
              child: _buildDecoSquare(const Color(0xFFFF3D00)),
            ),
          ],
          clipBehavior: Clip.none,
        ),
      ],
    );
  }

  Widget _buildLetter(String char, Color color) {
    return Text(
      char,
      style: GoogleFonts.fredoka(
        fontSize: 60,
        fontWeight: FontWeight.w900,
        color: color,
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(2, 2),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDecoSquare(Color color) {
    return Transform.rotate(
      angle: -0.2,
      child: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(1, 1),
              blurRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class StatsCard extends StatelessWidget {
  final int highScore;
  final int streak;

  const StatsCard({super.key, required this.highScore, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2855AE).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow(
            Icons.emoji_events_rounded,
            "Score",
            highScore.toString(),
            const Color(0xFFFFD700),
          ),
          const Divider(color: Colors.white10),
          _buildStatRow(
            Icons.calendar_today_rounded,
            "Streak",
            streak.toString(),
            const Color(0xFF4CAF50),
          ),
          const Divider(color: Colors.white10),
          _buildStatRow(
            Icons.map_rounded,
            "Levels",
            "1-3",
            const Color(0xFFFFA000),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF8aaae5),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class GameButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Color shadowColor;
  final Gradient gradient;
  final VoidCallback onPressed;

  const GameButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.shadowColor,
    required this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 6),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 8),
              blurRadius: 6,
            ),
          ],
          gradient: gradient,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
