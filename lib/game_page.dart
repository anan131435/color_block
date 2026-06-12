import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'game/color_block_game.dart';

class GamePage extends StatefulWidget {
  final bool isJourneyMode;
  const GamePage({super.key, this.isJourneyMode = false});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late ColorBlockGame _game;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _game = ColorBlockGame(isJourneyMode: widget.isJourneyMode);
    _loadBannerAd();
  }

  void _loadBannerAd() {
    final bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    if (!isAndroid && !isIOS) return;

    final String adUnitId = isIOS
        ? 'ca-app-pub-8407541271065760/2682676683'
        : 'ca-app-pub-3940256099942544/6300978111';

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GameWidget<ColorBlockGame>(
                game: _game,
                overlayBuilderMap: {
                  'GameOver': (BuildContext context, ColorBlockGame game) {
                    return GameOverOverlay(game: game);
                  },
                  'NewRecord': (BuildContext context, ColorBlockGame game) {
                    return NewRecordOverlay(game: game);
                  },
                },
              ),
            ),
            if (_isAdLoaded && _bannerAd != null)
              Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                color: Colors.black,
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }
}

class NewRecordOverlay extends StatelessWidget {
  final ColorBlockGame game;
  const NewRecordOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final int score = game.score;
    // Calculate IQ
    final int iq = 80 + (sqrt(score) * 0.45).floor();
    
    // Calculate beat percentage
    double beatPercentage;
    if (score < 100) {
      beatPercentage = (score / 100) * 10;
    } else if (score < 500) {
      beatPercentage = 10 + ((score - 100) / 400) * 30;
    } else if (score < 1500) {
      beatPercentage = 40 + ((score - 500) / 1000) * 35;
    } else if (score < 5000) {
      beatPercentage = 75 + ((score - 1500) / 3500) * 20;
    } else {
      beatPercentage = 95 + min(4.9, (score - 5000) / 10000);
    }

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.55),
      body: Stack(
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: min(MediaQuery.of(context).size.width * 0.85, 360),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2B32B2),
                      Color(0xFF1488CC),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFFFD54F).withOpacity(0.8),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFEB3B).withOpacity(0.3),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                    const BoxShadow(
                      color: Colors.black54,
                      blurRadius: 15,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // New Record 3D text header
                    Stack(
                      children: [
                        Text(
                          '新纪录!',
                          style: GoogleFonts.fredoka(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 6
                              ..color = const Color(0xFFE65100),
                          ),
                        ),
                        Text(
                          '新纪录!',
                          style: GoogleFonts.fredoka(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFEE58),
                            shadows: const [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Crown Icon inside glowing badge
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD54F),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD54F).withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFFFD54F),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Score Display and IQ Badge Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$score',
                          style: GoogleFonts.fredoka(
                            color: const Color(0xFFFFFDE7),
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            shadows: const [
                              Shadow(
                                offset: Offset(2, 3),
                                blurRadius: 6,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        // IQ badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.psychology_rounded,
                                color: Color(0xFFFF8A80),
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'IQ: $iq',
                                style: GoogleFonts.fredoka(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // You beat X% of players banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF8BC34A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.thumb_up_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '你打败了 ${beatPercentage.toStringAsFixed(1)}% 的玩家!',
                              style: GoogleFonts.fredoka(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Buttons Row
                    Row(
                      children: [
                        // Home Button
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              height: 55,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C6BC0),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF3F51B5),
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.home_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Play / Restart Button
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTap: () {
                              game.reset();
                            },
                            child: Container(
                              height: 55,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8BC34A),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF689F38),
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.replay_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '再来一次',
                                    style: GoogleFonts.fredoka(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  final ColorBlockGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final int score = game.score;
    final int highScore = game.highScore;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.55),
      body: Stack(
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: min(MediaQuery.of(context).size.width * 0.85, 360),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3E517A),
                      Color(0xFF2E3B5E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 15,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // GameOver Title Text
                    Stack(
                      children: [
                        Text(
                          '游戏结束',
                          style: GoogleFonts.fredoka(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 6
                              ..color = const Color(0xFF1A237E),
                          ),
                        ),
                        Text(
                          '游戏结束',
                          style: GoogleFonts.fredoka(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Trophy Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFFFD54F),
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Current Score
                    Text(
                      '当前得分',
                      style: GoogleFonts.fredoka(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$score',
                      style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(
                            offset: Offset(1, 2),
                            blurRadius: 4,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Best Score / High Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFFFB300),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '历史最高: $highScore',
                            style: GoogleFonts.fredoka(
                              color: const Color(0xFFFFD54F),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Buttons Row
                    Row(
                      children: [
                        // Home Button
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              height: 55,
                              decoration: BoxDecoration(
                                color: const Color(0xFF78909C),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF546E7A),
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.home_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Play / Restart Button
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTap: () {
                              game.reset();
                            },
                            child: Container(
                              height: 55,
                              decoration: BoxDecoration(
                                color: const Color(0xFF29B6F6),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF0288D1),
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.replay_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '重新开始',
                                    style: GoogleFonts.fredoka(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
