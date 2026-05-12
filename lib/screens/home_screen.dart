import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/greenverse_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = "Eco Warrior";
  String? _userId;

  // --- NEW: Animated Quotes Logic ---
  final List<String> _ecoQuotes = [
    "\"The Earth is what we all have in common.\"",
    "\"There is no planet B.\"",
    "\"Small acts, when multiplied by millions, transform the world.\"",
    "\"Be the change you wish to see in the world.\"",
    "\"Green is the new black.\"",
  ];
  int _currentQuoteIndex = 0;
  Timer? _quoteTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Rotate quotes every 4 seconds
    _quoteTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      setState(() {
        _currentQuoteIndex = (_currentQuoteIndex + 1) % _ecoQuotes.length;
      });
    });
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('username') ?? "Eco Warrior";
      _userId = prefs.getString('userId');
    });
  }

  Future<void> _launchARVR() async {
    final Uri url = Uri.parse('https://greenversear.netlify.app/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch AR/VR module')),
      );
    }
  }

  void _navigateToModule(String routeName) {
    if (routeName == '/dashboard') {
      Navigator.pushNamed(context, routeName, arguments: {'userId': _userId});
    } else {
      Navigator.pushNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Premium off-white
      appBar: AppBar(
        title: const Text(
          "GreenVerse",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () => Navigator.pushNamed(context, '/wallet'),
          ),
        ],
      ),
      drawer: const GreenverseDrawer(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green[800]!, Colors.green[600]!],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back,",
                    style: TextStyle(
                      color: Colors.green[100],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ✅ NEW: Beautiful Animated Quote Switcher
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.format_quote,
                          color: Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 800),
                            transitionBuilder: (
                              Widget child,
                              Animation<double> animation,
                            ) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: Text(
                              _ecoQuotes[_currentQuoteIndex],
                              key: ValueKey<int>(_currentQuoteIndex),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Explore Modules",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Modules Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9, // Slightly taller for breathing room
                children: [
                  _buildModuleCard(
                    title: "GreenTrail",
                    subtitle: "Carbon Tracker",
                    icon: Icons.eco,
                    colors: [Colors.green[400]!, Colors.green[800]!],
                    onTap: () => _navigateToModule('/dashboard'),
                  ),
                  _buildModuleCard(
                    title: "EcoStore",
                    subtitle: "Redeem Coins",
                    icon: Icons.shopping_bag,
                    colors: [Colors.teal[400]!, Colors.teal[800]!],
                    onTap: () => _navigateToModule('/store'),
                  ),
                  _buildModuleCard(
                    title: "Food Rescue",
                    subtitle: "Zero Waste",
                    icon: Icons.restaurant,
                    colors: [Colors.orange[400]!, Colors.deepOrange[800]!],
                    onTap: () => _navigateToModule('/food-waste'),
                  ),
                  _buildModuleCard(
                    title: "Carpooling",
                    subtitle: "Share Rides",
                    icon: Icons.directions_car,
                    colors: [Colors.blue[400]!, Colors.blue[800]!],
                    onTap: () => _navigateToModule('/carpool'),
                  ),
                  _buildModuleCard(
                    title: "GreenStream",
                    subtitle: "Shorts & Ed",
                    icon: Icons.video_library,
                    colors: [Colors.purple[400]!, Colors.deepPurple[800]!],
                    onTap: () => _navigateToModule('/ecolearn/feed'),
                  ),
                  _buildModuleCard(
                    title: "GreenScan",
                    subtitle: "Immersive Tech",
                    icon: Icons.view_in_ar,
                    colors: [Colors.redAccent[400]!, Colors.red[800]!],
                    onTap: _launchARVR,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Premium Module Cards with rich gradients and overflow fixes
  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: colors[1].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 38),
                ),
                const Spacer(),
                // ✅ FIXED OVERFLOW: FittedBox forces text to shrink instead of overflowing
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
