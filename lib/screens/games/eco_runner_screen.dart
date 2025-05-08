import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';

class GameItem {
  final int id;
  double left;
  double top;
  final String type;
  final String icon;
  final int score;

  GameItem({
    required this.id,
    required this.left,
    required this.top,
    required this.type,
    required this.icon,
    required this.score,
  });
}

class Particle {
  final int id;
  double x;
  double y;
  final Color color;
  final DateTime createdAt;
  final double tx;
  final double ty;

  Particle({
    required this.id,
    required this.x,
    required this.y,
    required this.color,
    required this.createdAt,
    required this.tx,
    required this.ty,
  });
}

class EcoRunnerScreen extends StatefulWidget {
  const EcoRunnerScreen({Key? key}) : super(key: key);

  @override
  _EcoRunnerScreenState createState() => _EcoRunnerScreenState();
}

class _EcoRunnerScreenState extends State<EcoRunnerScreen> {
  double playerPos = 0;
  List<GameItem> items = [];
  List<Particle> particles = [];
  int score = 100;
  bool gameOver = false;
  final AudioPlayer audioPlayer = AudioPlayer();
  Timer? itemSpawnTimer;
  Timer? gameLoopTimer;
  Timer? particleTimer;
  double gameAreaWidth = 0;
  double gameAreaHeight = 0;
  bool gameInitialized = false;

  static const double playerWidth = 40;
  static const double playerHeight = 60;
  static const double itemSize = 30;
  double itemSpeed = 2.0;
  double playerSpeed = 8.0;

  @override
  void initState() {
    super.initState();
    _playBackgroundMusic();
  }

  Future<void> _playBackgroundMusic() async {
    try {
      await audioPlayer.play(AssetSource('sounds/background.mp3'), volume: 0.3);
    } catch (e) {
      print("Error playing background music: $e");
    }
  }

  @override
  void dispose() {
    itemSpawnTimer?.cancel();
    gameLoopTimer?.cancel();
    particleTimer?.cancel();
    audioPlayer.stop();
    audioPlayer.dispose();
    super.dispose();
  }

