import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kosmik Shooter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // O'yin holati
  bool isGameStarted = false;
  bool isGameOver = false;
  int score = 0;
  int health = 100;
  
  // Kema pozitsiyasi
  double shipX = 0.5;
  double shipY = 0.8;
  
  // O'qlar va dushmanlar
  List<Bullet> bullets = [];
  List<Enemy> enemies = [];
  
  Timer? gameTimer;
  Timer? enemySpawner;
  Random random = Random();
  
  // Animatsiya controllerlari
  late AnimationController explosionController;
  List<Explosion> explosions = [];

  @override
  void initState() {
    super.initState();
    explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  void startGame() {
    setState(() {
      isGameStarted = true;
      isGameOver = false;
      score = 0;
      health = 100;
      bullets.clear();
      enemies.clear();
      explosions.clear();
    });
    
    // O'yin loopi
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });
    
    // Dushmanlarni yaratish
    enemySpawner = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      spawnEnemy();
    });
  }

  void spawnEnemy() {
    if (!isGameOver) {
      setState(() {
        enemies.add(Enemy(
          x: random.nextDouble() * 0.8 + 0.1,
          y: -0.1,
          speed: random.nextDouble() * 0.003 + 0.002,
        ));
      });
    }
  }

  void shoot() {
    if (!isGameOver && isGameStarted) {
      setState(() {
        bullets.add(Bullet(x: shipX, y: shipY - 0.05));
      });
    }
  }

  void updateGame() {
    if (isGameOver) return;
    
    setState(() {
      // O'qlarni harakatlantirish
      for (var bullet in bullets) {
        bullet.y -= 0.01;
      }
      bullets.removeWhere((bullet) => bullet.y < -0.1);
      
      // Dushmanlarni harakatlantirish
      for (var enemy in enemies) {
        enemy.y += enemy.speed;
      }
      
      // Ekrandan chiqib ketgan dushmanlarni o'chirish
      enemies.removeWhere((enemy) {
        if (enemy.y > 1.0) {
          health -= 10;
          return true;
        }
        return false;
      });
      
      // To'qnashuvlarni tekshirish
      checkCollisions();
      
      // Portlashlarni yangilash
      explosions.removeWhere((explosion) => explosion.lifetime <= 0);
      for (var explosion in explosions) {
        explosion.lifetime--;
      }
      
      // Game Over tekshirish
      if (health <= 0) {
        endGame();
      }
    });
  }

  void checkCollisions() {
    List<Bullet> bulletsToRemove = [];
    List<Enemy> enemiesToRemove = [];
    
    for (var bullet in bullets) {
      for (var enemy in enemies) {
        double distance = sqrt(
          pow(bullet.x - enemy.x, 2) + pow(bullet.y - enemy.y, 2)
        );
        
        if (distance < 0.05) {
          bulletsToRemove.add(bullet);
          enemiesToRemove.add(enemy);
          score += 10;
          
          // Portlash effekti
          explosions.add(Explosion(x: enemy.x, y: enemy.y));
        }
      }
    }
    
    bullets.removeWhere((bullet) => bulletsToRemove.contains(bullet));
    enemies.removeWhere((enemy) => enemiesToRemove.contains(enemy));
  }

  void endGame() {
    isGameOver = true;
    gameTimer?.cancel();
    enemySpawner?.cancel();
  }

  void restartGame() {
    startGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    enemySpawner?.cancel();
    explosionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.blue.shade900,
              Colors.purple.shade900,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Yulduzlar fonida
            ...List.generate(50, (index) {
              return Positioned(
                left: random.nextDouble() * MediaQuery.of(context).size.width,
                top: random.nextDouble() * MediaQuery.of(context).size.height,
                child: Container(
                  width: 2,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
            
            // O'yin maydoni
            if (isGameStarted && !isGameOver)
              GestureDetector(
                onTapDown: (details) {
                  final size = MediaQuery.of(context).size;
                  setState(() {
                    shipX = details.localPosition.dx / size.width;
                  });
                  shoot();
                },
                onPanUpdate: (details) {
                  final size = MediaQuery.of(context).size;
                  setState(() {
                    shipX = (details.localPosition.dx / size.width).clamp(0.05, 0.95);
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      // Kema
                      Positioned(
                        left: shipX * MediaQuery.of(context).size.width - 25,
                        top: shipY * MediaQuery.of(context).size.height - 25,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.cyan,
                                Colors.blue.shade700,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.rocket_launch,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      
                      // O'qlar
                      ...bullets.map((bullet) {
                        return Positioned(
                          left: bullet.x * MediaQuery.of(context).size.width - 3,
                          top: bullet.y * MediaQuery.of(context).size.height,
                          child: Container(
                            width: 6,
                            height: 15,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.yellow,
                                  Colors.orange,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      
                      // Dushmanlar
                      ...enemies.map((enemy) {
                        return Positioned(
                          left: enemy.x * MediaQuery.of(context).size.width - 20,
                          top: enemy.y * MediaQuery.of(context).size.height - 20,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Colors.red.shade400,
                                  Colors.purple.shade700,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.bug_report,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        );
                      }).toList(),
                      
                      // Portlashlar
                      ...explosions.map((explosion) {
                        return Positioned(
                          left: explosion.x * MediaQuery.of(context).size.width - 30,
                          top: explosion.y * MediaQuery.of(context).size.height - 30,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.yellow.withOpacity(explosion.lifetime / 10),
                                  Colors.orange.withOpacity(explosion.lifetime / 15),
                                  Colors.red.withOpacity(explosion.lifetime / 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            
            // UI elementlar
            if (isGameStarted && !isGameOver)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Ball
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.cyan, width: 2),
                            ),
                            child: Text(
                              'Ball: $score',
                              style: const TextStyle(
                                color: Colors.cyan,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // Hayot
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: health > 50 ? Colors.green : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: health > 50 ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '$health%',
                                  style: TextStyle(
                                    color: health > 50 ? Colors.green : Colors.red,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
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
            
            // Boshlash ekrani
            if (!isGameStarted)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.rocket_launch,
                      size: 100,
                      color: Colors.cyan,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'KOSMIK SHOOTER',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan,
                        shadows: [
                          Shadow(
                            color: Colors.cyan,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                    ElevatedButton(
                      onPressed: startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'BOSHLASH',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Ekranni bosing - harakat va o\'q otish',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Game Over ekrani
            if (isGameOver)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'GAME OVER',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          shadows: [
                            Shadow(
                              color: Colors.red,
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Sizning ballingiz: $score',
                        style: const TextStyle(
                          fontSize: 30,
                          color: Colors.cyan,
                        ),
                      ),
                      const SizedBox(height: 50),
                      ElevatedButton(
                        onPressed: restartGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'QAYTA BOSHLASH',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// O'q klassi
class Bullet {
  double x;
  double y;
  
  Bullet({required this.x, required this.y});
}

// Dushman klassi
class Enemy {
  double x;
  double y;
  double speed;
  
  Enemy({required this.x, required this.y, required this.speed});
}

// Portlash klassi
class Explosion {
  double x;
  double y;
  int lifetime;
  
  Explosion({required this.x, required this.y, this.lifetime = 10});
}