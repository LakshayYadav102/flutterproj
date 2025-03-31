import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
        image: DecorationImage(
                image: AssetImage('assets/images/home.jpg'), // Add your image
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.2),
                  BlendMode.darken,
                ),
              ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE1F5FE),
              Color(0xFFB3E5FC),
              Color(0xFF81D4FA),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated Background Elements
            Positioned(
              top: screenHeight * 0.15,
              left: -screenWidth * 0.2,
              child: _AnimatedLeaf(size: screenWidth * 0.5),
            ),
            Positioned(
              bottom: screenHeight * 0.1,
              right: -screenWidth * 0.15,
              child: _AnimatedLeaf(size: screenWidth * 0.4, reverse: true),
            ),

            // Main Content
            Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  _LogoAnimation(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AspectRatio(
                        aspectRatio: 1,
                        child: Padding(
                          padding: EdgeInsets.all(25.0),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.eco_rounded),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),

                  SizedBox(height: 40),

                  // Title
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                    ).createShader(bounds),
                    child: Text(
                      "Welcome to GreenTrail",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Subtitle
                  Text(
                    "Your journey towards a sustainable future begins here. "
                    "Track, reduce, and offset your carbon footprint with ease.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 40),

                  // Buttons
                  _AnimatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    text: "Continue Your Journey",
                    icon: Icons.login_rounded,
                  ),
                  SizedBox(height: 20),
                  _AnimatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    text: "Start New Adventure",
                    icon: Icons.app_registration_rounded,
                    isSecondary: true,
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

class _AnimatedLeaf extends StatefulWidget {
  final double size;
  final bool reverse;

  _AnimatedLeaf({required this.size, this.reverse = false});

  @override
  __AnimatedLeafState createState() => __AnimatedLeafState();
}

class __AnimatedLeafState extends State<_AnimatedLeaf>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.reverse ? 8 : 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 0.25).animate(_controller),
      child: Opacity(
        opacity: 0.15,
        child: Icon(
          Icons.spa_rounded,
          size: widget.size,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LogoAnimation extends StatefulWidget {
  final Widget child;

  _LogoAnimation({required this.child});

  @override
  __LogoAnimationState createState() => __LogoAnimationState();
}

class __LogoAnimationState extends State<_LogoAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -0.02, end: 0.02).animate(
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
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value * 20),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData icon;
  final bool isSecondary;

  _AnimatedButton({
    required this.onPressed,
    required this.text,
    required this.icon,
    this.isSecondary = false,
  });

  @override
  __AnimatedButtonState createState() => __AnimatedButtonState();
}

class __AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
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
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: widget.isSecondary
                ? LinearGradient(
                    colors: [Colors.white, Colors.grey[100]!],
                  )
                : LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
             backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon,
                    color: widget.isSecondary ? Colors.green[800] : Colors.white),
                SizedBox(width: 12),
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isSecondary ? Colors.green[800] : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}