  void startGame() {
    gameInitialized = true;
    itemSpawnTimer = Timer.periodic(const Duration(milliseconds: 1500), (
      timer,
    ) {
      if (!gameOver && gameAreaWidth > 0) {
        setState(() {
          items.add(
            GameItem(
              id: DateTime.now().millisecondsSinceEpoch,
              left: Random().nextDouble() * (gameAreaWidth - itemSize),
              top: -itemSize,
              type: ["good", "good", "bad", "bad"][Random().nextInt(4)],
              icon: ["🚲", "🌳", "🚗", "🏭"][Random().nextInt(4)],
              score: [20, 15, -30, -50][Random().nextInt(4)],
            ),
          );
        });
      }
    });

    gameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!gameOver) {
        setState(() {
          items = items.map((item) => item..top += itemSpeed).toList();
          items.removeWhere((item) => item.top > gameAreaHeight);

          final playerLeft = playerPos;
          final playerRight = playerLeft + playerWidth;
          final playerTop = gameAreaHeight - 100 - playerHeight;
          final playerBottom = gameAreaHeight - 100;

          items.removeWhere((item) {
            final collide =
                playerLeft < item.left + itemSize &&
                playerRight > item.left &&
                playerTop < item.top + itemSize &&
                playerBottom > item.top;

            if (collide) {
              _handleCollision(item);
              return true;
            }
            return false;
          });
        });
      }
    });
    startParticleCleanup();
  }

  void _handleCollision(GameItem item) {
    score += item.score;
    if (score <= 0) {
      score = 0;
      gameOver = true;
    }
    try {
      audioPlayer.play(
        AssetSource(item.score > 0 ? 'sounds/collect.mp3' : 'sounds/hit.mp3'),
      );
    } catch (e) {
      print("Error playing sound: $e");
    }
    createParticles(
      item.left,
      item.top,
      item.score > 0 ? Colors.green : Colors.red,
    );
  }

  void createParticles(double x, double y, Color color) {
    final now = DateTime.now();
    setState(() {
      particles.addAll(
        List.generate(
          15,
          (i) => Particle(
            id: now.millisecondsSinceEpoch + i,
            x: x,
            y: y,
            color: color,
            createdAt: now,
            tx: (Random().nextDouble() - 0.5) * 50,
            ty: (Random().nextDouble() - 0.5) * 50,
          ),
        ),
      );
    });
  }

  void startParticleCleanup() {
    particleTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        particles.removeWhere(
          (p) => DateTime.now().difference(p.createdAt).inMilliseconds > 1000,
        );
      });
    });
  }

  void moveLeft() {
    if (!gameOver) {
      setState(() {
        playerPos = (playerPos - playerSpeed).clamp(
          0,
          gameAreaWidth - playerWidth,
        );
      });
    }
  }

  void moveRight() {
    if (!gameOver) {
      setState(() {
        playerPos = (playerPos + playerSpeed).clamp(
          0,
          gameAreaWidth - playerWidth,
        );
      });
    }
  }

  void restartGame() {
    setState(() {
      items.clear();
      particles.clear();
      playerPos = gameAreaWidth / 2 - playerWidth / 2;
      score = 100;
      gameOver = false;
    });
    itemSpawnTimer?.cancel();
    gameLoopTimer?.cancel();
    startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eco Runner"),
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.blue[800]
                : Colors.blue,
      ),
      body: Container(
        color: const Color(0xFF1A2F38),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (gameAreaWidth != constraints.maxWidth - 40 ||
                gameAreaHeight != constraints.maxHeight) {
              gameAreaWidth = constraints.maxWidth - 40;
              gameAreaHeight = constraints.maxHeight;
              playerPos = gameAreaWidth / 2 - playerWidth / 2;
              if (!gameInitialized) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => startGame(),
                );
              }
            }

            return Column(
              children: [
                _buildScorePanel(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.lightBlue, Color(0xFFE0F6FF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A9375),
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        ..._buildGameElements(),
                        if (gameOver) _buildGameOverOverlay(),
                      ],
                    ),
                  ),
                ),
                _buildControlButtons(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScorePanel() {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        children: [
          Text(
            "🌍 Carbon Score: ${score}kg",
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF2C3E50),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              widthFactor: score.clamp(0, 100) / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.greenAccent],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            score >= 100 ? "🌱 Sustainable!" : "⚠️ Keep Going!",
            style: const TextStyle(fontSize: 14, color: Colors.green),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGameElements() {
    return [
      Positioned(
        bottom: 100,
        left: playerPos,
        child: const SizedBox(
          width: playerWidth,
          height: playerHeight,
          child: Text("🚶‍♂️", style: TextStyle(fontSize: 40)),
        ),
      ),
      ...items.map(
        (item) => Positioned(
          left: item.left,
          top: item.top,
          child: SizedBox(
            width: itemSize,
            height: itemSize,
            child: Text(
              item.icon,
              style: TextStyle(
                fontSize: 30,
                color: item.type == "good" ? Colors.green : Colors.red,
              ),
            ),
          ),
        ),
      ),
      ...particles.map((p) {
        final age =
            DateTime.now().difference(p.createdAt).inMilliseconds / 1000;
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 1000),
          left: p.x + p.tx * age,
          top: p.y + p.ty * age,
          child: Opacity(
            opacity: (1 - age).clamp(0, 1),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
            ),
          ),
        );
      }),
    ];
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton("◀️ Left", moveLeft),
          const SizedBox(width: 20),
          _buildControlButton("Right ▶️", moveRight),
        ],
      ),
    );
  }

  Widget _buildControlButton(String label, VoidCallback action) {
    return GestureDetector(
      onTapDown: (_) => action(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Carbon Footprint Alert! ⚠️",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: restartGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Try Again"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
