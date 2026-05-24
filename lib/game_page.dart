import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
