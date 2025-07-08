import 'package:flutter/material.dart';

class ModernActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const ModernActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  _ModernActionCardState createState() => _ModernActionCardState();
}

class _ModernActionCardState extends State<ModernActionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) => _controller.reverse().then((_) => widget.onTap()),
            onTapCancel: () => _controller.reverse(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16), // Reduced from 20 to 16
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Added to prevent overflow
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12), // Reduced from 16 to 12
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: widget.gradient),
                        borderRadius: BorderRadius.circular(12), // Reduced from 16 to 12
                        boxShadow: [
                          BoxShadow(
                            color: widget.gradient.first.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        size: 28, // Reduced from 32 to 28
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12), // Reduced from 16 to 12
                    Flexible( // Wrapped with Flexible to prevent overflow
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15, // Reduced from 16 to 15
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                          height: 1.2, // Added line height for better control
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2, // Added max lines
                        overflow: TextOverflow.ellipsis, // Added overflow handling
                      ),
                    ),
                    const SizedBox(height: 2), // Reduced from 4 to 2
                    Flexible( // Wrapped with Flexible to prevent overflow
                      child: Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 11, // Reduced from 12 to 11
                          color: Colors.white60,
                          letterSpacing: 0.3,
                          height: 1.2, // Added line height for better control
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2, // Added max lines
                        overflow: TextOverflow.ellipsis, // Added overflow handling
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}