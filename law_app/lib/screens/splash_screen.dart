import 'package:flutter/material.dart';
import 'package:law_app/screens/main_screen.dart';
import 'package:law_app/screens/login_screen.dart';
import 'package:law_app/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particleController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _logoScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _textFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _logoController.forward();
    _particleController.repeat();

    // Check authentication after animation
    Future.delayed(const Duration(seconds: 3), () {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    bool isLoggedIn = await AuthService().isLoggedIn();
    
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF1A1D3A),
              Color(0xFF0A0E27),
            ],
          ),
        ),
        child: Stack(
          children: [
            ...List.generate(
              20,
              (index) => AnimatedParticle(
                controller: _particleController,
                delay: index * 0.05,
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.rotate(
                          angle: _logoRotation.value * 0.1,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D4FF), Color(0xFF5B73FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D4FF).withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.balance,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF00D4FF), Color(0xFF5B73FF)],
                          ).createShader(bounds),
                          child: const Text(
                            'LexAid',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your Legal Rights, Our Priority',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white60,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF00D4FF)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedParticle extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const AnimatedParticle({
    super.key,
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final clampedDelay = delay.clamp(0.0, 1.0);
    final animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(clampedDelay, 1.0, curve: Curves.easeInOut),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * (0.1 + clampedDelay * 0.8),
          top: MediaQuery.of(context).size.height * (0.1 + (animation.value * 0.8)),
          child: Opacity(
            opacity: (1 - animation.value) * 0.7,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

