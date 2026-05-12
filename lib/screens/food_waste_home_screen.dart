import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ IMPORT YOUR NEW DRAWER
import '../widgets/food_waste_drawer.dart';

class FoodWasteHomeScreen extends StatefulWidget {
  const FoodWasteHomeScreen({super.key});

  @override
  _FoodWasteHomeScreenState createState() => _FoodWasteHomeScreenState();
}

class _FoodWasteHomeScreenState extends State<FoodWasteHomeScreen> {
  bool _isLoggedIn = false;
  String _quoteText = "";
  int _quoteIndex = 0;

  final List<String> _quotes = [
    "Share surplus food, nourish your community.",
    "Turn potential waste into immediate relief.",
    "Connecting abundance with necessity.",
    "Every meal saved is a step toward zero-waste.",
    "Your leftovers could be someone's lifeline.",
  ];

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _startTypingEffect();
  }

  Future<void> _checkAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _isLoggedIn = prefs.getString('token') != null);
  }

  void _startTypingEffect() async {
    while (mounted) {
      String fullQuote = _quotes[_quoteIndex];

      for (int i = 0; i <= fullQuote.length; i++) {
        if (!mounted) return;
        setState(() => _quoteText = fullQuote.substring(0, i));
        await Future.delayed(const Duration(milliseconds: 80));
      }

      await Future.delayed(const Duration(seconds: 2));

      for (int i = fullQuote.length; i >= 0; i--) {
        if (!mounted) return;
        setState(() => _quoteText = fullQuote.substring(0, i));
        await Future.delayed(const Duration(milliseconds: 40));
      }

      _quoteIndex = (_quoteIndex + 1) % _quotes.length;
    }
  }

  void _navigate(String path) {
    if (_isLoggedIn) {
      Navigator.pushNamed(context, path);
    } else {
      Navigator.pushNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[50],
      appBar: AppBar(
        title: const Text(
          "Food Rescue",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),

      // ✅ ADD THE DRAWER HERE
      drawer: const FoodWasteDrawer(),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.amber[800],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.restaurant, color: Colors.white, size: 60),
                  const SizedBox(height: 10),
                  const Text(
                    "Community Rescue Network",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    "Food Waste Rescue",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$_quoteText|",
                      style: const TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildActionCard(
                    title: "Donate Surplus Food",
                    desc:
                        "Share extra, high-quality unconsumed food from your home or events. Notify local NGOs instantly.",
                    icon: Icons.volunteer_activism,
                    color: Colors.green[700]!,
                    onTap: () => _navigate('/food-waste/donate'),
                  ),
                  const SizedBox(height: 16),
                  _buildActionCard(
                    title: "NGO / Community Shelter",
                    desc:
                        "Find and claim available food donations posted nearby in real-time. Coordinate pickups directly.",
                    icon: Icons.business,
                    color: Colors.blue[700]!,
                    onTap: () => _navigate('/food-waste/require'),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[200]!, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.eco, color: Colors.green[700], size: 30),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "100% Zero-Waste Cycle",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Any unclaimed food is responsibly redirected to local composting facilities or animal feed networks.",
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                desc,
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Get Started",
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
